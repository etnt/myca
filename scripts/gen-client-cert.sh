#!/usr/bin/env sh

if [ -f SUBJECT.env ]; then
    . ./SUBJECT.env
else
    echo "$0 : no SUBJECT.env file found"
    exit 1
fi

echo -n "Enter client name: " ; read CNAME
echo -n "Enter client email: " ; read EMAIL

# Ask if user wants to add Subject Alternative Names
echo ""
echo "Subject Alternative Names (SANs) allow additional identities in the certificate."
echo "The email address will be automatically added to SAN for Cryptic username extraction."
echo -n "Do you want to add additional SANs? (y/N): " ; read ADD_SANS

# Initialize SAN variables
# Always include the email in SAN for Cryptic username extraction
EMAIL_SANS="$EMAIL"
DNS_SANS=""
IP_SANS=""
URI_SANS=""

# Only prompt for additional SAN details if user wants them
if [ "$ADD_SANS" = "y" ] || [ "$ADD_SANS" = "Y" ]; then
    echo "Enter additional Subject Alternative Names (SANs) - press Enter to skip each type:"
    echo -n "DNS names (comma-separated): " ; read DNS_SANS
    echo -n "IP addresses (comma-separated): " ; read IP_SANS
    echo -n "Additional email addresses (comma-separated): " ; read ADDITIONAL_EMAILS
    if [ -n "$ADDITIONAL_EMAILS" ]; then
        EMAIL_SANS="$EMAIL,$ADDITIONAL_EMAILS"
    fi
    echo -n "URIs (comma-separated): " ; read URI_SANS
fi

DTAG=`date | sed -e 's/ /-/g'`

FNAME=""${EMAIL}_${DTAG}""

# Build SAN string - always include email for Cryptic username extraction
SAN_PARTS=""

# Add email first (always included)
SAN_PARTS="email:$(echo "$EMAIL_SANS" | sed 's/,/, email:/g')"

if [ -n "$DNS_SANS" ]; then
    # Convert comma-separated DNS names to SAN format
    DNS_FORMATTED=$(echo "$DNS_SANS" | sed 's/,/, DNS:/g' | sed 's/^/DNS:/')
    SAN_PARTS="$SAN_PARTS, $DNS_FORMATTED"
fi

if [ -n "$IP_SANS" ]; then
    # Convert comma-separated IP addresses to SAN format
    IP_FORMATTED=$(echo "$IP_SANS" | sed 's/,/, IP:/g' | sed 's/^/IP:/')
    SAN_PARTS="$SAN_PARTS, $IP_FORMATTED"
fi

if [ -n "$URI_SANS" ]; then
    # Convert comma-separated URIs to SAN format
    URI_FORMATTED=$(echo "$URI_SANS" | sed 's/,/, URI:/g' | sed 's/^/URI:/')
    SAN_PARTS="$SAN_PARTS, $URI_FORMATTED"
fi

SAN_STRING="subjectAltName = $SAN_PARTS"

# Create temporary config file with SAN extension
TEMP_CONFIG="/tmp/openssl_san_${FNAME}.cnf"
cp ./openssl.cnf "$TEMP_CONFIG"

# Add SAN to the v3_client section
sed -i.bak "/# SAN will be added dynamically if provided/c\\
$SAN_STRING" "$TEMP_CONFIG"

CONFIG_FILE="$TEMP_CONFIG"

# Display what will be created
echo ""
echo "Creating certificate with:"
echo "  Common Name (CN): $CNAME"
echo "  Email: $EMAIL"
echo "  Subject Alternative Names: $SAN_PARTS"
echo "  Cryptic username will be extracted from: email local part"
if [ -n "$EMAIL" ]; then
    EXTRACTED_USERNAME=$(echo "$EMAIL" | cut -d'@' -f1)
    echo "  → Cryptic username: $EXTRACTED_USERNAME"
fi
echo ""

# generate certificate signing request
openssl req -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout client_keys/${FNAME}.key -nodes -out csr/${FNAME}.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=client/CN=${CNAME}/emailAddress=${EMAIL}"

# generate and sign the client certificate using rootca certificate
# Use v3_client extensions for proper client certificate with OTP 28 compatibility
openssl ca -config "$CONFIG_FILE" -extensions v3_client -batch -notext -in csr/${FNAME}.csr -days 3652 -out client_keys/${FNAME}.crt

## Use this .pem file as the 'certfile' in the Erlang TLS client_opts()
cat client_keys/${FNAME}.key client_keys/${FNAME}.crt > client_keys/${FNAME}.pem

# Clean up temporary config file if it was created
if [ -n "$TEMP_CONFIG" ] && [ -f "$TEMP_CONFIG" ]; then
    rm -f "$TEMP_CONFIG" "$TEMP_CONFIG.bak"
fi

