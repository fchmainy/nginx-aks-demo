#!/bin/bash

docker build -t registry.gitlab.com/k8sfch/demo-name-generator/apigw --build-arg CONTROLLER_URL=https://controller.f5demolab.org:8443/1.4 --build-arg API_KEY='3bbb7951e9baebc92c69e37e083e49c9' --build-arg STORE_UUID=True --build-arg LOCATION=aks_apigw-ns .
docker push registry.gitlab.com/k8sfch/demo-name-generator/apigw

