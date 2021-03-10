#!/bin/bash

docker build -t registry.gitlab.com/k8sfch/demo-name-generator/generator:v0.0.1 .
docker push registry.gitlab.com/k8sfch/demo-name-generator/generator:v0.0.1
