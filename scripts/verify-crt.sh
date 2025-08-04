#!/usr/bin/env sh
#
# verify-crt.sh <Cert-File> [<CA-Cert-File>]
#
#   default CA-Cert-File is: cert/ca.crt
#

if [ ! -f "$1" ]; then
    echo "$0 : file not found: $1"
    exit 1
fi

CA_CERT="certs/ca.crt"
if [ ! -z "$2" ]; then
    CA_CERT="$2"
fi


if [ -f "./crl/rootcrl" ]; then
    openssl verify -CAfile $CA_CERT -crl_check -CRLfile crl/rootca.crl "$1"
else
    echo "No ./crl/rootcrl file found, ignoring Revoked Check!"
    openssl verify -CAfile  $CA_CERT "$1"
fi
