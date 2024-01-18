#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

echo -n "Enter client name: " ; read CNAME
echo -n "Enter client email: " ; read EMAIL

DTAG=`date | sed -e 's/ /-/g'`

FNAME=""${EMAIL}_${DTAG}""

## generate client private key
openssl genrsa -out client_keys/${FNAME}.key 4096

## generate certificate signing request
openssl req -config ./openssl.cnf -new -key client_keys/${FNAME}.key -out certs/${FNAME}.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=client/CN=${CNAME}/emailAddress=${EMAIL}"

## generate and sign the server certificate using rootca certificate
openssl ca -config ./openssl.cnf -notext -batch -in certs/${FNAME}.csr -out client_keys/${FNAME}.crt -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=client/CN=${CNAME}/emailAddress=${EMAIL}"

## Use this .pem file as the 'certfile' in the Erlang TLS client_opts()
cat client_keys/${FNAME}.key client_keys/${FNAME}.crt > client_keys/${FNAME}.pem

rm client_keys/${FNAME}.key client_keys/${FNAME}.crt
rm certs/${FNAME}.csr
