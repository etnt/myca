#!/usr/bin/env sh

#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

## generate server private key
openssl genrsa -out certs/server.key 4096

## generate certificate signing request
openssl req -new -key certs/server.key -out certs/server.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=server/CN=${CNAME}/emailAddress=${EMAIL}"

## generate and sign the server certificate using rootca certificate
openssl ca -config openssl.cnf -notext -batch -in certs/server.csr -out certs/server.crt -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=server/CN=${CNAME}/emailAddress=${EMAIL}"


cat certs/server.key certs/server.crt > certs/server.pem

rm certs/server.csr
