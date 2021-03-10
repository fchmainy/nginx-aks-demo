# Description
This is a very simple kubernetes demo application intended to show most of the benefits of using F5 Technology for your application delivery and security.
It is composed of multiple technology frameworks.

This app will generate a sentence :)

![alt text](https://raw.githubusercontent.com/MattDierick/api-sentence-demo/main/docs/images/webapp.png)

# Features
- Ingress Canary testing
- Cross-namespace Ingress
- JWT validation
- MS API GW

# Lab Documentation
## Task 1: Deploy the version 1 of the application
Simple application composed of multiple microservices.
  [Task1: Deploy the version 1 of the application](docs/task1/README.md)
  ![alt text](https://github.com/fchmainy/nginx-aks-demo/blob/main/docs/images/task1-topology.jpg?raw=true)

In term of micro-services, this is how there are spread and used by the Webapp frontend

  ![alt text](https://github.com/MattDierick/api-sentence-demo/blob/main/docs/images/webapp-containers.png?raw=true)

**Features:**
- NGINX+ Ingress Service
- Cross-Namespace deployment

## Task 2: API Management
  **Goal:**
    Deploy an API Gw in Kubernetes managed by Nginx Controller. And scale this Gateway in K8S with auto-adoption by the controller.

  **Duration:**

  **Features:**
  - NGINX Controller API Management
  
    ![](https://raw.githubusercontent.com/MattDierick/api-sentence-demo/main/docs/images/topology2.png)


## Task 3: Web Application and API Protection (WAAP)
  **Goal:**
    Protect Inbound application and API traffic from Advanced attacks (OWASP TopN, L7 DDoS, Threat Campaigns...) and microservice to microservice communications.

  **Duration:**: 30 minutes


  **Features:**
  - NGINX App Protect (https://www.nginx.com/products/nginx-app-protect/)

  **Lab Guide:**
  [Task3: WAAP] (https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/task3/README.md)


## Task 4: Service Mesh
**Goal:**
    Securing Microservice to Microservice communication in a hollistic Zero-Trust model while extending the visibility and

**Duration:**


**Features:**


**Lab Guide:**

## Task 5: API Management with API GW as sidecar
  **Goal:**
  We are making our simple application to evolve with a more secure framework and Application Security
  Two different deployment model for our API Gateway in this case:
    - Shared and centralized API Gateway in a dedicated namespace so micro-services can talk one with the others through this API Gateway.
      - scales independantly 

    - API Gateway injected as a sidecar
      - specialized for the associated application sharing the same pod.
      in our scenario, the generator is the central piece of the configuration so we decided to make it have its own APIGW closest to the application.
        - it scales 1:1 along with the application

  ![alt text](https://github.com/fchmainy/nginx-aks-demo/blob/main/docs/images/Task2-topology.png?raw=true)

  **Duration:**: 30 minutes.

  **Lab Guide:**
  [Task5: API Management] (https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/task2/README.md)


  **Features:**
  - NGINX API Management :
      NGINX Controller (https://www.nginx.com/products/nginx-controller/)



# Upcoming:
- version 1: Direct MS to MS
- version 2: introducing NGINX API GW
- version 3: NGINX Service Mesh
- version 4: gRPC schema validation

# Courtesy of:
Thanks to https://www.npmjs.com/package/json-server for the zero coding JSON Server.