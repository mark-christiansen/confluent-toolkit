#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Subject not specified" ; exit 1; }
SUBJECT=$2

# set basic auth username:secret if SASL enabled
BASIC_AUTH=""
if [[ $SASL == "true" ]]; then
  BASIC_AUTH="-u admin:admin-secret"
fi

#echo ""
#echo "Setting schemas for $SUBJECT"
#echo ""
#curl -k $BASIC_AUTH -X PUT --data '{"compatibility": "BACKWARD"}' $SCHEMA_URL/config/$SUBJECT 

echo ""
echo "Deleting schemas for $SUBJECT"
echo ""
curl -k $BASIC_AUTH -X DELETE $SCHEMA_URL/subjects/$SUBJECT?permanent=true

echo ""
echo "Schemas for $SUBJECT"
echo ""
curl -k $BASIC_AUTH -X GET $SCHEMA_URL/subjects/$SUBJECT/versions


POST_DATA=$(cat <<EOF
{
  "schema": "{\"type\": \"record\",\"name\": \"MyRecord\",\"namespace\": \"com.mycompany\",\"fields\": [{ \"name\": \"id\", \"type\": \"long\"}, {\"name\": \"name\", \"type\": [\"null\", \"string\"], \"default\": null}]}"
}
EOF
)

echo ""
echo "Creating first schema for $SUBJECT"
echo ""
SCHEMA_ID_1=$(curl -k $BASIC_AUTH -X POST -H "Content-Type:application/vnd.schemaregistry.v1+json" --data "$POST_DATA" $SCHEMA_URL/subjects/$SUBJECT/versions)
echo $SCHEMA_ID_1
SCHEMA_ID_1=$(echo "$SCHEMA_ID_1" | grep -oEi '[0-9_]*')

POST_DATA=$(cat <<EOF
{
  "schema": "{\"type\": \"record\",\"name\": \"MyRecord\",\"namespace\": \"com.mycompany\",\"fields\": [{ \"name\": \"id\", \"type\": \"long\"}, {\"name\": \"description\", \"type\": [\"null\", \"string\"], \"default\": null}, {\"name\": \"name\", \"type\": [\"null\", \"string\"], \"default\": null}]}"
}
EOF
)

echo ""
echo "Creating second schema for $SUBJECT"
echo ""
SCHEMA_ID_2=$(curl -k $BASIC_AUTH -X POST -H "Content-Type:application/vnd.schemaregistry.v1+json" --data "$POST_DATA" $SCHEMA_URL/subjects/$SUBJECT/versions)
echo $SCHEMA_ID_2
SCHEMA_ID_2=$(echo "$SCHEMA_ID_2" | grep -oEi '[0-9_]*')

echo ""
echo "Schema 1:"
curl -k $BASIC_AUTH -X GET $SCHEMA_URL/schemas/ids/$SCHEMA_ID_1
echo ""

echo "Schema 2:"
curl -k $BASIC_AUTH -X GET $SCHEMA_URL/schemas/ids/$SCHEMA_ID_2
echo ""