# confluent-toolkit

## Summary

This project is used to launch, test and teardown different Confluent Platform environments in docker. The following environments have configurations setup:

- Confluent Platform Enterprise with mTLS authentication and ACL authorization (env=mtls-acl)
- Confluent Platform Enterprise with SASL Plain authentication and RBAC authorization (env=sasl-rbac)

## Requirements

The following programs are required to exist on the host machine to use this project:

- Docker
- Docker-Compose
- OpenSSL

## Usage

Before launching any environments, you will need to create the Kafka client docker image first which will be used to execute scripts for setup but also can be used for 
operational functions like viewing topics, ACLs, and consumer groups. To create the Kafka client docker image execute the "create-client.sh" script.

```
    ./create-client.sh
```

Once the Kafka client docker image is created you can now launch an environment. Tolaunch a Confluent Platform environment, make sure docker is running and execute the 
script "setup.sh" in the base of this project, passing in the env name as an argument.

```
    ./setup.sh sasl-rbac
```

This will clear out volumes used by this environment in the "volumes" folder and recreate the certificates (if any) used by this environment in the "certs" folder. Then it will 
launch the zookeeper servers, brokers and any other components in Docker.

To tear down an environment execute the script "teardown.sh" in the base of this project, passing in the env name as an argument.

```
    ./teardown.sh sasl-rbac
```

This will stop all the runnning containers for the environment in Docker and clear out the "volumes" folder when finished.

## Environment: mTLS authentication and ACL authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one schema registry server and one Kafka Connect worker. SSL is enabled for all
communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). The authentication method being used in mTLS, meaning that the
principal is coming from the CN of the client certificate. There is no authentication on the schema registry server and Kafka Connect REST APIs. Authorization is performed through
Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the schema registry server and Kafka Connect worker. Two connectors, 
Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a 
table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the 
Datagen Connector.

## Environment: SASL Plain authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one schema registry server and one Kafka Connect worker. SSL is enabled for all
communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization 
against an Open LDAP server. The schema registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for schema registry 
and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in schema registry 
and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector 
and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a 
table created in the "public" schema called "person" which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the 
Datagen Connector.