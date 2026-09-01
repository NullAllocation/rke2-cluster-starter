#!/bin/bash

# Initialize variables with defaults
RKE2_LB_NAME="rke2-lb"

while getopts "n:h" flag; do
  case "$flag" in
    n) RKE2_LB_NAME=$OPTARG ;;
    h) echo -e "Sample Usage:\n  $0\n  $0 -n <RKE2 host name>" && exit 1 ;;
    *) echo "Invalid option" && exit 1 ;;
  esac
done


#Ensure required inputs are available
if [[ -z "$RKE2_LB_NAME" ]]; then
    echo "The RKE2 load balancer host must be specified."
    exit 1
fi


# Create a sample TLS certificates for testing. Insert the ip of the RKE2 load balancer host (obtained from the inventory) into the certificate.
mkdir -p certs
cd certs
openssl req -x509 -newkey rsa:4096 -keyout rke2.pem.key -out rke2.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=$RKE2_LB_NAME"
chmod 644 rke2.pem
chmod 644 rke2.pem.key

