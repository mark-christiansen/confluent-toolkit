#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Cluster link name not specified" ; exit 1; }
NAME=$2

# get the kafka cluster ID
SRC_CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $SRC_BROKER_URL --config $SRC_KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$SRC_CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $SRC_CLUSTER_ID"

kafka-cluster-links --bootstrap-server $BROKER_URL --create --link $NAME --cluster-id $SRC_CLUSTER_ID \
--command-config $KAFKA_CONFIG --config-file $CL_CONFIG

echo "Finished creating cluster link $NAME"