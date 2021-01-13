#!/bin/bash

docker build -t registry.gitlab.com/k8sfch/demo-name-generator/apigw2 --build-arg CONTROLLER_URL=https://controller.f5demolab.org:8443/1.4 --build-arg API_KEY='25b06e4fc0e7d029badbad4708621231' --build-arg STORE_UUID=True --build-arg LOCATION=aks .
docker push registry.gitlab.com/k8sfch/demo-name-generator/apigw2

