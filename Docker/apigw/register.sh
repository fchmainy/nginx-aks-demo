# Set the following environment variables
# export CTRL_IP
# export CTRL_FQDN=controller.f5demolab.org
# export CTRL_USERNAME
# export CTRL_PASSWORD
# export LOCATION=aks

# AUthenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$CTRL_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

# curl -sk -b cookie.txt -c cookie.txt -X GET --url 'https://'$CTRL_FQDN'/api/v1/platform/login'

# Wait until we get a corresponding gateway
#curl -sk -b cookie.txt -c cookie.txt -X GET \
#    --connect-timeout 5 \
#    --max-time 10 \
#    --retry 5 \
#    --retry-delay 0 \
#    --retry-max-time 40 \
#    --url 'https://'$CTRL_FQDN'/api/v1/infrastructure/locations/'$LOCATION'/instances' \
#    -o gateways.json

#nbGtws = $(cat gateways.json | jq '.items | length')
gwExists = $(curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY --write-out '%{http_code}' --silent --output /dev/null)

# if the gateway does not exist, we are creating it, otherwise we add the instance reference to the gateway.
if gwExists != 200
then
        envsubst < gateway.json > $HOSTNAME.json
else
	curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY -o update.json
	jq '.desiredState.ingress.placement.instanceRefs += [{"ref": "/infrastructure/locations/aks/instances/'$HOSTNAME'"}]' update.json > $HOSTNAME.json
	
fi
curl -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY


# curl -sk -b cookie.txt -c cookie.txt -X POST -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways' 

#if nbGtws == 0
#then
#        echo 'test'
#        envsubst < gateway.json > $HOSTNAME.json
#	curl -sk -b cookie.txt -c cookie.txt -X POST @d$HOSTNAME.json --header 'Content-Type: application/json' --url /api/v1/services/environments/aks/gateways
#	curl -sk -b cookie.txt -c cookie.txt -X POST -d @$HOSTNAME.json --header 'Content-Type: application/json' --url https://$CTRL_FQDN/api/v1/services/environments/aks/gateways -v
#else
#
#fi
#
#jq '.desiredState.placement.instanceRefs += [{"ref": "/infrastructure/locations/aks/instances/$HOSTNAME"}]' gateways.json
