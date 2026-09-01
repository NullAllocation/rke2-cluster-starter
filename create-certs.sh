#!/bin/bash

# Create sample TLS certificates for testing
mkdir -p certs
cd certs
openssl req -x509 -newkey rsa:4096 -keyout tls.pem.key -out tls.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
chmod 644 tls.pem
chmod 644 tls.pem.key

