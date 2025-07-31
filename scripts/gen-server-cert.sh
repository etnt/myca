#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

# Create a new 384-bit Elliptic Curve private key and a CSR.
# The CSR contains the public key and the identity (sibject line),
# which can then be sent to a Certificate Authority (CA) to
# be signed and issued as a digital certificate.
openssl req -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout private/server.key -nodes -out csr/server.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=server/CN=${CNAME}/emailAddress=${EMAIL}"

# Sign the server.csr certificate request using our local
# CA configuration, creating a server certificate valid for
# 10 years and saving it as: certs/server.crt.
openssl ca -config ./openssl.cnf -batch -notext -in csr/server.csr -days 3652 -out certs/server.crt
