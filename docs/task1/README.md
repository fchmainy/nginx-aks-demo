# Description
In this task, we will learn how to deploy this app. It is straight forward, as all docker images can run either in K8S/k3s/Volterra or any other Kubernetes environment.

# Deploy the WORDS microservices
First of all, deploy the 4 WORD microservices
- locations
- animals
- adjectives
- colors

Please clone this repo:
```
git clone https://github.com/fchmainy/nginx-aks-demo.git
```

## Deploy All Microservices in one
We created a YAML deployment with the 4 microservices (pods + services)

Run this command in your Kubernetes environment

```
kubectl apply -f ./k8s/attributes/all_attributes.yaml
```

This command will deploy 4 PODS and 4 SERVICES in **ClusterIP** mode. All services listen on port 80 and all PODS on port 8080.

# Deploy the Generator
As a reminder, the generator is a python application calling each microservice to get a WORD (randomly). This generator listen on port **8080**, and his service on port **80**.

```
vi k8s/attributes/generator-direct.yaml
```

Modify the YAML deployment with the right NAMESPACE value at the end. This value is the NAMESPACE where the 4 microservices run (deployed in the previous step). The generator needs this information to reach the service in K8S.

Example of call done by the `generator` to get the color word : curl http://colors.api/colors

**api** is the namespace, and **colors** is the k8s service.

Then, run the deployment
```
kubectl apply -f ./k8s/attributes/generator-direct.yaml
```

# Deploy the Frontend application (webapp)
In order to display the final sentence, we can run a `web application` that will call the `generator`.
This web application is not mandatory in case you just want to use this app for an API lab.

Edit the YAML deployment file in order to specify the NAMESPACE of the `generator`. This web application can be deployed in another namespace for instance. But teh web application needs to know where is the generator service.

```
vi .k8s/attributes/frontend-namespace-generator.yaml
```

```
kubectl apply -f ./k8s/attributes/frontend-namespace-generator.yaml
```

## Publish the services
You can publish `frontend` or `generator` services outside your K8S. To do so, change the YAML Service blob from `ClusterIP` to `NodePort`.

One example below to publish the `Frontend` externaly.

```
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: frontend
```

Find the port used by the `NodePort`
```
kubectl get services
```

And connect to your node with this port **http://node_IP:NodePort**


