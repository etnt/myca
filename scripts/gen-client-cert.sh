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

# generate certificate signing request
openssl req -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout client_keys/${FNAME}.key -nodes -out csr/${FNAME}.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=client/CN=${CNAME}/emailAddress=${EMAIL}"

# generate and sign the server certificate using rootca certificate
openssl ca -config ./openssl.cnf -batch -notext -in csr/${FNAME}.csr -days 3652 -out client_keys/${FNAME}.crt

## Use this .pem file as the 'certfile' in the Erlang TLS client_opts()
cat client_keys/${FNAME}.key client_keys/${FNAME}.crt > client_keys/${FNAME}.pem

