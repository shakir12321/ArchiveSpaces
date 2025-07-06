#!/bin/bash
# Extract optional scripts from Terraform outputs
# This script helps users get the demo data and digital objects setup scripts

set -e

echo "=== Extracting Optional Scripts from Terraform Outputs ==="
echo ""

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "Error: This script must be run from the terraform-mainifest directory"
    echo "Please run: cd terraform-mainifest && ./extract-scripts.sh"
    exit 1
fi

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed or not in PATH"
    exit 1
fi

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: No terraform.tfstate found. Please run 'terraform apply' first."
    exit 1
fi

echo "Extracting demo data loading script..."
terraform output demo_data_script > load-demo-data.sh
chmod +x load-demo-data.sh
echo "✅ Created: load-demo-data.sh"

echo ""
echo "Extracting digital objects setup script..."
terraform output digital_objects_script > setup-digital-objects.sh
chmod +x setup-digital-objects.sh
echo "✅ Created: setup-digital-objects.sh"

echo ""
echo "=== Scripts Extracted Successfully ==="
echo ""
echo "Available scripts:"
echo "  - load-demo-data.sh        # Load sample archival data"
echo "  - setup-digital-objects.sh # Configure digital object management"
echo ""
echo "To use these scripts:"
echo "  1. SSH into your VM: ssh azureuser@<PUBLIC_IP>"
echo "  2. Copy the scripts to the VM"
echo "  3. Run them from the ArchivesSpace directory"
echo ""
echo "Example:"
echo "  scp load-demo-data.sh azureuser@<PUBLIC_IP>:~/"
echo "  ssh azureuser@<PUBLIC_IP>"
echo "  cd ~/archivesspace/archivesspace"
echo "  ../load-demo-data.sh" 