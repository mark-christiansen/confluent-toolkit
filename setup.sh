#!/bin/bash

START=$SECONDS

# env from user input
ENVS=("mtls-acl" "sasl-rbac" "scram-rbac" "gssapi-acl" "gssapi-rbac" "cl" "kraft")
[[ -z "$1" ]] && { echo "Environment (${ENVS[@]}) not specified" ; exit 1; }
[[ ! " ${ENVS[@]} " =~ " $1 " ]] && { echo "Invalid environment $1 specified. Valid envs are (${ENVS[@]})." ; exit 1; }
ENV=$1

# cleanup volumes
echo ""
echo "******************************************************************"
echo "Cleaning up volumes"
echo "******************************************************************"
echo ""
./cleanup.sh

# create certs
echo ""
echo "******************************************************************"
echo "Creating certificates"
echo "******************************************************************"
echo ""
rm -f certs/*
cd cert-gen
./create-all.sh

# create MDS key pair for token listener
echo ""
echo "******************************************************************"
echo "Creating MDS key pair"
echo "******************************************************************"
echo ""
cd ../mds
./create-token-key-pair.sh

# launch zookeeper servers and brokers
echo ""
echo "******************************************************************"
echo "Starting zookeeper servers and brokers"
echo "******************************************************************"
echo ""
cd ../
docker-compose -f confluent-platform-$ENV.yml up -d

# determine role to use for executing scripts on the client container from the env
ROLE=""
if [[ $ENV == "sasl-rbac" ]]; then
  ROLE="sasl"
elif [[ $ENV == "scram-rbac" ]]; then
  ROLE="scram"
elif [[ $ENV == "mtls-acl" ]]; then
  ROLE="mtls"
elif [[ $ENV == "gssapi-acl" ]]; then
  ROLE="gssapi_super"
elif [[ $ENV == "gssapi-rbac" ]]; then
  ROLE="gssapi"
elif [[ $ENV == "kraft" ]]; then
  ROLE="mtls_noacl"
else 
  DURATION=$(( SECONDS - START ))
  echo ""
  echo "Finished setup of environment $ENV in $DURATION secs"
  exit 0
fi

# create datagen connector
echo ""
echo "******************************************************************"
echo "Creating datagen connector"
echo "******************************************************************"
echo ""
docker exec -it client /bin/bash -c "cd /scripts/connect && ./create-datagen.sh $ROLE"

# create datagen connector
echo ""
echo "******************************************************************"
echo "Creating jdbc-sink connector"
echo "******************************************************************"
echo ""
docker exec -it client /bin/bash -c "cd /scripts/connect && ./create-jdbc-sink.sh $ROLE"

DURATION=$(( SECONDS - START ))
echo ""
echo "Finished setup of environment $ENV in $DURATION secs"
exit 0