#!/bin/bash

docker build -t registry.gitlab.com/--path--/apigw:v1.0.0 --build-arg CONTROLLER_URL=https://controller.myfqdn.com:8443/1.4 --build-arg API_KEY='APIKEYAPIKEYAPIKEYAPIKEYAPIKEYAPIKEYAPIKEY' --build-arg STORE_UUID=True --build-arg LOCATION=aks_apigw-ns .
docker push registry.gitlab.com/k8sfch/demo-name-generator/apigw:v1.0.0

