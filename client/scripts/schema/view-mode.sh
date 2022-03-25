#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

curl -k -X GET $SCHEMA_URL/mode