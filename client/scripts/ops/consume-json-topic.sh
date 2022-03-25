#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2
[[ -z "$3" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$3

kafka-console-consumer -bootstrap-server $BROKER_URL --consumer.config $KAFKA_CONFIG \
--property print.key=true --property key.separator="   " --topic $TOPIC --group $GROUP --from-beginning