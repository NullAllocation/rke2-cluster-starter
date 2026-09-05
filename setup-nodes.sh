#!/bin/bash

# Initialize variables with defaults
INVENTORY="inventory.ini"
NODE_PASS=""
RKE2_LB_NAME="rke2-lb"
SSH_KEY=""

while getopts "i:p:n:k:h" flag; do
  case "$flag" in
    p) NODE_PASS=$OPTARG ;;
    i) INVENTORY=$OPTARG ;;
    n) RKE2_LB_NAME=$OPTARG ;;
    k) SSH_KEY=$OPTARG ;;
    h) echo -e "Sample Usage:\n  $0 -p <initial passwd>\n  $0 -i <inventory file> -p <initial passwd>\n  $0 -i <inventory file> -p <initial passwd> -n <RKE2 host name>" && exit 1 ;;
    *) echo "Invalid option" && exit 1 ;;
  esac
done


declare -A host_map
host_file_entry=""

#Ensure required inputs are available
if [[ ! -f "$INVENTORY" ]]; then
    echo "Inventory file does not exist."
    exit 1
elif [[ -z "$NODE_PASS" ]]; then
    echo "A password is required for the nodes during initial setup."
    exit 1
elif [[ -z "$RKE2_LB_NAME" ]]; then
    echo "The RKE2 load balancer host must be specified."
    exit 1
elif [[ ! -z $SSH_KEY && ! -f "$SSH_KEY" ]]; then
    echo "The key file '$SSH_KEY' is not found."
    exit 1
fi

# Parse the inventory file for host names and address
while read -r name ansible_host; do
    if [[ -z "$ansible_host" ]]; then
        continue
    fi
    ip=$(echo "$ansible_host" | grep -oP '(?<=ansible_host=)\S+')
    if [[ -z "$ip" ]]; then
        continue
    fi
    
    host_map[$name]=$ip
    host_file_entry+="$ip $name"$'\n'
done < $INVENTORY

# Insert the ip of the RKE2 load balancer host (obtained from the inventory) into the playbook file.
sed -i "s/rke2_api_ip:[[:space:]]\+.*/rke2_api_ip: ${host_map[$RKE2_LB_NAME]}/" playbook.yaml
sed -i "s/rke2_tls_san:[[:space:]]\+.*/rke2_tls_san: [$RKE2_LB_NAME, ${host_map[$RKE2_LB_NAME]}]/" playbook.yaml

# Test whether host key files exist, if not then generate keys for this host to support running Ansible automation playbooks
if [[ -z "$SSH_KEY" ]]; then
    SSH_KEY=$(grep -oP '(?<=ansible_ssh_private_key_file=)\S+' $INVENTORY)
    if [[ ! -f $SSH_KEY ]]; then
      echo "Generating cryptographic keys for this host."
      ssh-keygen -t ed25519 -f $SSH_KEY -N "" -q
      exit_code=$?
      if [ $exit_code -ne 0 ]; then
        echo "Failed to generate crypographic keys for this host"
        exit 1
      fi
    fi
fi

# Apply configuration to each host
errors=()
for key in "${!host_map[@]}"; do
    echo "Adjusting the host file and name on $key(${host_map[$key]})..."
    ssh-keygen -f '/root/.ssh/known_hosts' -R ${host_map[$key]} > /dev/null 2>&1
    sshpass -p $NODE_PASS ssh-copy-id -o StrictHostKeyChecking=no -i $SSH_KEY root@${host_map[$key]} > /dev/null 2>&1

    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      errors+=("Failed to copy host key '$SSH_KEY' to host $key")
      continue
    fi

    ssh -T -o StrictHostKeyChecking=no root@${host_map[$key]} << EOF
    hostnamectl set-hostname "$key"
    sed -i "/localhost/! s/^127\.0\.0\.1[[:space:]]\+.*/127.0.0.1 $key/" /etc/hosts
    sed -i "s/^127\.0\.1\.1[[:space:]]\+.*/127.0.1.1 $key/" /etc/hosts
    echo "$host_file_entry" >> /etc/hosts
EOF
done

# Print errors
if [ ${#errors[@]} -ne 0 ]; then
  echo -e "Errors\n---------"
  for error in "${errors[@]}"; do
    echo "$error"
  done
fi

