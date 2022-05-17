#!/bin/sh

# Docker workaround: Remove check for KAFKA_ZOOKEEPER_CONNECT parameter
sed -i '/KAFKA_ZOOKEEPER_CONNECT/d' /etc/confluent/docker/configure

# Docker workaround: Ignore cub zk-ready
sed -i 's/cub zk-ready/echo ignore zk-ready/' /etc/confluent/docker/ensure

# cluster ID needs to be the same across brokers
# CLUSTER_ID=$(kafka-storage random-uuid)
CLUSTER_ID='VN8Z9nGrQ9KycFPXVStI0w'

# KRaft required step: Format the storage directory with a new cluster ID
echo "kafka-storage format --ignore-formatted -t $CLUSTER_ID -c /etc/kafka/kafka.properties" >> /etc/confluent/docker/ensure