#!/usr/bin/env sh

if [ ! -f "$1" ]; then
    echo "$0 : file not found: $1"
    exit 1
fi

openssl verify -CAfile certs/ca.crt -crl_check -CRLfile crl/rootca.crl "$1"
