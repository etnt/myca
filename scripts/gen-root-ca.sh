#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

openssl req -x509 -days 3650 -sha384 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout private/ca.key -nodes -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=root/CN=${CNAME}/emailAddress=${EMAIL}" -out certs/ca.crt

## Verify the rootCA certificate content and X.509 extensions
#openssl x509 -noout -text -in certs/ca.crt
