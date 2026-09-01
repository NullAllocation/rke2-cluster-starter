#!/bin/bash

# Initialize variables with defaults
INVENTORY="inventory"
NODE_PASS=""
RKE2_LB_NAME="rke2-lb"
SSH_KEY=""

while getopts "i:p:h:k:" flag; do
  case "$flag" in
    p) NODE_PASS=$OPTARG ;;
    i) INVENTORY=$OPTARG ;;
    h) RKE2_LB_NAME=$OPTARG ;;
    k) SSH_KEY=$OPTARG ;;
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
sed -i "s/rke2_api_ip[[:space:]]\+:[[:space:]]\+.*/rke2_api_ip : ${host_map[$RKE2_LB_NAME]}/" playbook.yaml

# Apply configuration to each host
errors=()
for key in "${!host_map[@]}"; do
    echo "Adjusting the host file and name on $key(${host_map[$key]})..."
    ssh-keygen -f '/root/.ssh/known_hosts' -R ${host_map[$key]} > /dev/null 2>&1
    sshpass -p $NODE_PASS  ssh-copy-id -o StrictHostKeyChecking=no $([ -n "$SSH_KEY" ] && echo "-i $SSH_KEY") root@${host_map[$key]} > /dev/null 2>&1

    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      errors+=("Failed to copy host key $([ -n "$SSH_KEY" ] && echo "'$SSH_KEY' ")to host $key")
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

