#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Subject not specified" ; exit 1; }
SUBJECT=$2

curl -k -X POST -H "Content-Type:application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\": \"string\"}"}' $SCHEMA_URL/subjects/$SUBJECT/versions