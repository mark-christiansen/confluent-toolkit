#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Filter type not specified (Role/Principal)" ; exit 1; }
TYPE="$2"

[[ -z "$3" ]] && { echo "Role/Principal not specified" ; exit 1; }
FILTER="--role $3"
if [[ $TYPE == "Principal" ]]; then
  FILTER="--principal $3"
fi

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent iam rolebinding list --kafka-cluster-id $CLUSTER_ID $FILTER