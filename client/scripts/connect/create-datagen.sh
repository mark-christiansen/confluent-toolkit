#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

# create input topic for datagen connector
TOPIC="env.app.person"
echo "Creating datagen connector topic \"$TOPIC\""
kafka-topics --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --create --topic $TOPIC --partitions 1
echo "Created datagen connector topic \"$TOPIC\""

PRINCIPAL="datagen"

# create RBAC role bindings for datagen connector if RBAC is enabled
if [[ $RBAC == "true" ]]; then

  # login to cluster
  ../login.sh $ENV

  CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
  [[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
  echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperWrite --resource Topic:$TOPIC --kafka-cluster-id $CLUSTER_ID

  SUBJECT="env.app.person-value"
  SCHEMA_CLUSTER="schema-registry"
  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperWrite --resource Subject:$SUBJECT \
   --kafka-cluster-id $CLUSTER_ID --schema-registry-cluster-id $SCHEMA_CLUSTER

# create ACLs for datagen connector if RBAC not enabled
else

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${PRINCIPAL}" \
  --allow-host "*" --producer --topic $TOPIC
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$TOPIC\" and principal \"$PRINCIPAL\"" && exit

fi

# set basic auth username:secret if SASL enabled
BASIC_AUTH=""
if [[ $SASL == "true" ]]; then
  BASIC_AUTH="-u connect:connect-secret"
fi

# verify conenct server is running and accepting requests
echo "curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors"
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

if [[ $SSL == "true" ]]; then

  KEYSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.kafka_network.keystore.jks"
  TRUSTSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.kafka_network.truststore.jks"
  PASSWORD="datagen-secret"

  if [[ $SASL == "true" ]]; then

    SASL_MECHANISM="PLAIN"
    SASL_MODULE="org.apache.kafka.common.security.plain.PlainLoginModule"
    if [[ $ENV == "scram" ]]; then
      SASL_MECHANISM="SCRAM-SHA-512"
      SASL_MODULE="org.apache.kafka.common.security.scram.ScramLoginModule"
    fi

    echo "Creating datagen connector secrets"
    # create username secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PRINCIPAL\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/username/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create username secret for datagen connector" && exit
    fi

    # create password secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PASSWORD\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/password/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create password secret for datagen connector" && exit
    fi

    # create keystore password secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$KEYSTORE_PASSWORD\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/keypassword/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create keystore password secret for datagen connector" && exit
    fi

    # create datagen connector for SASL SSL env
    POST_DATA=$(cat <<EOF
{
  "name": "$PRINCIPAL",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "\${secret:datagen:keypassword}",
    "value.converter.schema.registry.ssl.key.password": "\${secret:datagen:keypassword}",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "\${secret:datagen:keypassword}",
    "value.converter.schemas.enable": "true",
    "value.converter.schema.registry.basic.auth.user.info": "\${secret:datagen:username}:\${secret:datagen:password}",
    "value.converter.schema.registry.basic.auth.credentials.source": "USER_INFO",
    "max.interval": "1000",
    "iterations": "5000",
    "producer.override.client.id": "$PRINCIPAL-producer",
    "producer.override.security.protocol": "SASL_SSL",
    "producer.override.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "producer.override.ssl.keystore.password": "\${secret:datagen:keypassword}",
    "producer.override.ssl.key.password": "\${secret:datagen:keypassword}",
    "producer.override.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "producer.override.ssl.truststore.password": "\${secret:datagen:keypassword}",
    "producer.override.sasl.mechanism": "$SASL_MECHANISM",
    "producer.override.sasl.jaas.config": "$SASL_MODULE required username=\"\${vault:secret/datagen:cp_username}\" password=\"\${vault:secret/datagen:cp_password}\";"
  }
}
EOF
    )

  else

    # create datagen connector for mTLS env
    POST_DATA=$(cat <<EOF
{
  "name": "$PRINCIPAL",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.key.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schemas.enable": "true",
    "value.converter.basic.auth.credentials.source": "USER_INFO",
    "value.converter.basic.auth.user.info": "$PRINCIPAL:$PASSWORD",
    "max.interval": "1000",
    "iterations": "1000",
    "producer.override.security.protocol": "SSL",
    "producer.override.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "producer.override.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.key.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "producer.override.ssl.truststore.password": "$KEYSTORE_PASSWORD"
  }
}
EOF
    )

  fi

else

    # create datagen connector for open env
    POST_DATA=$(cat <<EOF
{
  "name": "$PRINCIPAL",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schemas.enable": "true",
    "max.interval": "1000",
    "iterations": "1000"
  }
}
EOF
    )

fi

echo ""
echo "Creating datagen connector"
HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "$POST_DATA" --write-out "%{http_code}" $KAFKA_CONNECT_URL/connectors)
if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
  echo "Unable to create datagen connector" && exit
fi
echo ""
echo "Created datagen connector"

sleep 10
echo ""
echo "Checking status of datagen connector"
HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" --write-out "%{http_code}" $KAFKA_CONNECT_URL/connectors/$PRINCIPAL/status)
if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
  echo "Unable to check status datagen connector" && exit
fi