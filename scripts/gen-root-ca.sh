#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

## generate rootca private key
openssl genrsa  -out private/cakey.pem 4096

## generate rootCA certificate
openssl req -new -x509 -days 3650 -config openssl.cnf -key private/cakey.pem -out certs/cacert.pem -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=root/CN=${CNAME}/emailAddress=${EMAIL}"

## Verify the rootCA certificate content and X.509 extensions
#openssl x509 -noout -text -in certs/cacert.pem
