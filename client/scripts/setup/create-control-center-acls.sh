#!/bin/bash

echo "Creating general ACLs for Control Center"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

C3_PRINCIPALS=("c3")
C3_GROUP="_confluent-controlcenter-"
C3_TOPIC="_confluent-controlcenter-"
BALANCER_TOPIC="_confluent_balancer_"
LICENSE_TOPIC="_confluent-command"
METRICS_TOPIC="_confluent-metrics"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

for C3_PRINCIPAL in "${C3_PRINCIPALS[@]}"
do
 
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --operation Describe --cluster $CLUSTER_ID
  [ $? -eq 1 ] && echo "unable to make create ACL for cluster \"$CLUSTER_ID\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --operation DescribeConfigs --cluster $CLUSTER_ID
  [ $? -eq 1 ] && echo "unable to create producer ACL for cluster \"$CLUSTER_ID\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic $C3_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"$C3_TOPIC\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --producer --topic $C3_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create producer ACL for topic \"$C3_TOPIC\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --consumer --group $C3_GROUP --topic $C3_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create consumer ACL for group \"$C3_GROUP\", topic \"$C3_TOPIC\", and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --producer --topic $LICENSE_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create producer ACL for topic \"$LICENSE_TOPIC\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --consumer --group $C3_GROUP --topic $LICENSE_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create consumer ACL for group \"$C3_GROUP\", topic \"$LICENSE_TOPIC\", and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic $METRICS_TOPIC
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"$METRICS_TOPIC\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --producer --topic $METRICS_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create producer ACL for topic \"$METRICS_TOPIC\" and principal \"$C3_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${C3_PRINCIPAL}" \
  --allow-host "*" --consumer --group $C3_GROUP --topic $METRICS_TOPIC --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to create consumer ACL for group \"$C3_GROUP\", topic \"$METRICS_TOPIC\", and principal \"$C3_PRINCIPAL\"" && exit

done

echo "Created general ACLs for Control Center"