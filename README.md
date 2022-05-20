# confluent-toolkit

## Summary

This project is used to launch, test and teardown different Confluent Platform environments in docker. The following environments have configurations setup:

- Confluent Platform Enterprise with mTLS authentication and ACL authorization (env=mtls-acl)
- Confluent Platform Enterprise with Kerberos (GSSAPI) authentication and ACL authorization (env=gssapi-acl)
- Confluent Platform Enterprise with SASL Plain authentication and RBAC authorization (env=sasl-rbac)
- Confluent Platform Enterprise with SASL SCRAM SHA-512 authentication and RBAC authorization (env=scram-rbac)
- Confluent Platform Enterprise with SASL Kerberos (GSSAPI) authentication and RBAC authorization (env=gssapi-rbac)
- Confluent Platform Enterprise with Kraft using mTLS authentication and no authorization (env=kraft)
- Two Confluent Platform Enterprise Clusters using Cluster Linking to sync data between source and destination (env=cl)

## Requirements

The following programs are required to exist on the host machine to use this project:

- Docker
- Docker-Compose
- OpenSSL

## Usage

There are a few custom docker images that need to be created for use in the various environments. They are:

- Kafka Client (kafka-client): This is an `openjdk` image with Confluent Platform community installed and several operational scripts. This image is used for running setup scripts and as a way to view things inside of Kafka without using Control Center.
- Kafka Connect Vault (kafka-connect-vault): This is a `cp-server-connect` image with the `jcustenborder/kafka-config-provider-vault` library installed. This library is the Hashicorp Vault secrets provider which is used to pull secrets for connectors similar to the Kafka Connect Secret Registry, but instead against Hashicorp Vault. Kafka Connect workers need this library in their classpath before startup. That's why an image needed to be created instead of just addng the library to the plugin path.
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

## Kafka Client

Every environment should have user principals setup for all the components (Zookeeper, Kafka Brokers, Schema Registry, Kafka Connect, KsqlDB, Control Center) as well as these additional users:

- Datagen Source Connector (datagen): Has permission to write to a single topic ("env.app.person")
- JDBC Sink Connector (jdbcsink): Has permission to read from a single topic ("env.app.person")
- Admin (admin): Is either a super user or a system administrator in Kafka cluster, Schema Registry cluster, Kafka Conenct cluster and KsqlDB cluster
- Client (client): A normal user that has no access in any of the clusters

A `client` container is launched in every environment. On startup, this container executes scripts to create ACLs or RBAC role bindings for the Schema Registry, Kafka Connect, KsqlDB, and Control Center users. This container also has a mount that includes several useful operational scripts. To execute these scripts shell into the `client` container.

```
    docker exec -it client /bin/bash
```

The scripts are mounted under the `/scripts` directory inside the container and there are several sub-folders underneath this folder.

- `clusterlink`: scripts pertaining to the Cluster Linking feature of Confluent Platform (creating cluster links, removing cluster links, creating mirror topics, promoting mirror topics, etc)
- `config`: folder containing Kafka broker connection property files for the different environments and users
- `connect`: scripts for creating and deleting Kafka Connect connectors (like Datagen Source Connector and JDBC Sink Connector)
- `ops`: scripts for performing routine Kafka operations such as creating topics, viewing consumers, resetting consumer offsets, etc
- `setup`: scripts for setting up permissions for users, registering clusters, etc

When executing a script, the first argument always relates to the properties file being used from the `config` folder. For example, when executing the `list-topics.sh` script in the `ops` folder for the `confluent-platform-gssapi-rbac.yml` you would use the `gssapi.config` in `config` as shown below.

```
    cd /scripts/ops
    ./list-topics.sh gssapi
```

The `gssapi` configuration uses the `admin` user. There's also a `gssapi_client` user that will use the `client` user. These are the configurations currently available to run scripts:

- `gssapi`: Admin user for any of the Kerberos (GSSAPI) authentication environments
- `gssapi_client`: Client user for any of the Kerberos (GSSAPI) authentication environments
- `mtls`: Admin user for any of the mTLS authentication environments
- `sasl`: Admin user for any of the SASL Plain authentication environments
- `sasl_client`: Client user for any of the SASL Plain authentication environments
- `scram`: Admin user for any of the SASL Scram authentication environments
- `token`: Admin user for any of the RBAC environments that have OAuth Token authentication enabled (`sasl-rbac`, `gssapi-rbac`, `scram-rbac`)

You will notice that each of these has a `local` version, such as `gssapi_client_local`. These configs are for running the scripts outside of Docker where this repo is installed.

```
    cd /Users/myuser/repos/objectpartners/confluent-platform-toolkit/client/scripts/ops
    ./list-topics.sh gssapi_local
```

## Control Center

Control Center is enabled in each environment and can accessed from a browser at the URL `https://localhost:9021`. When you are prompted for a username and password (either by Basic Auth popup or a login screen), enter `admin` for username and `admin-secret` for password. This is the administrator user that should be able to access and modify any feature in Control Center. You can login with other users as well, but features will be hidden depending on that user's permissions.

## Environment: mTLS authentication and ACL authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). The authentication method being used in mTLS, meaning that the principal is coming from the CN of the client certificate. There is no authentication on the Schema Registry server and Kafka Connect REST APIs. Authorization is performed through Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the Schema Registry server and Kafka Connect worker. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL Kerberos (GSSAPI) authentication and ACL authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. Additionally, a KDC Server is running that handles all Kerberos authentication. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). There is no authentication on the Schema Registry server and Kafka Connect REST APIs. Authorization is performed through Kafka ACLs for reading/writing/creating topics and using consumer groups. There are examples of these ACLs for the Schema Registry server and Kafka Connect worker. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the ACLs needed for their principals.

This environment uses Kerberos (GSSAPI) for authentication to brokers, which means that principals and their passwords must be set in the kdc-server. Authentication to Zookeeper is Kerberos authentication. If the `./kerberos/init-script.sh` script is updated with new principals the `kdc-server` image will need to be rebuilt. This can be done by running `docker-compose -f confluent-platform-gssapi-acl.yml build`.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the 
Datagen Connector.

## Environment: SASL Plain authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses plain authentication to the brokers, so the broker clients need to have usernames/passwords in the JAAS config for the broker listener. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL SCRAM SHA-512 authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals.

This environment uses SCRAM SHA-512 for authentication to brokers, which means the usernames and passwords for the broker clients (and all components) are stored in Zookeeper as Kafka configs for "user" data in Zookeeper. Because the Kafka user is a SCRAM user as well, there is a jumphost called "scram-client" that is used to deploy SRAM user data to Zookeeper before the brokers are brought up. Authentication to Zookeeper is Digest Authentication.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: SASL Kerberos (GSSAPI) authentication and RBAC authorization

This environment is a three broker, three zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between zookeeper servers, brokers and between components and brokers (so basically everywhere). MDS is running on the brokers and RBAC is enabled for authorization against an Open LDAP server. The Schema Registry server and Kafka Connect worker are authenticating against the OAuth token listener on the brokers. The REST API for Schema Registry and Kafka Connect have basic authentication enabled and RBAC is enabled on both. This means prinicpals will need to have role bindings created to access subjects in Schema Registry and to create connectors in Kafka Connect. Principals will also need role bindings to read/write/create topics and consume using consumer groups. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default and demonstrate the role bindings needed for their principals. You will notice that a transformation taks place between the Kerberos principal to make it match the AD user common name. For more details on how this works see the section "Kerberos Principals and RBAC" below.

This environment uses Kerberos (GSSAPI) for authentication to brokers, which means that principals and their passwords must be set in the kdc-server. Authentication to Zookeeper is Kerberos authentication. If the `./kerberos/init-script.sh` script is updated with new principals the `kdc-server` image will need to be rebuilt. This can be done by running `docker-compose -f confluent-platform-gssapi-rbac.yml build`.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: Kraft with mTLS authentication and no authorization

This environment is a three broker, zero zookeeper cluster of Confluent Platform Enterprise with one Schema Registry server, one Kafka Connect worker, one KSQL node, and one Control Center instance. SSL is enabled for all communication between brokers and between components and brokers (so basically everywhere). The brokers are using [KRaft](https://github.com/apache/kafka/tree/trunk/raft) instead of Zookeeper for storing cluster metadata. KRaft is not in a production status as of when this environment was created on 5/17/22. KRaft is missing support for many security features like ACL and RBAC authorization, as well as Self Balancing and Cluster Linking. When brokers using KRaft are started, cluster ID needs to be specified in the broker properties, the broker storage needs to be formatted with the cluster ID, and the check for the "zookeeper.connect" property needs to be removed. This is all handled by an initialization script (`kraft/initialize-broker.sh`) that runs before the brokers startup.

The authentication method being used in mTLS, meaning that the principal is coming from the CN of the client certificate. There is basic authentication on the Schema Registry server and Kafka Connect REST APIs. There is no authorization setup because it isn't supported by KRaft. Two connectors, Datagen Connector and JDBC Sink Connector, are setup by default.

If you want to verify your environment is working correctly, you can open up a connection to the Postgres server on "localhost:5432" running in Docker and verify that there is a table created in the `public` schema called `person` which should be populated with records. This table is populated by the JDBC Sink Connector from a topic populated by the Datagen Connector.

## Environment: Two Clusters using Cluster Linking to sync data between source and destination

This environment has two three broker, three zookeeper Confluent Platform Enterprise clusters. The source cluster is CP 6.2.0 and the destination cluster is CP 7.1.1. The authentication method being used in both clusters is mTLS, meaning that the principal is coming from the CN of the client certificate. A Cluster Link is setup on the destination cluster called `test` and three topics (`test1`, `test2, `test3`) in the source cluster on startup. Also, three [Mirror Topics](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/mirror-topics-cp.html) are created on the `test` Cluster Link that sync from each of the three topics in the source cluster. Also, two Kafka configurations are setup for accessing data in the source cluster (called `src`) and the destination cluster (called `dst`). These can be used when executing the client scripts to list topics and describe consumers (ex: `./list-topics.sh src` or `./list-mirror-topics.sh dst`).

[Cluster Linking](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html) is a feature of Confluent Platform 7.x used for sinking data between Kafka clusters. Unlike [Confluent Replicator](https://docs.confluent.io/platform/current/control-center/replicators.html) and its predecessor [MirrorMaker](https://docs.confluent.io/4.0.0/multi-dc/mirrormaker.html), Cluster Linking provides byte-per-byte replication, meaning the partitions will be copied over exactly how they appear in the source cluster. In addition, topic configs, consumer offsets and ACLs can be synced using Cluster Linked making it ideal for migrations. Another popular use case is for pushing data from on-premise Confluent Platform to Confluent Cloud. Cluster Linking can be setup to run from the source cluster (push) or the destination cluster (pull) as long at the cluster it is setup in is Confluent Platform 7.x+. Cluster Linking is also much more efficient than Confluent Replicator because it uses Replica Fetchers, the mechanism brokers use to replicate data to one another. Cluster Linking has a specific Replica Fetcher called the Cluster Link Replica Fetcher.

Cluster Linking relies on Cluster Links and read-only [Mirror Topics](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/mirror-topics-cp.html) for syncing data between two clusters. The Cluster Link has the other cluster's connect information in its configuration which is stored in Zookeeper at `/config/cluster-links/<cluster-link-id>`. To see this information, load up the `cl` environment, shell into the `client` container.

```
./setup.sh cl
docker exec -it client /bin/bash
```

Then run the script `zk-shell.sh dst` inside the client container.

```
$ cd /scripts/ops
$ ./zk-shell.sh dst
```

Inside the Zookeeper shell execute the command `` as shown below.

```
> ls /config/cluster-links

[64179a02-52a6-4ed5-8f2a-b8f2851a454e]

> get /config/cluster-links/64179a02-52a6-4ed5-8f2a-b8f2851a454e
```

You will see something like the data below.

```
{
  "version": 1,
  "config": {
    "consumer.offset.group.filters": "{\"groupFilters\": [{\"name\": \"*\",\"patternType\": \"LITERAL\",\"filterType\": \"INCLUDE\"}]}",
    "acl.filters": "{\"aclFilters\": [{\"resourceFilter\": {\"resourceType\": \"any\",\"patternType\": \"any\"},\"accessFilter\": {\"operation\": \"any\",\"permissionType\": \"any\"}}]}",
    "auto.create.mirror.topics.filters": "{\"topicFilters\": [{\"name\": \"_\",\"patternType\": \"PREFIXED\",\"filterType\": \"EXCLUDE\"},{\"name\": \"app1\",\"patternType\": \"PREFIXED\",\"filterType\": \"INCLUDE\"}]}",
    "auto.create.mirror.topics.enable": "true",
    "consumer.offset.sync.ms": "15000",
    "local.listener.name": "INTERNAL",
    "ssl.keystore.location": "/var/ssl/private/kafka1.mycompany.com.keystore.jks",
    "bootstrap.servers": "lb:29092",
    "config.providers.clusterlink.param.encrypted.secret.ssl.truststore.password": "encryptedPassword:fJv2kB1ZFdXHmsvZtPS9eA==,keyLength:128,cipherAlgorithm:AES/CBC/PKCS5Padding,initializationVector:Vc0xnbzOWQplWBh5dk5QLw==,keyFactoryAlgorithm:PBKDF2WithHmacSHA512,passwordLength:14,salt:upuwR9DWzcAvFw/3w3uXaelJoaAfMi5I6YYZMZWaGu1nVO6AP19C6zqJFDCj5OAPaZK7hAjJ1z/rI5EL2Jw3dBsF2HC2KsMEwVcim3SruS6C8xN8iH0s/XmMPDfPCOHRAkdENVcLBu+Uz7pqF1CywytnQTVhIrnI/kr2j1a+r8GEa2Ttk3OLjOUwEbGs7uvPwabsVMxLoshdwreLKt6+7rquxNwcqdMDxYxKWHeodCu7gJSnI7RkMu9mjFHJFtjLZnk45cUt1pSgypZKRC63RdfihIvZg7NdlJKU/Ewmn8pDc4aYEYi0yT8W3iFKbUO/ceLgrhkmlPxzYPqunZ6n3w==,iterations:4096",
    "consumer.offset.sync.enable": "true",
    "acl.sync.enable": "false",
    "security.protocol": "SSL",
    "ssl.truststore.location": "/var/ssl/private/kafka1.mycompany.com.truststore.jks",
    "config.providers.clusterlink.param.encrypted.secret.": "encryptedPassword:hDyX6SoGv8WRSbFIYHv9Hg==,keyLength:128,cipherAlgorithm:AES/CBC/PKCS5Padding,initializationVector:2oTpbZRLl59hTQiYR9BsFQ==,keyFactoryAlgorithm:PBKDF2WithHmacSHA512,passwordLength:14,salt:zI1ZHp3Nn7Jm/oYhXOcfaIN283g2t82BIkGpHzdqT9tzugF+c1Onr9oW3SleUkJBusBhikM38M2ytJ164J99ShwpnZ+mThvMJMumwXpVGLHSbW99S/03UaCgnnbx1dfbptKf3rVW2+PiRNOxGX0/iwjQqyS8v8uYOGF/D1/9TlQOqdPVTiEXoZNryVsjii0GBDEAbQiUtICXi6JzqIWYRfv7kK8JM3Wp1KdmbE7+Xl0Qh4NzLmhWomXWCNT6Fz/weiea0f/vFqOwtFxMx4MmpB68+BzgKWrDyRUy/vm/BW7JmCvFhn8Uc+r4CvsrhceBUpeQ+OcZKve0AB4UZ3YEfg==,iterations:4096",
    "ssl.keystore.password": "${clusterlink:ssl.keystore.password}",
    "topic.config.sync.ms": "5000",
    "config.providers.clusterlink.param.encrypted.secret.ssl.keystore.password": "encryptedPassword:tYJafffh2BRpnVedNpktrA==,keyLength:128,cipherAlgorithm:AES/CBC/PKCS5Padding,initializationVector:9NNcpf55bvn44fq2DrLhYg==,keyFactoryAlgorithm:PBKDF2WithHmacSHA512,passwordLength:14,salt:npd2dp0ozY+FSrNB328EG/qEO5Mc7ZwIZg4XU1KTABx/aef0yhdSCNLak5fkMMs2arU7uPeps65fluto30cYpEAj4GOXFiO/1FjaJ1jl0s4Dxob3Qs9vxRerVQQ3qco/EkmNhEhswPM18+AhGU/7lAUbv5li/ffCRXHErB02/MzlEwlyqOsk73OWjG1bFpZpUzi3XHms85V50KJpgps+G7fpLXzTq9uOE4qDjuNZjMkDeaqaklRlqSZ6GVnOT6C6PqRryxdT5Nk47ooiGsIlAdrO1t2CxpRzVSTh6GBHr3rHGVAnJ3wb43sEmMMhtghhAEITRd4aSJ8O1aJPr8CuXQ==,iterations:4096",
    "ssl.truststore.password": "${clusterlink:ssl.truststore.password}",
    "cluster.link.paused": "false"
  }
}
```

The `cl` environment is setup with a source cluster of CP 6.2.0 and a destination cluster of CP 7.1.1. The cluster link is setup in the destination cluster so you use the profile `dst` to look at Mirror Topics and the Cluster Link as shown below.

```
$ cd /scripts/clusterlink
$ ./list-mirror-topics.sh dst

Topic: test2	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test2	State: ACTIVE	StateTime: 2022-05-20 23:12:02
	Partition: 0	State: ACTIVE	DestLogEndOffset: 194	LastFetchSourceHighWatermark: 194	Lag: 0	TimeSinceLastFetchMs: 99792
	Partition: 1	State: ACTIVE	DestLogEndOffset: 190	LastFetchSourceHighWatermark: 190	Lag: 0	TimeSinceLastFetchMs: 98934
	Partition: 2	State: ACTIVE	DestLogEndOffset: 205	LastFetchSourceHighWatermark: 205	Lag: 0	TimeSinceLastFetchMs: 101146
	Partition: 3	State: ACTIVE	DestLogEndOffset: 205	LastFetchSourceHighWatermark: 205	Lag: 0	TimeSinceLastFetchMs: 99424
	Partition: 4	State: ACTIVE	DestLogEndOffset: 206	LastFetchSourceHighWatermark: 206	Lag: 0	TimeSinceLastFetchMs: 98602
Topic: test3	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test3	State: ACTIVE	StateTime: 2022-05-20 23:12:06
	Partition: 0	State: ACTIVE	DestLogEndOffset: 190	LastFetchSourceHighWatermark: 190	Lag: 0	TimeSinceLastFetchMs: 80095
	Partition: 1	State: ACTIVE	DestLogEndOffset: 187	LastFetchSourceHighWatermark: 187	Lag: 0	TimeSinceLastFetchMs: 79106
	Partition: 2	State: ACTIVE	DestLogEndOffset: 206	LastFetchSourceHighWatermark: 206	Lag: 0	TimeSinceLastFetchMs: 82690
	Partition: 3	State: ACTIVE	DestLogEndOffset: 207	LastFetchSourceHighWatermark: 207	Lag: 0	TimeSinceLastFetchMs: 79539
	Partition: 4	State: ACTIVE	DestLogEndOffset: 210	LastFetchSourceHighWatermark: 210	Lag: 0	TimeSinceLastFetchMs: 78682
Topic: test1	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test1	State: ACTIVE	StateTime: 2022-05-20 23:11:59
	Partition: 0	State: ACTIVE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 118571
	Partition: 1	State: ACTIVE	DestLogEndOffset: 180	LastFetchSourceHighWatermark: 180	Lag: 0	TimeSinceLastFetchMs: 119636
	Partition: 2	State: ACTIVE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 119967
	Partition: 3	State: ACTIVE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 118548
	Partition: 4	State: ACTIVE	DestLogEndOffset: 196	LastFetchSourceHighWatermark: 196	Lag: 0	TimeSinceLastFetchMs: 119221

$ ./list-cluster-links.sh dst

Link name: 'test', link ID: '64179a02-52a6-4ed5-8f2a-b8f2851a454e', remote cluster ID: 'UFbunQ0fTuWhMeV9C3ffcQ', local cluster ID: 'CgjKHeSdQX-v1Tz37fXqyg', remote cluster available: 'true', topics: [test2, test3, test1]
```

The environment is setup with one cluster link named `test` and three topics (`test1`, `test2, `test3`). The topics should appear as regular topics in the source cluster if you execute these commands.

```
$ cd /scripts/ops
$ ./list-topics.sh src

__consumer_offsets
_confluent-license
_confluent-metrics
_confluent-telemetry-metrics
_confluent_balancer_api_state
_confluent_balancer_broker_samples
_confluent_balancer_partition_samples
test1
test2
test3
```

The environment also produces and consumes messages to all three topics in the source cluster on startup. To verify Cluster Linking is working correctly, describe the consumer `test` in both environments and verify they match and that the offsets for the partitions are not zero.

```
$ cd /scripts/ops
$ ./describe-consumer.sh src test

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
test            test1           3          208             208             0               -               -               -
test            test2           4          206             206             0               -               -               -
test            test3           0          190             190             0               -               -               -
test            test2           1          190             190             0               -               -               -
test            test3           2          206             206             0               -               -               -
test            test1           0          208             208             0               -               -               -
test            test1           4          196             196             0               -               -               -
test            test1           1          180             180             0               -               -               -
test            test3           3          207             207             0               -               -               -
test            test2           2          205             205             0               -               -               -
test            test2           0          194             194             0               -               -               -
test            test2           3          205             205             0               -               -               -
test            test1           2          208             208             0               -               -               -
test            test3           1          187             187             0               -               -               -
test            test3           4          210             210             0               -               -               -

$ ./describe-consumer.sh dst test

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
test            test1           3          208             208             0               -               -               -
test            test2           4          206             206             0               -               -               -
test            test3           0          190             190             0               -               -               -
test            test2           1          190             190             0               -               -               -
test            test3           2          206             206             0               -               -               -
test            test1           0          208             208             0               -               -               -
test            test1           4          196             196             0               -               -               -
test            test1           1          180             180             0               -               -               -
test            test3           3          207             207             0               -               -               -
test            test2           2          205             205             0               -               -               -
test            test2           0          194             194             0               -               -               -
test            test2           3          205             205             0               -               -               -
test            test1           2          208             208             0               -               -               -
test            test3           1          187             187             0               -               -               -
test            test3           4          210             210             0               -               -               -
```

Cluster Linking will change the Cluster Link status and Mirror Topic statuses from `ACTIVE` to `SOURCE_UNAVAILABLE` when the source cluster can't be reached. The time it takes to recognize that the source cluster is unreachable and stop the Cluster Link Replica Fetcher is determined by the Cluster Link properties `availability.check.ms` and `availability.check.consecutive.failure.threshold` (see [this](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/configs.html) documentation for defaults. To test this in the `cl` environment, stop the containers `kafka1`, `kafka2`, and `kafka3` and wait approximately five minutes.

```
docker stop kafka1 kafka2 kafka3
docker exec -it client /bin/bash
```

You can see the statuses of the Mirror Topics by executing this script inside the `client` shell.

```
$ cd /scripts/clusterlink
$ ./list-mirror-links.sh dst

Topic: test2	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test2	State: SOURCE_UNAVAILABLE	StateTime: 2022-05-20 23:26:53
	Partition: 0	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 194	LastFetchSourceHighWatermark: 194	Lag: 0	TimeSinceLastFetchMs: 610662
	Partition: 1	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 190	LastFetchSourceHighWatermark: 190	Lag: 0	TimeSinceLastFetchMs: 610303
	Partition: 2	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 205	LastFetchSourceHighWatermark: 205	Lag: 0	TimeSinceLastFetchMs: 610443
	Partition: 3	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 205	LastFetchSourceHighWatermark: 205	Lag: 0	TimeSinceLastFetchMs: 610664
	Partition: 4	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 206	LastFetchSourceHighWatermark: 206	Lag: 0	TimeSinceLastFetchMs: 610304
Topic: test3	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test3	State: SOURCE_UNAVAILABLE	StateTime: 2022-05-20 23:26:53
	Partition: 0	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 190	LastFetchSourceHighWatermark: 190	Lag: 0	TimeSinceLastFetchMs: 610664
	Partition: 1	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 187	LastFetchSourceHighWatermark: 187	Lag: 0	TimeSinceLastFetchMs: 610304
	Partition: 2	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 206	LastFetchSourceHighWatermark: -1	Lag: -207	TimeSinceLastFetchMs: 1653089228052
	Partition: 3	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 207	LastFetchSourceHighWatermark: 207	Lag: 0	TimeSinceLastFetchMs: 610664
	Partition: 4	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 210	LastFetchSourceHighWatermark: 210	Lag: 0	TimeSinceLastFetchMs: 610304
Topic: test1	LinkName: test	LinkId: 64179a02-52a6-4ed5-8f2a-b8f2851a454e	MirrorTopic: test1	State: SOURCE_UNAVAILABLE	StateTime: 2022-05-20 23:26:53
	Partition: 0	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 610664
	Partition: 1	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 180	LastFetchSourceHighWatermark: 180	Lag: 0	TimeSinceLastFetchMs: 610834
	Partition: 2	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 610444
	Partition: 3	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 208	LastFetchSourceHighWatermark: 208	Lag: 0	TimeSinceLastFetchMs: 610664
	Partition: 4	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 196	LastFetchSourceHighWatermark: 196	Lag: 0	TimeSinceLastFetchMs: 610834
```

Once the source cluster brokers are started again, you should should see the Mirror Topics change from status `SOURCE_UNAVAILABLE` to `ACTIVE` shortly. In addition, you will see some of the lags on the Mirror Topic partitions set to negative numbers. They will stay this way even after the Mirror Topics return to `ACTIVE`, until the Cluster Link Replica Fetcher loads more data from the source partition into this topic partition.

The Cluster Link can be paused by changing the `cluster.link.paused` setting in `/scripts/config/cl.config` to `true` and updating the Cluster Link.

```
$ cd /scripts/clusterlink
./update-cluster-link.sh dst test
```

This will change the status of the Mirror Topics to `PAUSED` and all syncing of messages, consumer offsets, and ACLs will be stopped until the Cluster Link is unpaused.

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
