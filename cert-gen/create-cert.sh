#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage: $0 hostname"
  exit
fi

BASE=$(dirname "$0")

cd ${BASE}

. ./env.sh

HOSTNAME=$1
PUBLIC_DNS=$2
shift

# TODO verify intermediate.crt, intermediate.key, ca.crt exists

CA_PW=${CA_PASSWORD}
IN_PW=${INTERMEDIATE_PASSWORD}
B_PW=${BROKER_PASSWORD}

#
# Subject should be adjusted for your location, with the CN record being the hostname.
#
COUNTRY=US
STATE=MN
CITY=MINNEAPOLIS
ORG=IDS
UNIT=IT

SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${HOSTNAME}"

key=${HOSTNAME}.key
req=${HOSTNAME}.req
crt=${HOSTNAME}.crt
cnf=${HOSTNAME}.cnf
keystore=${HOSTNAME}.keystore.jks

printf "\ngenerating key, csr, crt, and p12 file for $i\n\n"

printf "generate key\n============\n\n"
openssl genrsa -aes256 -passout pass:${B_PW} -out ${CERTS}/${key} 3072
[ $? -eq 1 ] && echo "unable to generate key for ${HOSTNAME}." && exit

printf "\n\nverify key\n==========\n\n"
openssl rsa -check -in ${CERTS}/${key} -passin pass:${B_PW} 
[ $? -eq 1 ] && echo "unable to verify key for ${HOSTNAME}." && exit

# This allows for hostname of just the server name (host before ".") or the entire full hostname with domain
HOST_PREFIX=$(echo $HOSTNAME | cut -d. -f1)

SUBLECT_ALT=""
if [ -z "$PUBLIC_DNS" ]
then
  SUBJECT_ALT="DNS:${HOSTNAME},DNS:${HOST_PREFIX}"
else
  SUBJECT_ALT="DNS:${HOSTNAME},DNS:${HOST_PREFIX}"
  # split PUBLIC_DNS by comma and write each to the subject alt names
  IFS=',' read -ra DNSES <<< "${PUBLIC_DNS}"
  for i in "${DNSES[@]}"; do
    SUBJECT_ALT="${SUBJECT_ALT},DNS:${i}"
  done
fi
echo "Subject Alt Name=${SUBJECT_ALT}"

printf "\n\ngenerate csr\n==========\n\n"
openssl req -new -sha384 -key ${CERTS}/${key} -passin pass:${B_PW} -out ${CERTS}/${req} -subj "${SUBJECT}" \
	-reqexts SAN \
	-config <(cat ./openssl.cnf <(printf "\n[SAN]\nsubjectAltName=${SUBJECT_ALT}\nextendedKeyUsage=serverAuth,clientAuth"))
[ $? -eq 1 ] && echo "unable to generate csr for ${HOSTNAME}." && exit

printf "\n[v3_ca]\nsubjectAltName=${SUBJECT_ALT}\nextendedKeyUsage=serverAuth,clientAuth" > ${CERTS}/${cnf}

printf "\ncsr\n===\n\n"
openssl req -in ${CERTS}/${req} -text -noout

[ $? -eq 1 ] && echo "unable to print certificate for ${HOSTNAME}." && exit


## Sign

printf "\n\nsign csr\n========\n\n"

  #
  # sign the certificate request and extensions file
  #     openssl.cnf must have 'copy_extensions = copy'
  #     issues running on MacOS to get extensions into x509 from csr
  #
openssl x509 \
	-req \
  -sha384 \
	-CA ${CERTS}/intermediate.crt \
	-CAkey ${CERTS}/intermediate.key \
	-passin pass:$IN_PW \
	-in ${CERTS}/${req} \
	-out ${CERTS}/${crt} \
	-days 1095 \
	-CAcreateserial \
  -extfile ${CERTS}/${cnf} \
	-extensions v3_ca 
[ $? -eq 1 ] && echo "unable to sign the csr for ${HOSTNAME}." && exit

cat ${CERTS}/intermediate.crt ${CERTS}/ca.crt > ${CERTS}/chain.pem
cp ${CERTS}/chain.pem ${CERTS}/${HOSTNAME}_chain.pem

openssl verify -CAfile ${CERTS}/chain.pem ${CERTS}/${crt}
[ $? -eq 1 ] && echo "unable to verify certificate for ${HOSTNAME}." && exit

printf "\ncertificate\n===========\n\n"
openssl x509 -in ${CERTS}/${crt} -text -noout
[ $? -eq 1 ] && echo "unable to print certificate for ${HOSTNAME}." && exit

# combine key and certificate into a pkcs12 file
openssl pkcs12 -export -in ${CERTS}/${crt} -inkey ${CERTS}/${key} -passin pass:$B_PW -chain -CAfile ${CERTS}/chain.pem -name ${HOSTNAME} -out ${CERTS}/${HOSTNAME}.p12 -passout pass:$B_PW
[ $? -eq 1 ] && echo "unable to create pkcs12 file for ${HOSTNAME}." && exit
