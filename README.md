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

There are a few custom docker images that need to be created for use in the various environments. They are:

- Kafka Client (kafka-client): This is an `openjdk` image with Confluent Platform community installed and several operational scripts. This image is used for running setup scripts and as a way to view things inside of Kafka without using Control Center.
- Kafka Connect Vault (kafka-connect-vault): This is a `cp-server-connect` image with the `jcustenborder/kafka-config-provider-vault` library installed. This library is the Hashicorp Vault secrets provider which is used to pull secrets for connectors similar to the Connect Secretys Registry, but instead against Hashicorp Vault.
- KDC Server (kdc-server): This is a `debian:jesse` image with `krb5-kdc` and `krb5-admin-server` installed which is used for storing and maintaining Kerberos secrets.

To build these images you can run the `docker-compose build` command against the Kerberos RBAC environment as shown below. This will not launch the environment, only build any custom images needed for these environments.

```
    docker-compose -f confluent-platform-gssapi-rbac.yml build
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

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server and one Kafka Connect worker. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). The authentication method being used in mTLS, meaning that the principal is coming from the CN of the client certificate. There is no authentication on the Schema Registry server and Kafka Connect REST APIs. Authorization is performed through Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the Schema Registry server and Kafka Connect worker. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL Kerberos (GSSAPI) authentication and ACL authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. Additionally, a KDC Server is running that handles all Kerberos authentication. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). There is no authentication on the Schema Registry server and Kafka Connect REST APIs. Authorization is performed through Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the Schema Registry server and Kafka Connect worker. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

This environment uses Kerberos (GSSAPI) for authentication to brokers, which means that principals and their passwords must be set in the kdc-server. Authentication to Zookeeper is Kerberos authentication. If the `./kerberos/init-script.sh` script is updated with new principals the `kdc-server` image will need to be rebuilt. This can be done by running `docker-compose -f confluent-platform-sasl-gssapi-acl.yml build`.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the 
Datagen Connector.

## Environment: SASL Plain authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses plain authentication to the brokers, so the broker clients need to have usernames/passwords in the JAAS config for the broker listener. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL SCRAM SHA-512 authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses SCRAM SHA-512 for authentication to brokers, which means the usernames and passwords for the broker clients (and all components) are stored in Zookeeper as Kafka configs for "user" data in Zookeeper. Because the Kafka user is a SCRAM user as well, there is a jumphost called "scram-client" that is used to deploy SRAM user data to Zookeeper before the brokers are brought up. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL Kerberos (GSSAPI) authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals. You will notice that a transformation taks place between the Kerberos principal to make it match the AD user common name. For more details on how this works see the section "Kerberos Principals and RBAC" below.

This environment uses Kerberos (GSSAPI) for authentication to brokers, which means that principals and their passwords must be set in the kdc-server. Authentication to Zookeeper is Kerberos authentication. If the `./kerberos/init-script.sh` script is updated with new principals the `kdc-server` image will need to be rebuilt. This can be done by running `docker-compose -f confluent-platform-sasl-gssapi-acl.yml build`.

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

## Kerberos Principals and RBAC

For RBAC to work properly, the principal from the Kerberos keytabs must match the broker setting for `ldap.user.name.attribute` which is setup in these environments as the AD user common name (cn). To do this, a property called `sasl.kerberos.principal.to.local.rules` is specified on the broker which transforms the incoming Kerberos principal into a value that will match the AD user common name (strips the realm and host info). The `sasl.kerberos.principal.to.local.rules` value is actually Kerberos "Auth-to-Local" rules syntax. In this syntax you can have multiple rules which are comma-delimited and each having a regex that can be used to indentify which principals the rule applies to and a sed expression to convert the principal to the desired string. For more on Kerberos "Auth-to-Local" rules see the documentation below.

https://community.cloudera.com/t5/Community-Articles/Auth-to-local-Rules-Syntax/ta-p/245316

To explain how the rules work, let's look at an example. Taking the incoming Kerberos principal as `my-app/server1.mycompany.com@MYCOMPANY.COM`, the realm is considered the part after `@`, or `MYCOMPANY.COM`. The principal is broken up into components delimited by `/`. In this example there are two components: `my-app` and `server1.mycompany.com`. The "Auth-to-Local" rules start with a string surrounded by square brackets that indicate which components to consider. The realm is `$0` and the first component is `$1`. The second component is `$2` and so on. For this example, let's say that `sasl.kerberos.principal.to.local.rules` is set to the value below.

```
RULE:[1:$1],RULE:[2,$2](.+\.mycompany\.com)s/\(.*\)\.mycompany\.com/\U\1svc/,DEFAULT
```

The first rule `[1:$1]` is only matched if the principal has one component, denoted by the first `1`. So the example principal we are looking at will be ignored. The second rule `[2,$2](.+\.mycompany\.com)s/\(.*\)\.mycompany\.com/\U\1svc/` expects two components as denoted by the first `2` in square brackets and the `$2` indicates that we will only be transforming the second component, which in this case is `server1.mycompany.com`. The regex `(.+\.mycompany\.com)` must find a match for this rule to work and it does in this case. To test this go to https://regexr.com/ and paste ".+\.mycompany\.com)" into the expression field. Then paste "server1.mycompany.com" into the large "text" field. You should see an indication on the screen that the string matches the regex. The rule's sed expression `s/\(.*\)\.mycompany\.com/\U\1svc/` is the part that performs the transform. In this case, `server1.mycompany.com` is transformed into the string `SERVER1SVC`. To test this run the command below.

```
echo "server1.mycompany.com" | sed 's/\(.*\)\.mycompany\.com/\U\1SVC/'
```

The `DEFAULT` rule would return `my-app` for the principal `my-app/server1.mycompany.com@MYCOMPANY.COM`, but in the rule string above wouldn't be reached because the second rule would match the Kerberos principal string first and return `SERVER1SVC`. If the Kerberos principal `my-app/server1.othercompany.com@MYCOMPANY.COM` is passed in, then the rule string would return `mp-app` as the default rule would be the only matching rule of the three.