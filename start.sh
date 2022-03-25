#!/bin/bash

START=$SECONDS

# env from user input
ENVS=("mtls-acl" "sasl-rbac" "cl")
[[ -z "$1" ]] && { echo "Environment (${ENVS[@]}) not specified" ; exit 1; }
[[ ! " ${ENVS[@]} " =~ " $1 " ]] && { echo "Invalid environment $1 specified. Valid envs are (${ENVS[@]})." ; exit 1; }
ENV=$1

# launch Confluent Platform
echo ""
echo "******************************************************************"
echo "Starting Confluent Platform"
echo "******************************************************************"
echo ""
docker-compose -f confluent-platform-$ENV.yml up -d

# determine role to use for executing scripts on the client container
ROLE=""
if [[ $ENV == "sasl-rbac" ]]; then
  ROLE="sasl"
elif [[ $ENV == "mtls-acl" ]]; then
  ROLE="mtls"
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
if [[ $ROLE == "sasl" ]]; then
  docker exec -it client /bin/bash -c "cd /scripts && ./login.sh $ROLE && cd /scripts/connect && ./create-datagen.sh $ROLE"
else
  docker exec -it client /bin/bash -c "cd /scripts/connect && ./create-datagen.sh $ROLE"
fi

# create jdbc sink connector
echo ""
echo "******************************************************************"
echo "Creating jdbc sink connector"
echo "******************************************************************"
echo ""
if [[ $ROLE == "sasl" ]]; then
  docker exec -it client /bin/bash -c "cd /scripts && ./login.sh $ROLE && cd /scripts/connect && ./create-jdbc-sink.sh $ROLE"
else
  docker exec -it client /bin/bash -c "cd /scripts/connect && ./create-jdbc-sink.sh $ROLE"
fi

DURATION=$(( SECONDS - START ))
echo ""
echo "Finished setup of environment $ENV in $DURATION secs"
exit 0