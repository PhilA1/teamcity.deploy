#!/bin/bash
echo $'>> Initializing backend...\n'
terraform init 
terraform plan -var-file="variables.tfvars" 

echo $'>> Executing Terraform apply...\n'
terraform apply -var-file="variables.tfvars" 
