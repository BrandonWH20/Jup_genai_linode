#!/bin/bash

echo " Welcome to the GenAI Lab Terraform Bootstrap Script"

# Check for terraform.tfvars
if [ ! -f terraform.tfvars ]; then
  echo "  'terraform.tfvars' not found. Creating from template..."
  cp terraform.tfvars.template terraform.tfvars
  echo " Please edit 'terraform.tfvars' to include your Linode token and project details."
  exit 1
else
  echo " 'terraform.tfvars' already exists. Continuing setup..."
fi

# Initialize Terraform
echo " Initializing Terraform..."
terraform init

# Show a plan
echo "Running Terraform plan..."
terraform plan

