#!/bin/bash

echo "Creating RBAC roles for Kafka Connect servers"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="connect"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="connects"
fi

CONFIGS_TOPIC="docker-connect-configs"
OFFSETS_TOPIC="docker-connect-offsets"
STATUS_TOPIC="docker-connect-status"
GROUP="docker-connect-cluster"
SECRETS_TOPIC="_confluent-secrets"
SECRETS_GROUP="secret-registry"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$CONFIGS_TOPIC \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$OFFSETS_TOPIC \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$STATUS_TOPIC \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$SECRETS_TOPIC \
--kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$SECRETS_GROUP \
--kafka-cluster-id $CLUSTER_ID
# only set if the connect user is the user used for conenct devops
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --kafka-cluster-id $CLUSTER_ID \
--connect-cluster-id $GROUP
# have connect worker dynamically create DLQ topics
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:dlq. --prefix \
--kafka-cluster-id $CLUSTER_ID

echo "Created RBAC roles for Kafka Connect servers"