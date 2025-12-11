.PHONY: init plan apply destroy clean format unlock help

# Default target
help:
	@echo "Available targets:"
	@echo "  make init    - Initialize Terraform"
	@echo "  make plan    - Show Terraform execution plan"
	@echo "  make apply   - Apply Terraform configuration"
	@echo "  make destroy - Destroy Terraform-managed infrastructure"
	@echo "  make format  - Format Terraform files"
	@echo "  make unlock id=LOCK_ID - Unlock Terraform state"
	@echo "  make clean   - Remove Terraform files (.terraform, .tfstate)"

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan: init format
	terraform plan -var-file="secrets.tfvars"

# Apply Terraform configuration
apply:
	terraform apply -var-file="secrets.tfvars"
	@echo "Generating Ansible inventory..."
	@cd ../ansible && ./generate-inventory.sh

# Destroy infrastructure
destroy:
	terraform destroy -var-file="secrets.tfvars"

# Format Terraform files
format:
	terraform fmt

# Unlock Terraform state (usage: make unlock id=LOCK_ID)
unlock:
ifndef id
	@echo "Error: 'id' variable is required. Usage: make unlock id=LOCK_ID"
	@exit 1
endif
	terraform force-unlock $(id)

# Clean up Terraform files
clean:
	rm -rf .terraform .terraform.lock.hcl
	@echo "Cleaned Terraform cache and lock files"
