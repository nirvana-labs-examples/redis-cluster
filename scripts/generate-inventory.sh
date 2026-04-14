#!/bin/bash
# Generate Ansible inventory from Terraform output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
ANSIBLE_DIR="$SCRIPT_DIR/../ansible"

cd "$TERRAFORM_DIR"

# Get VM IPs from terraform output
PUBLIC_IPS=$(terraform output -json vm_public_ips | jq -r '.[]')
PRIVATE_IPS=$(terraform output -json vm_private_ips | jq -r '.[]')
NODE_COUNT=$(terraform output -raw node_count)

# Convert to arrays
PUBLIC_IPS_ARR=($PUBLIC_IPS)
PRIVATE_IPS_ARR=($PRIVATE_IPS)

# Generate inventory file
INVENTORY_FILE="$ANSIBLE_DIR/inventory.ini"

echo "[redis_nodes]" > "$INVENTORY_FILE"

for i in $(seq 0 $((NODE_COUNT - 1))); do
  echo "redis-$((i+1)) ansible_host=${PUBLIC_IPS_ARR[$i]} private_ip=${PRIVATE_IPS_ARR[$i]} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519" >> "$INVENTORY_FILE"
done

echo ""
echo "Inventory generated at $INVENTORY_FILE"
echo "Redis nodes: $NODE_COUNT"
echo "Public IPs: ${PUBLIC_IPS_ARR[*]}"
echo "Private IPs: ${PRIVATE_IPS_ARR[*]}"
