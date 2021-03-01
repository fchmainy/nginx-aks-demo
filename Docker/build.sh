#!/bin/bash

REGISTRY=""
TAG=""

Help()
{
	echo "Build and Push all the container images to your remote container registry"
	echo
	echo "Syntax: sh build.sh [-r|h|t|k]"
	echo "options:"
	echo "r		registry endpoint"
	echo "h		print this help"
	echo "t		add a tag to the image"
	echo
	echo "example:"
       	echo "sh build.sh -r registry.gitlab.com/k8sapp -t v1.0.1"
	echo	
}	

while getopts "hr:t:" option; do
	case $option in
		h)
			Help
			exit 0
			;;
		r)
			REGISTRY="$OPTARG"
			;;
		t)
			TAG="$OPTARG"
			;;
		\?)
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
	esac
done
#shift $((OPTIND -1))

for dir in */     # list directories in the form "/tmp/dirname/"
do
	dir=${dir%*/}      # remove the trailing "/"
    	echo "${dir##*/}"    # print everything after the final "/"
	cd "${dir##*/}"
	echo "docker build -t $REGISTRY/${dir##*/}:$TAG ."
	docker build -t ${REGISTRY}/${dir##*/}:${TAG} .
	docker push ${REGISTRY}/${dir##*/}:${TAG}
done
