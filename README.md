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
It will also create a CA certificate and a Server certificate and key,
which are stored in the `certs` subdirectory.

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

## Example

``` shell
❯ make all
touch ./index.txt
echo "01" > ./serial
echo "1000" > ./crlnumber
./scripts/gen-subject-env.sh
Country Code: US
State: Texas
City: Dallas
Organization: Ewing
Common Name: Bobby Ewing
Email: bobby@ewing.com

mkdir certs
mkdir crl
mkdir private
mkdir client_keys
./scripts/gen-root-ca.sh
./scripts/gen-server-cert.sh
Using configuration from openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: Nov 16 22:41:30 2023 GMT
            Not After : Nov 15 22:41:30 2024 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Texas
            organizationName          = Ewing
            organizationalUnitName    = server
            commonName                = Bobby Ewing
            emailAddress              = bobby@ewing.com
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                17:92:7E:88:1A:E2:2B:53:0E:0B:F9:6A:AD:08:DC:0A:B3:E8:A3:02
            X509v3 Authority Key Identifier: 
                3B:BF:78:CA:EF:38:FA:47:E1:33:D0:6F:99:15:DD:BD:70:84:88:42
            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Nov 15 22:41:30 2024 GMT (365 days)

Write out database with 1 new entries
Database updated
```

Info about generated certificates are stored in a file named:
`index.txt` (this is done by the `openssl` command). Example:

``` shell
❯ cat index.txt
V       241115224130Z           01      unknown /C=US/ST=Texas/O=Ewing/OU=server/CN=Bobby Ewing/emailAddress=bobby@ewing.com
```

The certificates are numbered and stored in the `certs` directory.
Example:

``` shell
❯ ls certs/
01.pem  cacert.pem  server.crt  server.key  server.pem
```

To create a new client certificate:

``` shell
❯ make client
./scripts/gen-client-cert.sh
Enter client name: Sue Ellen
Enter client email: sue@ewing.com
Using configuration from openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 2 (0x2)
        Validity
            Not Before: Nov 16 22:47:48 2023 GMT
            Not After : Nov 15 22:47:48 2024 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Texas
            organizationName          = Ewing
            organizationalUnitName    = client
            commonName                = Sue Ellen
            emailAddress              = sue@ewing.com
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                2F:FD:85:D6:05:52:BE:F3:AB:32:A9:21:9E:7C:38:1A:6E:35:9A:18
            X509v3 Authority Key Identifier: 
                3B:BF:78:CA:EF:38:FA:47:E1:33:D0:6F:99:15:DD:BD:70:84:88:42
            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Nov 15 22:47:48 2024 GMT (365 days)

Write out database with 1 new entries
Database updated
```

Note the Serial Number, which now is `2` this is reflected both in
the `index.txt` file as well as in the `certs` subdirectory:

``` shell
❯ cat index.txt
V       241115224130Z           01      unknown /C=US/ST=Texas/O=Ewing/OU=server/CN=Bobby Ewing/emailAddress=bobby@ewing.com
V       241115224748Z           02      unknown /C=US/ST=Texas/O=Ewing/OU=client/CN=Sue Ellen/emailAddress=sue@ewing.com

❯ ls certs
01.pem  02.pem  cacert.pem  server.crt  server.key  server.pem
```

Note the first character of each line in the `index.txt` file; 
it is called the Status Flag, and can take on the values:
V (Valid), R (Revoked) and E (Expired).

In the `client_keys` subdirectory we find the client certificates
that clients should get to use from their end of the SSL/TLS connection.
Note that each `.pem` file contains both the key and the certificate.

``` shell
❯ ls client_keys/
sue@ewing.com_Thu-Nov-16-22:47:46-UTC-2023.pem


```

To try out revocation, we first create a new client cert.
Out `index.txt` file now looks like:

``` shell
❯ cat index.txt
V       241115224130Z           01      unknown /C=US/ST=Texas/O=Ewing/OU=server/CN=Bobby Ewing/emailAddress=bobby@ewing.com
V       241115224748Z           02      unknown /C=US/ST=Texas/O=Ewing/OU=client/CN=Sue Ellen/emailAddress=sue@ewing.com
V       241115231600Z           03      unknown /C=US/ST=Texas/O=Ewing/OU=client/CN=JR Ewing/emailAddress=jr@ewing.com
```

If we want to revoke the `02` (Sue Ellen) certificate, we do:

``` shell
❯ ./scripts/revoke-cert.sh certs/02.pem 
Using configuration from openssl.cnf
Revoking Certificate 02.
Database updated
Using configuration from openssl.cnf
```

We can now see that the certificate has been revoked by looking into the
`index.txt` file again (note the `R` status flag):

``` shell
❯ cat index.txt
V       241115224130Z           01      unknown /C=US/ST=Texas/O=Ewing/OU=server/CN=Bobby Ewing/emailAddress=bobby@ewing.com
R       241115224748Z   231116232122Z   02      unknown /C=US/ST=Texas/O=Ewing/OU=client/CN=Sue Ellen/emailAddress=sue@ewing.com
V       241115231600Z           03      unknown /C=US/ST=Texas/O=Ewing/OU=client/CN=JR Ewing/emailAddress=jr@ewing.com
```

We have also created a CRL file according to how the Erlang SSL library want it:

``` shell
❯ ls -l crl
lrwxrwxrwx 1 tobbe tobbe   10 Nov 16 23:21 f0c82f1c.r0 -> rootca.crl
-rw-r--r-- 1 tobbe tobbe 1125 Nov 16 23:21 rootca.crl
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
, {cacertfile, "/home/tobbe/git/gunsmoke/CA/certs/cacert.pem"}
, {certfile, "/home/tobbe/git/gunsmoke/CA/certs/server.crt"}
, {keyfile, "/home/tobbe/git/gunsmoke/CA/certs/server.key"}
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
, {cacertfile, "/home/tobbe/git/gunsmoke/CA/certs/cacert.pem"}
%, {certfile, "/home/tobbe/git/gunsmoke/CA/client_keys/sue@ewing.com_Thu-Nov-16-22:47:46-UTC-2023.pem"}
, {certfile, "/home/tobbe/git/gunsmoke/CA/client_keys/jr@ewing.com_Thu-Nov-16-23:15:59-UTC-2023.pem"}
]
```

Note the `certfile` that is behind comments, if you have followed the
example you could try what happens when you switch between these
two certificates; one is valid and one is revoked.

__Good luck!__


