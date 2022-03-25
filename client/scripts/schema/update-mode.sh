#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Mode (IMPORT, READONLY, READWRITE) not specified" ; exit 1; }
MODE=$2

curl -k -X PUT --data "{\"mode\":\"$MODE\"}" -H "Content-Type:application/vnd.schemaregistry.v1+json" $SCHEMA_URL/mode