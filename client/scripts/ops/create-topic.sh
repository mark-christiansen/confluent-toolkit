#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Partitions not specified" ; exit 1; }
PARTITIONS=$3

kafka-topics -bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --create --topic $TOPIC --partitions $PARTITIONS
