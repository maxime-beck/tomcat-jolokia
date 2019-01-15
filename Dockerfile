FROM openjdk:8-jre-alpine
VOLUME /tmp

USER root
RUN mkdir -m 777 -p /deployments

ADD target/tomcat-maven-1.0.jar /deployments/app.jar
ADD conf /deployments/conf
ADD webapps /deployments/webapps

# Copying the Jolokia Jar file
ADD jolokia.jar /opt/jolokia/

WORKDIR /deployments

ARG namespace=myproject
ENV KUBERNETES_NAMESPACE=$namespace
EXPOSE 8080
# Don't forget to expose port 8778 as that is the port used by Jolokia
EXPOSE 8778 

RUN sh -c 'touch app.jar'

# Run Java configuring the path to Jolokia Jar and its configuration
ENV JAVA_OPTS="-javaagent:/opt/jolokia/jolokia.jar=config=conf/jolokia.properties -Dcatalina.base=. -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file=conf/logging.properties -Djava.security.egd=file:/dev/urandom"
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -jar app.jar" ]
