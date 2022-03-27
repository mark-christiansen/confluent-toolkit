#!/bin/bash

echo "Creating Scram user entities in Zookeeper"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

success=1
while [ $success -gt 0 ]; do
  echo "attempting to login"
  ../login.sh scram
  success="$?"
  echo $success
done