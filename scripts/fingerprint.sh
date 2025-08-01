#!/usr/bin/env sh

if [ ! -f "$1" ]; then
    echo "$0 : file not found: $1"
    exit 1
fi

openssl x509 -in "$1" -fingerprint -sha256 -noout
