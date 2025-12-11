#!/bin/sh

# Get server IP from Terraform output
cd ../terraform
SERVER_IP=$(terraform output -raw server_ipv4)
cd ../ansible

# Get Python path from remote server
PYTHON_PATH=$(ssh pxp9@${SERVER_IP} 'which python3')

# Generate Ansible inventory
cat > inventory.yml <<EOF
---
all:
  hosts:
    main_server:
      ansible_host: ${SERVER_IP}
      ansible_user: pxp9
      ansible_ssh_private_key_file: ~/.ssh/hetzner
      ansible_python_interpreter: ${PYTHON_PATH}
EOF

echo "Inventory generated with server IP: ${SERVER_IP}"
echo "Python interpreter: ${PYTHON_PATH}"
