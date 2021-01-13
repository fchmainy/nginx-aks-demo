#!/bin/bash

docker build -t registry.gitlab.com/k8sfch/demo-name-generator/locations .
docker push registry.gitlab.com/k8sfch/demo-name-generator/locations
