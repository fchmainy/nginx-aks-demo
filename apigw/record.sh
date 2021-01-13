# Set the following environment variables
# export CTRL_IP
# export CTRL_FQDN=controller.f5demolab.org
# export CTRL_USERNAME
# export CTRL_PASSWORD
# export LOCATION=aks

export HOSTNAME="$(hostname -f)"
export CTRL_FQDN=$(echo $ENV_CONTROLLER_URL | awk -F'https://' '{print $2}' | awk -F':8443' '{print $1}')

# AUthenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$CTRL_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

gwExists=$(curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY --write-out '%{http_code}' --silent --output /dev/null)

# if the gateway does not exist, we are creating it, otherwise we add the instance reference to the gateway.
if [ $gwExists -ne 200 ]
then
        envsubst < gateways.json > $HOSTNAME.json
else
	curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY -o update.json
	jq '.desiredState.ingress.placement.instanceRefs += [{"ref": "/infrastructure/locations/aks/instances/'$HOSTNAME'"}]' update.json > $HOSTNAME.json

fi
curl -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY
