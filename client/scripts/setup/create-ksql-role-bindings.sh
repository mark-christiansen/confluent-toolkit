#!/bin/bash

echo "Creating RBAC roles for KSQL servers"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="ksql"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="ksqls"
fi

TOPIC="_confluent-ksql-"
GROUP="_confluent-ksql-"
SERVICE_ID="ksql-cluster"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$TOPIC --prefix \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP --prefix \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource TransactionalId:$SERVICE_ID \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$SERVICE_ID --prefix \
--kafka-cluster-id $CLUSTER_ID

SCHEMA_CLUSTER="schema-registry"
SUBJECT="_confluent-ksql-$SERVICE_ID"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Subject:$SUBJECT --prefix \
--kafka-cluster-id $CLUSTER_ID --schema-registry-cluster-id $SCHEMA_CLUSTER

INTERCEPTOR_TOPIC="_confluent-monitoring"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --resource Topic:$INTERCEPTOR_TOPIC --prefix \
--kafka-cluster-id $CLUSTER_ID

echo "Created RBAC roles for KSQL servers"