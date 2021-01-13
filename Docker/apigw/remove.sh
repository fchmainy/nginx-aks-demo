# export HOSTNAME="$(hostname -f)"
# export CTRL_FQDN=$(echo $ENV_CONTROLLER_URL | awk -F'https://' '{print $2}' | awk -F':8443' '{print $1}')

# Authenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$CTRL_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

# 1. Remove the instance from gateway
curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY -o update.json
jq '.desiredState.ingress.placement.instanceRefs -= [{"ref": "/infrastructure/locations/'$LOCATION'/instances/'$HOSTNAME'"}]' update.json > $HOSTNAME.json

# cat $HOSTNAME.json

curl -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$LOCATION'/gateways/'$GATEWAY

# 2. Remove the instance from infrastructure
curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' -X DELETE --url 'https://'$CTRL_FQDN'/api/v1/infrastructure/locations/'$LOCATION'/instances/'$HOSTNAME
