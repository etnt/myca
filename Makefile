#
# Some simple CA handling:
#
#   make all          - Generate CA cert and one Server cert.
#
#   make client       - Generate a new Client cert.
#
#   make all_clean    - Beware!! This will remove everything!
#

DIRS = certs crl private client_keys

.PHONY: all client all_clean run_scripts

all: index.txt serial crlnumber SUBJECT.env create_dirs run_scripts

run_scripts: gen_root_ca gen_server_cert init_crl

client: gen_client_cert

all_clean:
	rm -f index.txt* serial* crlnumber*
	rm -rf $(DIRS)
	rm -i SUBJECT.env

index.txt:
	touch ./index.txt

serial:
	echo "01" > ./serial

crlnumber:
	echo "1000" > ./crlnumber

SUBJECT.env:
	./scripts/gen-subject-env.sh

#
# Generate Root CA
#
.PHONY: gen_root_ca
gen_root_ca: private/cakey.pem

private/cakey.pem:
	./scripts/gen-root-ca.sh

#
# Generate Server cert
#
.PHONY: gen_server_cert
gen_server_cert: certs/server.key.pem

 certs/server.key.pem:
	./scripts/gen-server-cert.sh

#
# Generate Client cert
#
.PHONY: gen_client_cert
gen_client_cert:
	./scripts/gen-client-cert.sh

#
# Init the CRL
#
.PHONY: init_crl
init_crl:
	./scripts/init-crl.sh


create_dirs: $(DIRS)

$(DIRS):
	mkdir $@
