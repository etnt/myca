# myca - A simple CA (Certification Authority) framework
> Self-signed generation and revocation of certificates.

`myca` is a very simple CA framework that was broken out
from the [gunsmoke](https://github.com/etnt/gunsmoke) project;
hence it may be best suited for Erlang projects. On the other
hand, it only contain a very simple Makefile and equally 
simple shell scripts; so it may be useful to others as well.

## Installation

Just clone it. Then (assuming you have the `openssl`
command installed) start using it.

You could integrate `myca` by simply clone it into a
subdirectory of your project. Like this:

    git clone --depth 1 https://github.com/etnt/myca.git CA
    
then enter your `CA` directory and setup your certificates
that you then can refer to from your setup. This is how
`gunsmoke` does it.

## Usage

The `Makefile` has three targets:

1. `make all` - Generate a CA cert and one Server cert.

2. `make client` - Generate a new Client cert.

3. `make all_clean` - Beware!! This will remove all certificates!

So when you run `make all` it will create a number of subdirectories
and ask you a for some info that is used when creating the certificates.
This info will be stored in a file named: `SUBJECT.env`.
It will also create a CA certificate and a Server certificate and key.
The CA certificate (`ca.crt`) is stored in the `certs` subdirectory,
while private keys are stored in the `private` subdirectory for security.
Certificate signing requests (CSR) are stored in the `csr` subdirectory.

The framework now uses modern elliptic curve cryptography (secp384r1) 
instead of RSA for better security and performance.

The CA certificate is used to sign all the other certificates.

The Server certificate and key is used by your SSL/TLS server.

Clients that connects to your server could make use of
client certificates. To generate a new such certificate for
a particular client, run: `make client`. You will be prompted
for a full name and an email. The generated client certificate
and key will be stored in the `client_keys` subdirectory.

If you want to revoke a (client) certificate, you can
use the `revoke-cert.sh` shell script that is located
in the `scripts` subdirectory. Information about revoked
certificates is stored in the `crl` subdirectory.

## Key Features

- **Modern Cryptography**: Uses elliptic curve cryptography (secp384r1) for enhanced security and performance
- **Long-lived Certificates**: Generates certificates valid for 10 years (3652 days)
- **Organized File Structure**: 
  - `certs/` - CA and issued certificates
  - `private/` - Private keys (CA and server)
  - `csr/` - Certificate signing requests
  - `client_keys/` - Client certificates and keys
  - `crl/` - Certificate revocation lists

## Example

``` shell
❯ make all
mkdir certs
mkdir csr
mkdir crl
mkdir private
mkdir client_keys
touch ./index.txt
echo "01" > ./serial
echo "1000" > ./crlnumber
./scripts/gen-root-ca.sh
-----
./scripts/gen-server-cert.sh
-----
Using configuration from ./openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: Jul 31 17:02:53 2025 GMT
            Not After : Jul 31 17:02:53 2035 GMT
        Subject:
            countryName               = SE
            stateOrProvinceName       = Stockholm
            organizationName          = Kruskakli
            organizationalUnitName    = server
            commonName                = Karl Kruska
            emailAddress              = karl@kruskakli.se
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                36:2A:FF:90:88:B9:B8:F3:D7:64:17:8E:9D:06:CE:10:86:0A:05:A5
            X509v3 Authority Key Identifier:
                27:A2:55:7F:5A:07:09:40:12:0F:D0:B4:45:05:18:C4:38:D2:D0:7E
            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Jul 31 17:02:53 2035 GMT (3652 days)

Write out database with 1 new entries
Database updated
```

Info about generated certificates are stored in a file named:
`index.txt` (this is done by the `openssl` command). Example:

``` shell
❯ cat index.txt
V       350731170253Z           01      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=server/CN=Karl Kruska/emailAddress=karl@kruskakli.se
```

The certificates are numbered and stored in the `certs` directory.
Example:

``` shell
❯ ls certs/
01.pem  02.pem  ca.crt  server.crt

❯ ls private/
ca.key  server.key

❯ ls csr/
server.csr
```

To create a new client certificate:

``` shell
❯ make client
Enter client name: Rune Gustafsson
Enter client email: rune@kruskakli.se
-----
Using configuration from ./openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 2 (0x2)
        Validity
            Not Before: Jul 31 17:12:51 2025 GMT
            Not After : Jul 31 17:12:51 2035 GMT
        Subject:
            countryName               = SE
            stateOrProvinceName       = Stockholm
            organizationName          = Kruskakli
            organizationalUnitName    = client
            commonName                = Rune Gustafsson
            emailAddress              = rune@kruskakli.se
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                EC:3C:D5:22:72:F7:D0:E9:2A:AC:E2:69:3C:D6:67:0E:30:AF:D5:6F
            X509v3 Authority Key Identifier:
                27:A2:55:7F:5A:07:09:40:12:0F:D0:B4:45:05:18:C4:38:D2:D0:7E
            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Jul 31 17:12:51 2035 GMT (3652 days)

Write out database with 1 new entries
Database updated
```

Note the Serial Number, which now is `2` this is reflected both in
the `index.txt` file as well as in the `certs` subdirectory:

``` shell
❯ cat index.txt
V       350731170253Z           01      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=server/CN=Karl Kruska/emailAddress=karl@kruskakli.se
V       350731171251Z           02      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=client/CN=Rune Gustafsson/emailAddress=rune@kruskakli.se

❯ ls certs
01.pem  02.pem  ca.crt  server.crt

❯ ls csr
rune@kruskakli.se_Thu-Jul-31-19:12:51-CEST-2025.csr
server.csr
```

Note the first character of each line in the `index.txt` file; 
it is called the Status Flag, and can take on the values:
V (Valid), R (Revoked) and E (Expired).

In the `client_keys` subdirectory we find the client certificates
that clients should get to use from their end of the SSL/TLS connection.
Note that each `.pem` file contains both the key and the certificate.

``` shell
❯ ls client_keys/
rune@kruskakli.se_Thu-Jul-31-19:12:51-CEST-2025.crt
rune@kruskakli.se_Thu-Jul-31-19:12:51-CEST-2025.key
rune@kruskakli.se_Thu-Jul-31-19:12:51-CEST-2025.pem
```

To try out revocation, we first create a new client cert.
Our `index.txt` file now looks like:

``` shell
❯ cat index.txt
V       350731170253Z           01      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=server/CN=Karl Kruska/emailAddress=karl@kruskakli.se
V       350731171251Z           02      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=client/CN=Rune Gustafsson/emailAddress=rune@kruskakli.se
V       350731171811Z           03      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=client/CN=Bo Bengtsson/emailAddress=bo@kruskakli.se

```

If we want to revoke the `02` (Rune Gustafsson) certificate, we do:

``` shell
❯ ./scripts/revoke-cert.sh certs/02.pem 
Using configuration from openssl.cnf
Revoking Certificate 02.
Database updated
Using configuration from openssl.cnf
```

We can now see that the certificate has been revoked by looking into the
`index.txt` file again (note the `R` status flag):

```shell
❯ cat index.txt
V       350731170253Z           01      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=server/CN=Karl Kruska/emailAddress=karl@kruskakli.se
R       350731171251Z   250731171940Z   02      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=client/CN=Rune Gustafsson/emailAddress=rune@kruskakli.se
V       350731171811Z           03      unknown /C=SE/ST=Stockholm/O=Kruskakli/OU=client/CN=Bo Bengtsson/emailAddress=bo@kruskakli.se
```

We have also created a CRL file according to how the Erlang SSL library want it:

```shell
❯ ls -l crl
lrwxrwxrwx 1 tobbe tobbe   10 Nov 16 23:21 f0c82f1c.r0 -> rootca.crl
-rw-r--r-- 1 tobbe tobbe 1125 Nov 16 23:21 rootca.crl
```

We can print info about the revoked certificate as:
```shell
❯ ./scripts/print-crl.sh 
Certificate Revocation List (CRL):
        Version 2 (0x1)
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: C=SE, ST=Stockholm, L=EkerÃ¶, O=Kruskakli, OU=root, CN=Karl Kruska, emailAddress=karl@kruskakli.se
        Last Update: Jul 31 17:19:40 2025 GMT
        Next Update: Aug 30 17:19:40 2025 GMT
        CRL extensions:
            X509v3 Authority Key Identifier: 
                27:A2:55:7F:5A:07:09:40:12:0F:D0:B4:45:05:18:C4:38:D2:D0:7E
            X509v3 CRL Number: 
                4097
Revoked Certificates:
    Serial Number: 02
        Revocation Date: Jul 31 17:19:40 2025 GMT
    Signature Algorithm: ecdsa-with-SHA256
    Signature Value:
        30:65:02:30:17:18:d7:8b:09:a9:f7:2c:e2:a5:f6:fc:6c:cb:
        43:9b:22:2f:ff:a0:af:18:84:57:84:9a:cf:ff:40:b6:0e:35:
        9a:43:03:2f:44:01:ae:6f:ba:03:33:4b:dc:4e:8e:40:02:31:
        00:c5:39:ee:6a:3e:c2:02:6d:f3:bc:b8:8e:40:23:84:5c:0b:
        95:2e:c9:53:ab:6d:57:45:7c:b7:ac:1d:21:d8:45:44:99:6a:
        15:3d:d6:d2:30:a8:4f:eb:31:b5:27:9d:e0
```

### Erlang setup

There are a number of options that can be set when using the
Erlang SSL application. But here is an example of a working setup.

The Erlang SSL/TLS server setup:

``` erlang
[ {verify, verify_peer}
  %% Used together with 'verify_peer}'. If set to true,
  %% the server fails if the client does not have a certificate
  %% to send, that is, sends an empty certificate. If set to
  %% false, it fails only if the client sends an invalid
  %% certificate (an empty certificate is considered valid).
  %% Defaults to false.
, {fail_if_no_peer_cert, true}
, {cacertfile, "/home/tobbe/git/gunsmoke/CA/certs/ca.crt"}
, {certfile, "/home/tobbe/git/gunsmoke/CA/certs/server.crt"}
, {keyfile, "/home/tobbe/git/gunsmoke/CA/private/server.key"}
  %% Perform CRL (Certificate Revocation List) verification
  %% on the peer certificate.
, {crl_check, peer}
, {crl_cache, {ssl_crl_hash_dir, {internal, [{dir, "/home/tobbe/git/gunsmoke/CA/crl"}]}}}
]
```

The client can use the following:

``` erlang
[ {verify, verify_peer}
  %% Note: when `verify` is set to `verify_peer`, we may
  %%  want to disable the Hostname check.
, {server_name_indication, disable}
, {cacertfile, "/home/tobbe/git/gunsmoke/CA/certs/ca.crt"}
%, {certfile, "/home/tobbe/git/gunsmoke/CA/client_keys/rune@kruskakli.se_Thu-Jul-31-19:12:51-CEST-2025.pem"}
, {certfile, "/home/tobbe/git/gunsmoke/CA/client_keys/bo@kruskakli.se_Thu-Jul-31-19:18:11-CEST-2025.pem"}
]
```

Note the `certfile` that is behind comments, if you have followed the
example you could try what happens when you switch between these
two certificates; one is valid and one is revoked.

__Good luck!__


