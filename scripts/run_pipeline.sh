#!/bin/bash
set -e

echo "Starting Minecraft automation pipeline..."

cd terraform

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve

PUBLIC_IP=$(terraform output -raw instance_public_ip)

cd ..

echo "Copying private key to WSL SSH directory..."
mkdir -p ~/.ssh
cp terraform/minecraft_key.pem ~/.ssh/minecraft_key.pem
chmod 600 ~/.ssh/minecraft_key.pem

echo "Writing Ansible inventory..."
cat > ansible/inventory.ini <<EOF
[minecraft]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/minecraft_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Waiting for EC2 instance to become reachable..."
sleep 45

echo "Running Ansible playbook..."
cd ansible
ansible-playbook -i inventory.ini setup_minecraft.yml

cd ..

echo "Minecraft server setup complete."
echo "Server address: $PUBLIC_IP:25565"
echo "Run this to verify the port:"
echo "nmap -sV -Pn -p T:25565 $PUBLIC_IP"