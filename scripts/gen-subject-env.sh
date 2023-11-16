#!/usr/bin/env sh

# Get the necessary input
echo -n "Country Code: " ; read CC
echo -n "State: " ; read STATE
echo -n "City: " ; read CITY
echo -n "Organization: " ; read ORG
echo -n "Common Name: " ; read CNAME
echo -n "Email: " ; read EMAIL
echo ""

cat > SUBJECT.env <<EOF
CC="${CC}"
STATE="${STATE}"
CITY="${CITY}"
ORG="${ORG}"
CNAME="${CNAME}"
EMAIL="${EMAIL}"
EOF
