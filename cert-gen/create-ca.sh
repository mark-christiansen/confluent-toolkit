#!/bin/bash

BASE=$(dirname "$0")

cd ${BASE}

. ./env.sh

ca_password=${CA_PASSWORD}

#
# Subject should be adjusted for your location, with the CN record being the hostname.
#
COUNTRY=US
STATE=MN
CITY=MINNEAPOLIS
ORG=IDS
UNIT=IT

#
# the subject name for your certificate authority certificate
#
subject="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${CA_DOMAIN}"

key=ca.key
req=ca.csr
crt=ca.crt

echo ""
echo "======================="
echo "create root certificate"
echo "======================="
echo ""

printf "\n\ncreated CA key and CA csr\n=========================\n\n"
openssl req -newkey rsa:3072 -sha384 -passout pass:${ca_password} -keyout ${CERTS}/${key} -out ${CERTS}/${req} -subj ${subject} \
	-reqexts ext \
	-config <(cat ./openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:5"))
[ $? -eq 1 ] && echo "unable to create CA key and csr" && exit

printf "\n\nverify CA key\n=============\n\n"
openssl rsa -check -in ${CERTS}/${key} -passin pass:${ca_password} 
[ $? -eq 1 ] && echo "unable to verify CA key" && exit

printf "\n\nverify CA csr\n=============\n\n"
openssl req -text -noout -verify -in ${CERTS}/${req}
[ $? -eq 1 ] && echo "unable to verify CA csr" && exit

printf "\n\nself-sign CA csr\n================\n\n"
openssl x509 -req -in ${CERTS}/${req} -sha384 -days 3650 -passin pass:${ca_password} -signkey ${CERTS}/${key} -out ${CERTS}/${crt} \
	-extensions ext \
	-extfile <(cat ./openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:5"))
[ $? -eq 1 ] && echo "unable to self-sign CA csr" && exit

printf "\n\nverify CS crt\n=============\n\n"
openssl x509 -in ${CERTS}/${crt} -text -noout
[ $? -eq 1 ] && echo "unable to verify CA crt" && exit

printf "\n\n"
