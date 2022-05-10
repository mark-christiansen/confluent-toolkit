#!/bin/bash

# env from user input
ENVS=("mtls-acl" "sasl-rbac" "scram-rbac" "gssapi-acl" "gssapi-rbac")
[[ -z "$1" ]] && { echo "Environment (${ENVS[@]}) not specified" ; exit 1; }
[[ ! " ${ENVS[@]} " =~ " $1 " ]] && { echo "Invalid environment $1 specified. Valid envs are (${ENVS[@]})." ; exit 1; }
ENV=$1

# teardown borkers and zookeeper servers
docker-compose -f confluent-platform-$ENV.yml down

# cleanup volumes
./cleanup.sh