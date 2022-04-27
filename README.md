# confluent-toolkit

## Summary

This project is used to launch, test and teardown different Confluent Platform environments in docker. The following environments have configurations setup:

- Confluent Platform Enterprise with mTLS authentication and ACL authorization (env=mtls-acl)
- Confluent Platform Enterprise with SASL Plain authentication and RBAC authorization (env=sasl-rbac)
- Confluent Platform Enterprise with SASL SCRAM SHA-512 authentication and RBAC authorization (env=scram-rbac)

## Requirements

The following programs are required to exist on the host machine to use this project:

- Docker
- Docker-Compose
- OpenSSL

## Usage

Before launching any environments, you will need to create the Kafka client docker image first which will be used to execute scripts for setup but also can be used for operational functions like viewing topics, ACLs, and consumer groups. To create the Kafka client docker image execute the "create-client.sh" script.

```
    ./create-client.sh
```

In addition, you will need to create the Kafka Conenct vault docker image because some of the environments use Hashicorp Vault for storing secrets. To create the docker image, execute the "create-kafka-conenct-vault.sh" script.

```
    ./create-kafka-connect-vault.sh
```

Once the docker images are created you can now launch an environment. To launch a Confluent Platform environment, make sure docker is running and execute the script "setup.sh" in the base of this project, passing in the env name as an argument.

```
    ./setup.sh sasl-rbac
```

This will clear out volumes used by this environment in the "volumes" folder and recreate the certificates (if any) used by this environment in the "certs" folder. Then it will launch the zookeeper servers, brokers and any other components in Docker.

To tear down an environment execute the script "teardown.sh" in the base of this project, passing in the env name as an argument.

```
    ./teardown.sh sasl-rbac
```

This will stop all the runnning containers for the environment in Docker and clear out the "volumes" folder when finished.

## Environment: mTLS authentication and ACL authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one schema registry server and one Kafka Connect worker. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). The authentication method being used in mTLS, meaning that the principal is coming from the CN of the client certificate. There is no authentication on the schema registry server and Kafka Connect REST APIs. Authorization is performed through Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the schema registry server and Kafka Connect worker. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL Plain authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one schema registry server and one Kafka Connect worker. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The schema registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for schema registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in schema registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses plain authentication to the brokers, so the broker clients need to have usernames/passwords in the JAAS config for the broker listener. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL SCRAM SHA-512 authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one schema registry server and one Kafka Connect worker. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The schema registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for schema registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in schema registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses SCRAM SHA-512 for authentication to brokers, which means the usernames and passwords for the broker clients (and all components) are stored in Zookeeper as Kafka configs for "user" data in Zookeeper. Because the Kafka user is a SCRAM user as well, there is a jumphost called "scram-client" that is used to deploy SRAM user data to Zookeeper before the brokers are brought up. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Usage for Confluent Professional Services (CPS) Engagements

I have found it is useful to have a local enviornment running with the configuration settings of the client when participating in Confluent Professional Services (CPS) engagements. With a working local environment, it's easy to diagnose misconfigurations in the client's environment. To do this I grab the properties for the CP component in my local environment by following the instructions below and then compare those properties to the client's properties.

First shell into the local component.

```
docker exec -it connect1 /bin/bash
```

Inside the shell run `ps -ef | grep java` and grab the properties filename from the output (it's last in the command). Then execute `sort <properties-filename>` to list the properties.

```
> ps -ef | grep java

appuser      191       1 15 14:52 ?        00:03:39 java -Xms256M -Xmx2G -server -XX:+UseG1GC -XX:GCTimeRatio=1 -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:MaxGCPauseMillis=10000 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -XX:MaxInlineLevel=15 -Djava.awt.headless=true -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dkafka.logs.dir=/var/log/kafka 
...
-Djavax.net.ssl.trustStore=/var/ssl/private/connect1.kafka_network.truststore.jks -Djavax.net.ssl.trustStorePassword=serverpassword -Djavax.net.ssl.keyStore=/var/ssl/private/connect1.kafka_network.keystore.jks -Djavax.net.ssl.keyStorePassword=serverpassword org.apache.kafka.connect.cli.ConnectDistributed /etc/kafka-connect/kafka-connect.properties

> sort /etc/kafka-connect/kafka-connect.properties

bootstrap.servers=lb:19092
config.providers.secret.class=io.confluent.connect.secretregistry.rbac.config.provider.InternalSecretConfigProvider
config.providers.secret.param.kafkastore.basic.auth.user.info=connect:connect-secret
config.providers.secret.param.kafkastore.bootstrap.servers=lb:19092
...
value.converter.schema.registry.url=https://schema1:8081
value.converter=io.confluent.connect.avro.AvroConverter
value.subject.name.strategy=io.confluent.kafka.serializers.subject.RecordNameStrategy
zookeeper.connect=zoo1:2181,zoo2:2182,zoo3:2183
```