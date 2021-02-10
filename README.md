# Description
This is a very simple kubernetes demo application intended to show most of the benefits of using F5 Technology for your application delivery and security.
It is composed of multiple technology frameworks.

![alt text](https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/images/topology.jpeg)

# Features
- Ingress Canary testing
- Cross-namespace Ingress
- JWT validation
- MS API GW

# Lab Documentation
## Task 1: Deploy the version 1 of the application
Simple application composed of multiple microservices.
  [Task1: Deploy the version 1 of the application] (https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/task1/README.md)
  ![alt text](https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/images/task1-topology.jpg)

**Features:**
- NGINX+ Ingress Service
- Cross-Namespace deployment


## Task 2: API Management
  **Goal:**
  We are making our simple application to evolve with a more secure framework and Application Security
  Two different deployment model for our API Gateway in this case:
    - Shared and centralized API Gateway in a dedicated namespace so micro-services can talk one with the others through this API Gateway.
      - scales independantly 

    - API Gateway injected as a sidecar
      - specialized for the associated application sharing the same pod.
      in our scenario, the generator is the central piece of the configuration so we decided to make it have its own APIGW closest to the application.
        - it scales 1:1 along with the application

  ![alt text](https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/images/task2-topology.jpg)

  **Duration:**: 30 minutes.

  **Lab Guide:**
  [Task2: API Management] (https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/task2/README.md)


  **Features:**
  - NGINX API Management :
      NGINX Controller (https://www.nginx.com/products/nginx-controller/)



## Task 3: Web Application and API Protection (WAAP)
  **Goal:**
    Protect Inbound application and API traffic from Advanced attacks (OWASP TopN, L7 DDoS, Threat Campaigns...) and microservice to microservice communications.

  **Duration:**: 30 minutes


  **Features:**
  - NGINX App Protect (https://www.nginx.com/products/nginx-app-protect/)

  **Lab Guide:**
  [Task3: WAAP] (https://raw.githubusercontent.com/fchmainy/nginx-aks-demo/main/docs/task3/README.md)


## Task 5: Service Mesh
**Goal:**
    Securing Microservice to Microservice communication in a hollistic Zero-Trust model while extending the visibility and

**Duration:**


**Features:**


**Lab Guide:**

# Upcoming:
- version 1: Direct MS to MS
- version 2: introducing NGINX API GW
- version 3: NGINX Service Mesh
- version 4: gRPC schema validation

# Courtesy of:
Thanks to https://www.npmjs.com/package/json-server for the zero coding JSON Server.