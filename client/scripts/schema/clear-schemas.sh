#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

IN="$(curl -k -X GET $SCHEMA_URL/subjects | tr -d '[]"')"
echo "$IN"
subjects=$(echo $IN | tr "," "\n")
for subject in $subjects
do
    printf "deleting schema ${subject}\n"
    curl -k -X DELETE $SCHEMA_URL/subjects/${subject}
    printf "\n"
done