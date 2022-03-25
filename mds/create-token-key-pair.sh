#!/bin/bash

echo "Deleting MDS token key and cert"
rm -f ../certs/token_key.pem
rm -f ../certs/token_crt.pem
echo "Creating MDS token key and cert"
openssl genrsa -out ../certs/token_key.pem 2048
openssl rsa -in ../certs/token_key.pem -outform PEM -pubout -out ../certs/token_crt.pem
echo "Created MDS token key and cert"