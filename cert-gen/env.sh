#!/bin/bash

# set the env (CA) and region (intermediate CA) domains
CA_DOMAIN="mycompany.com"
INT_DOMAIN="region.${CA_DOMAIN}"
PRIVATE_DOMAIN="kafka_network"

# certificate needed, brokers certificate should be based on hostname of the cerificate
#declare -a MACHINES=("ip-10-150-1-51.${PRIVATE_DOMAIN}" "ip-10-150-1-48.${PRIVATE_DOMAIN}" "ip-10-150-1-54.${PRIVATE_DOMAIN}" "ip-10-150-1-58.${PRIVATE_DOMAIN}" "ip-10-150-1-36.${PRIVATE_DOMAIN}" "broker-0.${INT_DOMAIN}" "broker-1.${INT_DOMAIN}" "broker-2.${INT_DOMAIN}" "broker-3.${INT_DOMAIN}" "broker-4.${INT_DOMAIN}" "schema-0.${INT_DOMAIN}" "schema-1.${INT_DOMAIN}" "ip-10-150-2-40.${PRIVATE_DOMAIN}" "ip-10-150-2-44.${PRIVATE_DOMAIN}" "ip-10-150-2-48.${PRIVATE_DOMAIN}" "ip-10-150-1-56.${PRIVATE_DOMAIN}")
declare -a MACHINES=(
	"zoo1.${PRIVATE_DOMAIN}" "zoo2.${PRIVATE_DOMAIN}" "zoo3.${PRIVATE_DOMAIN}" 
	"zoo4.${PRIVATE_DOMAIN}" "zoo5.${PRIVATE_DOMAIN}" "zoo6.${PRIVATE_DOMAIN}" 
	"kafka1.${PRIVATE_DOMAIN}" "kafka2.${PRIVATE_DOMAIN}" "kafka3.${PRIVATE_DOMAIN}"
	"kafka4.${PRIVATE_DOMAIN}" "kafka5.${PRIVATE_DOMAIN}" "kafka6.${PRIVATE_DOMAIN}"
	"schema1.${PRIVATE_DOMAIN}" "schema2.${PRIVATE_DOMAIN}" "schema3.${PRIVATE_DOMAIN}" 
	"connect1.${PRIVATE_DOMAIN}" "connect2.${PRIVATE_DOMAIN}" "connect3.${PRIVATE_DOMAIN}" 
	"ksql1.${PRIVATE_DOMAIN}" "kslq2.${PRIVATE_DOMAIN}" "ksql3.${PRIVATE_DOMAIN}" 
	"lb.${PRIVATE_DOMAIN}" "c3.${PRIVATE_DOMAIN}" "client.${PRIVATE_DOMAIN}"
	"datagen.${PRIVATE_DOMAIN}" "jdbcsink.${PRIVATE_DOMAIN}" "replicator.${PRIVATE_DOMAIN}")
declare -a PUBLIC_DNS=(
	"localhost" "localhost" "localhost"
	"localhost" "localhost" "localhost" 
	"localhost,lb,lb.${PRIVATE_DOMAIN}" "localhost,lb,lb.${PRIVATE_DOMAIN}" "localhost,lb,lb.${PRIVATE_DOMAIN}"
	"localhost,lb,lb.${PRIVATE_DOMAIN}" "localhost,lb,lb.${PRIVATE_DOMAIN}" "localhost,lb,lb.${PRIVATE_DOMAIN}" 
	"localhost" "localhost" "localhost" 
	"localhost" "localhost" "localhost" 
	"localhost" "localhost" "localhost" 
	"localhost" "localhost" "localhost"
	"localhost" "localhost" "localhost")
# location to create certificates
CERTS=../certs

# the password of the root authority certificate
CA_PASSWORD=capassword

# the password if the intermediate certificate
INTERMEDIATE_PASSWORD=intpassword

# the password of the broker certificate and the keystore
# keystore password and key password must be the same
BROKER_PASSWORD=serverpassword

## Make the CERTS directory and ensure that it wasn't removed above

if [ "${CERTS}" == "" ]; then
  echo "CERTS environment variable is missing"
  exit
fi
mkdir -p ${CERTS}