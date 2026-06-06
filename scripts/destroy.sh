#!/bin/bash
set -e

echo "Destroying AWS infrastructure..."

cd terraform
terraform destroy -auto-approve

echo "Infrastructure destroyed."