# Openshift - Monitoring Tomcat Containers with Jolokia
The purpose of this repository is to demonstrate how to monitor Openshift Tomcat Containers using Jolokia. It contains a deployable pre-configured, Jolokia enabled, Tomcat Sever.

## Quick start
The repo provides a script nammed `deploy.sh` to quickly deploy the Jolokia enabled Tomcat Server on your Openshift Server. Start by login to Openshift using `oc login`, then simply create a new project and run it up:
```
oc new-project tomcat-jolokia
./deploy.sh
```

## Monitoring Containers
### Via REST Queries
Jolokia can be queried through the Openshift REST API (http://[master_host]:8443/api). The URL to communicate with the Jolokia port as the following format:

    https://[master_host]:8443/api/v1/namespaces/[namespace]/pods/[protocol]:[pod_name]:[port]/proxy/ jolokia

If you followed this step by step procedure, your URL should something like this:

    https://myhost:8443/api/v1/namespaces/tomcat-jolokia/pods/https:tomcat-jolokia-7cb:8778/proxy/jolokia

Accessing the Openshift REST API requires you to be authentify. You can therefore invoke query URLs using the following command:

    curl -k -H "Authorization: Bearer [api_token]" https://myhost:8443/api/v1/namespaces/tomcat-jolokia/pods/https:tomcat-jolokia-7cb:8778/proxy/jolokia

Where [api_token] is the OAuth token of your Openshift user. Please, checkout Jolokia’s documentation for the full set of requests and responses of the service.

### Via GUI
Jolokia provides a demo app that offers a GUI to monitor an Openshift project. To use it, you’ll first need to make sure CORS restrictions is disable on your Openshift Server (enabled by default). To do that, edit the Openshift master configuration file located at /etc/origin/master-config.yaml. You’ll need to add - .* in a new line under corsAllowedOrigins:

    corsAllowedOrigins:
    - .*
    Other hosts...

You’ll need to reboot the Master Node in order for the modification to be applied. Then simply clone their demo app on your local machine and run the index.html file:

    git clone https://github.com/sabre1041/ose-jolokia-demo

For more info, please refere to the README file of their repository.

## Custom configuration
### Configuration changes over Tomcat

Configuration is located in `conf/server.xml`, `conf/web.xml`, `conf/logging.properties`, all other configuration files, resources and context files are located in `conf`, identical to standalone Tomcat.

### Building
#### Maven Build
If you would like to build the Docker image yourself, you'll first need to build the project through Maven:
```
mvn clean; mvn package
```
Note that you can update the Tomcat version number in the `pom.xml` and customize Tomcat components in the dependencies to keep the ones needed (only the main `tomcat-catalina` is mandatory).

#### Docker Build
To build the Docker image, run the following command:
```
docker build -t [docker_repository]/tomcat-jolokia:1.0 -f ./Dockerfile --build-arg [openshift_namespace] .
```
Where __docker_repository__ is the repository you will push your image to once builded (To run it inside Openshift, your Docker Image has to be hosted on a repository) and __openshift_namspace__ is the name of your Openshift Project.

### Configuring Jolokia
#### jolokia.properties
Jolokia’s configuration is done through a simple key-value property file (*conf/jolokia.properties*). Here’s how it looks:

    host=*
    port=8778
    protocol=https
    authIgnoreCerts=true

Through this file, we’re basically telling Jolokia to run on port 8778 (default port) via the HTTPS protocol on every IP-Address of the host ignoring certificates

#### Dockerfile
In the Dockerfile, we first need to copy the JVM-Agent to the Docker Container. We’ll copy it to /opt/jolokia/jolokia.jar:
ADD jolokia.jar /opt/jolokia/

We then need to expose the port Jolokia will be running on (8778):

    EXPOSE 8778

Finally, we have to make sure we tell Java where is located the Jolokia JAR along with its configuration file. This is done through the JAVA_OPTS variable:

    ENV JAVA_OPTS="-javaagent:/opt/jolokia/jolokia.jar=config=conf/jolokia.properties”

### Deploying Tomcat Server to Openshift
Start by logging in to your Openshift Server using  `oc login` . Then create a new project. We’ll call it tomcat-jolokia:
```
oc new-project tomcat-jolokia
```

You can either build the dockerfile yourself and then push it on a Docker Registry or simply use the docker image I’ve already built:
```
kubectl run $(oc project -q) --image=[docker_registry]/tomcat-jolokia:1.0 --port 8080
```

Now simply expose your deployment to port 80 so we’ll be able to access it from outside the cluster:
```
kubectl expose deployment $(oc project -q) --type=LoadBalancer --port 80 --target-port 8080
```

Finally we have to tell Openshift that Jolokia is running on port 8778. We can do this by editing the yaml for your deployment. Go to the following link and click Action > Edit YAML:

    https://[openshift_server]:8443/console/project/tomcat-jolokia/browse/rs/[pod_name]