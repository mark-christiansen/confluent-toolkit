#!/bin/bash

echo "Creating general ACLs for Control Center"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPALS=("c3")
INTERMEDIATE_TOPICS=(Group-FIFTEEN_SECONDS-changelog Group-ONE_HOUR-changelog Group-ONE_WEEK-changelog MonitoringMessageAggregatorWindows-FIFTEEN_SECONDS-changelog MonitoringMessageAggregatorWindows-ONE_HOUR-changelog MonitoringMessageAggregatorWindows-ONE_WEEK-changelog MonitoringStream-FIFTEEN_SECONDS-changelog MonitoringStream-ONE_HOUR-changelog MonitoringStream-ONE_WEEK-changelog MonitoringVerifierStore-changelog aggregate-topic-partition aggregate-topic-partition-changelog aggregatedTopicPartitionTableWindows-FIFTEEN_SECONDS-changelog aggregatedTopicPartitionTableWindows-ONE_HOUR-changelog aggregatedTopicPartitionTableWindows-ONE_WEEK-changelog error-topic group-aggregate-topic-FIFTEEN_SECONDS group-aggregate-topic-FIFTEEN_SECONDS-changelog group-aggregate-topic-ONE_HOUR group-aggregate-topic-ONE_HOUR-changelog group-aggregate-topic-ONE_WEEK group-aggregate-topic-ONE_WEEK-changelog group-stream-extension-rekey group-stream-extension-rekey-changelog monitoring-aggregate-rekey monitoring-aggregate-rekey-changelog monitoring-message-rekey)
ZK_CONNECT="$ZOO1_URL,$ZOO2_URL,$ZOO3_URL"
CONTROL_CENTER_NAME="_confluent-controlcenter"
CONTROL_CENTER_ID="7-0-1-1"
LICENSE_TOPIC="_confluent-command"
MONITORING_TOPIC="_confluent-monitoring"
APP_ID="$CONTROL_CENTER_NAME-$CONTROL_CENTER_ID"

for PRINCIPAL in "${PRINCIPALS[@]}"
do

  for topic_suffix in "${INTERMEDIATE_TOPICS[@]}"
  do
    topic="$APP_ID-$topic_suffix"
    echo "Setting acls for topic $topic"
    kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer --topic "$topic" #> /dev/null 2>&1 || echo "Failed"
    kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer --group "$APP_ID" --topic "$topic" #> /dev/null 2>&1 || echo "Failed"
  done

  echo "Setting acls for topic $LICENSE_TOPIC"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer --topic "$LICENSE_TOPIC" #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer --group "$APP_ID" --topic "$LICENSE_TOPIC" #> /dev/null 2>&1 || echo "Failed"
 

  echo "Setting acls for topic $MONITORING_TOPIC"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --producer --topic "$MONITORING_TOPIC" #> /dev/null 2>&1 || echo "Failed"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" --consumer --group "$APP_ID" --topic "$MONITORING_TOPIC" #> /dev/null 2>&1 || echo "Failed"
 
done

echo "Created general ACLs for Control Center"