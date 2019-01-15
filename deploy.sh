#/bin/bash!

kubectl run $(oc project -q) --image=maxbeck/tomcat-jolokia --port 8080
kubectl scale deployment $(oc project -q) --replicas=1
kubectl expose deployment $(oc project -q) --type=LoadBalancer --port 80 --target-port 8080