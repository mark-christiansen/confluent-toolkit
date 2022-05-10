#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

# create DLQ topic for jdbcsink connector
DLQ="dlq.jdbcsink"
echo "Creating jdbcsink connector topic \"$DLQ\""
kafka-topics --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --create --topic $DLQ --partitions 1
echo "Created jdbcsink connector topic \"$DLQ\""

TOPIC="env.app.person"
PRINCIPAL="jdbcsink"
GROUP=$PRINCIPAL

# create RBAC role bindings for jdbcsink connector if RBAC is enabled
if [[ $RBAC == "true" ]]; then

  CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
  [[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
  echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

  confluent iam rolebinding create --principal User:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP --cluster-name $KAFKA_CLUSTER
  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperRead --resource Topic:$TOPIC --cluster-name $KAFKA_CLUSTER
  confluent iam rolebinding create --principal User:$PRINCIPAL --role ResourceOwner --resource Topic:$DLQ --cluster-name $KAFKA_CLUSTER

  SUBJECT="env.app.person-value"
  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperRead --resource Subject:$SUBJECT --cluster-name $SCHEMA_CLUSTER

# create ACLs for jdbcsink connector if RBAC not enabled
else

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${PRINCIPAL}" \
  --allow-host "*" --consumer --topic $TOPIC --group $GROUP
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$TOPIC\" and principal \"$PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${PRINCIPAL}" \
  --allow-host "*" --producer --topic $DLQ
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$DLQ\" and principal \"$PRINCIPAL\"" && exit

fi

BASIC_AUTH=""
if [[ $SASL == "true" ]]; then
  BASIC_AUTH="-u connect:connect-secret"
fi

# verify conenct server is running and accepting requests
printf 'Waiting until connect server REST API is ready to accept requests'
until $(curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server REST API is ready to accept requests"

if [[ $SSL == "true" ]]; then

  KEYSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.$DOMAIN.keystore.jks"
  TRUSTSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.$DOMAIN.truststore.jks"
  PASSWORD="jdbcsink-secret"
  DB_USERNAME="postgres"
  DB_PASSWORD="postgrespass"

  if [[ $SASL == "true" ]]; then

    SASL_MECHANISM="PLAIN"
    JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\\\"\${vault:secret/jdbcsink:cp_username}\\\" password=\\\"\${vault:secret/jdbcsink:cp_password}\\\";"
    if [[ $ENV == "scram" ]]; then
      SASL_MECHANISM="SCRAM-SHA-512"
      JAAS_CONFIG="org.apache.kafka.common.security.scram.ScramLoginModule required username=\\\"\${vault:secret/jdbcsink:cp_username}\\\" password=\\\"\${vault:secret/jdbcsink:cp_password}\\\";"
    elif [[ $ENV == "gssapi" ]]; then
      SASL_MECHANISM="GSSAPI"
      JAAS_CONFIG="com.sun.security.auth.module.Krb5LoginModule required useKeyTab=true storeKey=true keyTab=\\\"/etc/security/keytabs/connect.keytab\\\" principal=\\\"\${vault:secret/jdbcsink:cp_username}@${REALM}\\\";"
    fi

    echo "Creating jdbcsink connector secrets"
    # create username secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PRINCIPAL\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/username/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create username secret for jdbcsink connector" && exit
    fi

    # create password secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PASSWORD\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/password/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create password secret for jdbcsink connector" && exit
    fi

    # create keystore password secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$KEYSTORE_PASSWORD\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/keypassword/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create keystore password secret for jdbcsink connector" && exit
    fi

    # create database username secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$DB_USERNAME\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/dbusername/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create username secret for jdbcsink connector" && exit
    fi

    # create database password secret
    HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$DB_PASSWORD\"}" --write-out "%{http_code}" \
    $KAFKA_CONNECT_URL/secret/paths/$PRINCIPAL/keys/dbpassword/versions)
    if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
      echo "Unable to create password secret for jdbcsink connector" && exit
    fi

    # create jdbc sink connector for SASL SSL env
    POST_DATA=$(cat <<EOF
{
  "name": "$PRINCIPAL",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "batch.size": "100",
    "connection.url": "jdbc:postgresql://postgres:5432/kafka",
    "connection.user": "\${vault:secret/jdbcsink:db_username}",
    "connection.password": "\${vault:secret/jdbcsink:db_password}",
    "topics.regex": "env\\\\.app\\\\..*",
    "table.name.format": "\${topic}",
    "auto.create": "true",
    "auto.evolve": "true",
    "pk.mode": "record_key",
    "pk.fields": "id",
    "insert.mode": "upsert",
    "delete.enabled": "true",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": "$DLQ",
    "errors.deadletterqueue.topic.replication.factor": 3,
    "errors.deadletterqueue.context.headers.enable": true,
    "errors.retry.delay.max.ms": 10000,
    "errors.retry.timeout": 30000,
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "\${secret:jdbcsink:keypassword}",
    "value.converter.schema.registry.ssl.key.password": "\${secret:jdbcsink:keypassword}",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "\${secret:jdbcsink:keypassword}",
    "value.converter.schemas.enable": "true",
    "value.converter.schema.registry.basic.auth.user.info": "\${vault:secret/jdbcsink:cp_username}:\${vault:secret/jdbcsink:cp_password}",
    "value.converter.schema.registry.basic.auth.credentials.source": "USER_INFO",
    "consumer.override.group.id": "$GROUP",
    "consumer.override.sasl.mechanism": "$SASL_MECHANISM",
    "consumer.override.sasl.jaas.config": "$JAAS_CONFIG",
    "producer.override.client.id": "jdbcsink-producer",
    "producer.override.sasl.mechanism": "$SASL_MECHANISM",
    "producer.override.sasl.jaas.config": "$JAAS_CONFIG",
    "transforms":"dropPrefix",
    "transforms.dropPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.dropPrefix.regex":"env\\\\.app\\\\.(.*)",
    "transforms.dropPrefix.replacement":"public.\$1"
  }
}
EOF
    )

  else

    # create datagen connector
    POST_DATA=$(cat <<EOF
{
  "name": "$PRINCIPAL",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "batch.size": "100",
    "connection.url": "jdbc:postgresql://postgres:5432/kafka",
    "connection.user": "postgres",
    "connection.password": "postgrespass",
    "topics.regex": "env\\\\.app\\\\..*",
    "table.name.format": "\${topic}",
    "auto.create": "true",
    "auto.evolve": "true",
    "pk.mode": "record_key",
    "pk.fields": "id",
    "insert.mode": "upsert",
    "delete.enabled": "true",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": "$DLQ",
    "errors.deadletterqueue.topic.replication.factor": 3,
    "errors.deadletterqueue.context.headers.enable": true,
    "errors.retry.delay.max.ms": 10000,
    "errors.retry.timeout": 30000,
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.key.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schemas.enable": "true",
    "consumer.override.group.id": "$GROUP",
    "consumer.override.security.protocol": "SSL",
    "consumer.override.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "consumer.override.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "consumer.override.ssl.key.password": "$KEYSTORE_PASSWORD",
    "consumer.override.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "consumer.override.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "producer.override.client.id": "jdbcsink-producer",
    "producer.override.security.protocol": "SSL",
    "producer.override.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "producer.override.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.key.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "producer.override.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "transforms":"dropPrefix",
    "transforms.dropPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.dropPrefix.regex":"env\\\\.app\\\\.(.*)",
    "transforms.dropPrefix.replacement":"public.\$1"
  }
}
EOF
    )

  fi

else

  # create datagen connector
  POST_DATA=$(cat <<EOF
{
  "name": "jdbcsink",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "batch.size": "100",
    "connection.url": "jdbc:postgresql://postgres:5432/kafka",
    "connection.user": "postgres",
    "connection.password": "postgrespass",
    "topics.regex": "env\\\\.app\\\\..*",
    "table.name.format": "\${topic}",
    "auto.create": "true",
    "auto.evolve": "true",
    "pk.mode": "record_key",
    "pk.fields": "id",
    "insert.mode": "upsert",
    "delete.enabled": "true",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": "dlq",
    "errors.deadletterqueue.topic.replication.factor": 3,
    "errors.deadletterqueue.context.headers.enable": true,
    "errors.retry.delay.max.ms": 10000,
    "errors.retry.timeout": 30000,
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "http://schema1:8081",
    "value.converter.schemas.enable": "true",
    "consumer.override.group.id": "jdbc-sink-connector",
    "transforms":"dropPrefix",
    "transforms.dropPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.dropPrefix.regex":"env\\\\.app\\\\.(.*)",
    "transforms.dropPrefix.replacement":"public.\$1"
  }
}
EOF
  )

fi

echo ""
echo "Creating jdbcsink connector"
curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "$POST_DATA" $KAFKA_CONNECT_URL/connectors
echo ""
echo "Created jdbcsink connector"

sleep 10
echo ""
echo "Checking status of jdbcsink connector"
HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" --write-out "%{http_code}" $KAFKA_CONNECT_URL/connectors/$PRINCIPAL/status)
if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
  echo "Unable to check status jdbcsink connector" && exit
fi