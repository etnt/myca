#!/usr/bin/env sh

# Cert file to be revoked
RFILE=$1

if [ ! -f "${RFILE}" ]; then
    echo "ERROR : ${RFILE} does not exist"
    exit 1
fi

# The certificate files in the 'cert/' dir is named
# with the given serial number, which also exist in
# the 'index.txt' file. Example: cert/01.pem
#
# Get the serial number from the filename
SNUM=`basename ${RFILE} .pem`

# The first field in the 'index.txt' file is the
# certificate status flag, which can have the values:
# (V=valid, R=revoked, E=expired).
#
# So extract the status flag to check that it is Valid
# and thus can be revoked.
SFLAG=`grep "[[:blank:]]${SNUM}[[:blank:]]" index.txt | cut -s -f 1`

if [ "${SFLAG}x" != "Vx" ]; then
    echo "ERROR : ${RFILE} does not seem to be Valid according to: index.txt"
    exit 1
fi

# Revoke cert (mark it in the index.txt file)
openssl ca -config ./openssl.cnf -revoke ${RFILE}

# Generate a new CRL
openssl ca -config ./openssl.cnf -gencrl -out crl/rootca.crl

# Setup a hash link, remove the old one
# See: https://www.erlang.org/doc/man/ssl#type-cert_pem
# Explanation of: ssl_crl_hash_dir
rm -f crl/*.r?
HASH=`openssl crl -noout -hash -in crl/rootca.crl`
(cd crl; ln -s rootca.crl "${HASH}.r0" )
