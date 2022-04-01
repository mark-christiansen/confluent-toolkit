#!/bin/bash

echo "Creating RBAC roles for admin clients"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="admin"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="admins"
fi

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --kafka-cluster-id $CLUSTER_ID

SCHEMA_CLUSTER="schema-registry"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --kafka-cluster-id $CLUSTER_ID --schema-registry-cluster-id $SCHEMA_CLUSTER

CONNECT_CLUSTER="docker-connect-cluster"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --kafka-cluster-id $CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER

echo "Created RBAC roles for admin clients"