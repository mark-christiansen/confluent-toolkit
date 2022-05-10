#!/bin/bash

echo "Creating general ACLs for Control Center"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPALS=("c3")
CONTROL_CENTER_NAME="_confluent-controlcenter"
CONTROL_CENTER_ID="7-0-1-1"
COMMAND_TOPIC="_confluent-command"
MONITORING_TOPIC="_confluent-monitoring"
METRICS_TOPIC="_confluent-metrics"
APP_ID="$CONTROL_CENTER_NAME-$CONTROL_CENTER_ID"

for PRINCIPAL in "${PRINCIPALS[@]}"
do

  echo "Setting acls for topics prefixed with $APP_ID-"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer \
      --topic "$APP_ID-" --resource-pattern-type prefixed #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer \
      --group "$APP_ID" --topic "$APP_ID-" --resource-pattern-type prefixed #> /dev/null 2>&1 || echo "Failed"

  echo "Setting acls for topic $COMMAND_TOPIC"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer \
      --topic "$COMMAND_TOPIC" #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer \
      --group "$APP_ID" --topic "$COMMAND_TOPIC" #> /dev/null 2>&1 || echo "Failed"
 
  echo "Setting acls for topic $MONITORING_TOPIC"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer \
      --topic "$MONITORING_TOPIC" #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer \
      --group "$APP_ID" --topic "$MONITORING_TOPIC" #> /dev/null 2>&1 || echo "Failed"

  echo "Setting acls for topic $METRICS_TOPIC"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer \
      --topic "$METRICS_TOPIC" #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer \
      --group "$APP_ID" --topic "$METRICS_TOPIC" #> /dev/null 2>&1 || echo "Failed"

done

echo "Created general ACLs for Control Center"