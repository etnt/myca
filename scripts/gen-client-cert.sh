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
echo -n "Do you want to add Subject Alternative Names (SANs)? (y/N): " ; read ADD_SANS

# Initialize SAN variables
DNS_SANS=""
IP_SANS=""
EMAIL_SANS=""
URI_SANS=""

# Only prompt for SAN details if user wants to add them
if [ "$ADD_SANS" = "y" ] || [ "$ADD_SANS" = "Y" ]; then
    echo "Enter Subject Alternative Names (SANs) - press Enter to skip each type:"
    echo -n "DNS names (comma-separated): " ; read DNS_SANS
    echo -n "IP addresses (comma-separated): " ; read IP_SANS
    echo -n "Email addresses (comma-separated): " ; read EMAIL_SANS
    echo -n "URIs (comma-separated): " ; read URI_SANS
fi

DTAG=`date | sed -e 's/ /-/g'`

FNAME=""${EMAIL}_${DTAG}""

# Build SAN string if any SAN values are provided
SAN_STRING=""
if [ -n "$DNS_SANS" ] || [ -n "$IP_SANS" ] || [ -n "$EMAIL_SANS" ] || [ -n "$URI_SANS" ]; then
    SAN_PARTS=""
    
    if [ -n "$DNS_SANS" ]; then
        # Convert comma-separated DNS names to SAN format
        DNS_FORMATTED=$(echo "$DNS_SANS" | sed 's/,/, DNS:/g' | sed 's/^/DNS:/')
        SAN_PARTS="$SAN_PARTS$DNS_FORMATTED"
    fi
    
    if [ -n "$IP_SANS" ]; then
        # Convert comma-separated IP addresses to SAN format
        IP_FORMATTED=$(echo "$IP_SANS" | sed 's/,/, IP:/g' | sed 's/^/IP:/')
        if [ -n "$SAN_PARTS" ]; then
            SAN_PARTS="$SAN_PARTS, $IP_FORMATTED"
        else
            SAN_PARTS="$IP_FORMATTED"
        fi
    fi
    
    if [ -n "$EMAIL_SANS" ]; then
        # Convert comma-separated email addresses to SAN format
        EMAIL_FORMATTED=$(echo "$EMAIL_SANS" | sed 's/,/, email:/g' | sed 's/^/email:/')
        if [ -n "$SAN_PARTS" ]; then
            SAN_PARTS="$SAN_PARTS, $EMAIL_FORMATTED"
        else
            SAN_PARTS="$EMAIL_FORMATTED"
        fi
    fi
    
    if [ -n "$URI_SANS" ]; then
        # Convert comma-separated URIs to SAN format
        URI_FORMATTED=$(echo "$URI_SANS" | sed 's/,/, URI:/g' | sed 's/^/URI:/')
        if [ -n "$SAN_PARTS" ]; then
            SAN_PARTS="$SAN_PARTS, $URI_FORMATTED"
        else
            SAN_PARTS="$URI_FORMATTED"
        fi
    fi
    
    SAN_STRING="subjectAltName = $SAN_PARTS"
    
    # Create temporary config file with SAN extension
    TEMP_CONFIG="/tmp/openssl_san_${FNAME}.cnf"
    cp ./openssl.cnf "$TEMP_CONFIG"
    
    # Add SAN to the v3_client section
    sed -i.bak "/# SAN will be added dynamically if provided/c\\
$SAN_STRING" "$TEMP_CONFIG"
    
    CONFIG_FILE="$TEMP_CONFIG"
else
    CONFIG_FILE="./openssl.cnf"
fi

# generate certificate signing request
openssl req -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout client_keys/${FNAME}.key -nodes -out csr/${FNAME}.csr -subj "/C=${CC}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=client/CN=${CNAME}/emailAddress=${EMAIL}"

# generate and sign the server certificate using rootca certificate
openssl ca -config "$CONFIG_FILE" -batch -notext -in csr/${FNAME}.csr -days 3652 -out client_keys/${FNAME}.crt

## Use this .pem file as the 'certfile' in the Erlang TLS client_opts()
cat client_keys/${FNAME}.key client_keys/${FNAME}.crt > client_keys/${FNAME}.pem

# Clean up temporary config file if it was created
if [ -n "$TEMP_CONFIG" ] && [ -f "$TEMP_CONFIG" ]; then
    rm -f "$TEMP_CONFIG" "$TEMP_CONFIG.bak"
fi

