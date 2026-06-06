#!/bin/bash
set -e

cd terraform
PUBLIC_IP=$(terraform output -raw instance_public_ip)
cd ..

echo "Checking Minecraft server port on $PUBLIC_IP..."
nmap -sV -Pn -p T:25565 "$PUBLIC_IP"