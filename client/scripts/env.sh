#!/bin/bash

CONFLUENT_LOCAL_HOME="~/programs/confluent-7.0.1"

if [[ $PATH != *"$CONFLUENT_LOCAL_HOME"* ]]; then
  PATH=$PATH:$CONFLUENT_LOCAL_HOME/bin
  export PATH
fi

# env variables for cluster linking "destination" cluster
dst() {
    echo "Setting \"dst\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="lb:29096"
    export KAFKA_CONFIG="/scripts/config/dst.config"
    export SRC_BROKER_URL="lb:29092"
    export SRC_KAFKA_CONFIG="/scripts/config/src.config"
    export CL_CONFIG="/scripts/config/cl.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo4:2184"
    export ZOO2_URL="zoo5:2185"
    export ZOO3_URL="zoo6:2186"
    export SCHEMA_URL="https://schema2:8082"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

dst_local() {
    echo "Setting \"dst_local\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="localhost:9096"
    export KAFKA_CONFIG="../config/dst_local.config"
    export SRC_BROKER_URL="localhost:9092"
    export SRC_KAFKA_CONFIG="../config/src_local.config"
    export CL_CONFIG="/scripts/config/cl_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2184"
    export ZOO2_URL="localhost:2185"
    export ZOO3_URL="localhost:2186"
    export SCHEMA_URL="https://localhost:8082"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

# env variables for cluster linking "source" cluster
src() {
    echo "Setting \"src\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="lb:29092"
    export KAFKA_CONFIG="/scripts/config/src.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

src_local() {
    echo "Setting \"src_local\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="localhost:9092"
    export KAFKA_CONFIG="../config/src_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2181"
    export ZOO2_URL="localhost:2182"
    export ZOO3_URL="localhost:2183"
    export SCHEMA_URL="https://localhost:8081"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

mtls() {
    echo "Setting \"mtls\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="lb:29092"
    export KAFKA_CONFIG="/scripts/config/mtls.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export MDS_URL="https://kafka1:8091"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

mtls_local() {
    echo "Setting \"mtls_local\" environment variables"
    export SSL="true"
    export RBAC="false"
    export SASL="false"
    export BROKER_URL="localhost:9092"
    export KAFKA_CONFIG="../config/mtls_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2181"
    export ZOO2_URL="localhost:2182"
    export ZOO3_URL="localhost:2183"
    export SCHEMA_URL="https://localhost:8081"
    export MDS_URL="https://localhost:8091"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

sasl() {
    echo "Setting \"sasl\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="lb:29092"
    export KAFKA_CONFIG="/scripts/config/sasl.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export MDS_URL="https://kafka1:8091"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

sasl_local() {
    echo "Setting \"sasl_local\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="localhost:9092"
    export KAFKA_CONFIG="../config/sasl_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2181"
    export ZOO2_URL="localhost:2182"
    export ZOO3_URL="localhost:2183"
    export SCHEMA_URL="https://localhost:8081"
    export MDS_URL="https://localhost:8091"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

sasl_client() {
    echo "Setting \"sasl_client\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="lb:29092"
    export KAFKA_CONFIG="/scripts/config/sasl_client.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export MDS_URL="https://kafka1:8091"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

sasl_client_local() {
    echo "Setting \"sasl_client_local\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="localhost:9092"
    export KAFKA_CONFIG="../config/sasl_client_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2181"
    export ZOO2_URL="localhost:2182"
    export ZOO3_URL="localhost:2183"
    export SCHEMA_URL="https://localhost:8081"
    export MDS_URL="https://localhost:8091"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

scram() {
    echo "Setting \"scram\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="lb:29092"
    export KAFKA_CONFIG="/scripts/config/scram.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export MDS_URL="https://kafka1:8091"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

scram_local() {
    echo "Setting \"scram_local\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="localhost:9092"
    export KAFKA_CONFIG="../config/scram_local.config"
    export KEYSTORE_DIR="../../../certs"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="localhost:2181"
    export ZOO2_URL="localhost:2182"
    export ZOO3_URL="localhost:2183"
    export SCHEMA_URL="https://localhost:8081"
    export MDS_URL="https://localhost:8091"
    export KAFKA_CONNECT_URL="https://localhost:8083"
}

token() {
    echo "Setting \"token\" environment variables"
    export SSL="true"
    export RBAC="true"
    export SASL="true"
    export BROKER_URL="lb:19092"
    export KAFKA_CONFIG="/scripts/config/token.config"
    export KEYSTORE_DIR="/var/ssl/private"
    export KEYSTORE_PASSWORD="serverpassword"
    export ZOO1_URL="zoo1:2181"
    export ZOO2_URL="zoo2:2182"
    export ZOO3_URL="zoo3:2183"
    export SCHEMA_URL="https://schema1:8081"
    export MDS_URL="https://kafka1:8091"
    export KAFKA_CONNECT_URL="https://connect1:8083"
}

# env from user input
[[ -z "$1" ]] && { echo "Environment not specified" ; exit 1; }
declare -a ENV=$1

# execute function for env
$ENV