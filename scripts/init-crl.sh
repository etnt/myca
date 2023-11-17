#!/usr/bin/env sh

# Generate a new CRL
openssl ca -config openssl.cnf -gencrl -out crl/rootca.crl

# Setup a hash link, remove the old one
# See: https://www.erlang.org/doc/man/ssl#type-cert_pem
# Explanation of: ssl_crl_hash_dir
rm -f crl/*.r?
HASH=`openssl crl -noout -hash -in crl/rootca.crl`
(cd crl; ln -s rootca.crl "${HASH}.r0" )
