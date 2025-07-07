# ArchivesSpace Azure Deployment

This repository contains Terraform configuration to deploy ArchivesSpace v4.1.1 on Azure using the official Docker configuration package with **fully inlined installation scripts**.

## Overview

This setup deploys ArchivesSpace following the [official ArchivesSpace Docker documentation](https://docs.archivesspace.org/administration/docker/) on an Azure VM with:

- **ArchivesSpace v4.1.1** - Latest stable version
- **MySQL 8** - Database backend
- **Solr 4.1.1** - Search engine
- **Nginx** - Reverse proxy
- **Fedora 6.4.0** - Digital repository
- **ActiveMQ 5.15.9** - Message broker
- **Automated backups** - Database backup service

## 🚀 Key Features

✅ **Self-Contained**: All installation scripts are inlined in Terraform using `locals`  
✅ **Zero External Dependencies**: No separate .sh files to manage  
✅ **Fully Automated**: Complete deployment in one Terraform apply  
✅ **Production Ready**: Includes monitoring, status checks, and management scripts  
✅ **Digital Objects**: Fedora integration for digital asset management

## Prerequisites

- Azure CLI installed and authenticated
- Terraform installed (v1.0+)
- SSH key pair for VM access

## Quick Start

1. **Clone the repository:**

   ```bash
   git clone https://github.com/shakir12321/ArchiveSpaces.git
   cd ArchiveSpaces/terraform-mainifest
   ```

2. **Update the subscription ID** in `main.tf`:

   ```hcl
   provider "azurerm" {
     features {}
     subscription_id = "YOUR_SUBSCRIPTION_ID_HERE"
   }
   ```

3. **Update the SSH public key** in `main.tf`:

   ```hcl
   admin_ssh_key {
     username   = "azureuser"
     public_key = "YOUR_SSH_PUBLIC_KEY_HERE"
   }
   ```

4. **Deploy:**

   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

5. **Access ArchivesSpace:**
   - Staff Interface: `http://<PUBLIC_IP>/staff/`
   - Public Interface: `http://<PUBLIC_IP>/`
   - API: `http://<PUBLIC_IP>/api/`
   - Fedora: `http://<PUBLIC_IP>:8086/fcrepo/rest`
   - ActiveMQ Admin: `http://<PUBLIC_IP>:8161/admin`

## Architecture

```
Internet
    ↓
Azure Load Balancer (port 80)
    ↓
Ubuntu VM (Standard_D8s_v3)
    ↓
Docker Compose Stacks
    ├── ArchivesSpace Stack
    │   ├── ArchivesSpace App (port 8080)
    │   ├── MySQL Database (port 3306)
    │   ├── Solr Search (port 8983)
    │   ├── Nginx Proxy (port 80)
    │   └── Backup Service
    └── Fedora Stack
        ├── Fedora Repository (port 8086)
        └── ActiveMQ Broker (ports 61616, 8161)
```

## Configuration Details

### VM Specifications

- **Size**: Standard_D8s_v3 (8 vCPUs, 32 GB RAM)
- **OS**: Ubuntu 20.04 LTS
- **Location**: East US
- **Storage**: Premium SSD for optimal performance

### Network Security

- **SSH**: Port 22 (for management)
- **HTTP**: Port 80 (ArchivesSpace web interface)
- **ArchivesSpace**: Ports 8080, 8081, 8089, 8983, 3306
- **Fedora**: Ports 8086, 61616, 8161

### Installation Sequence

The deployment uses **Azure VM Extensions** with inlined scripts:

1. **ArchivesSpace Core** (`install_archivesspace` local)

   - Installs Docker Engine and Docker Compose
   - Downloads official ArchivesSpace v4.1.1 Docker package
   - Configures environment variables and starts containers
   - Creates monitoring and management scripts

2. **Fedora Repository** (`install_fedora` local)

   - Deploys Fedora 6.4.0 digital repository
   - Deploys ActiveMQ 5.15.9 message broker
   - Sets up networking and volumes

3. **Integration** (`install_fedora_integration` local)
   - Configures ArchivesSpace to work with Fedora
   - Enables digital object management
   - Restarts services to apply configuration

## Post-Deployment Steps

1. **Change default passwords:**

   - Access the staff interface at `http://<PUBLIC_IP>/staff/`
   - Default credentials: `admin` / `admin`
   - Change passwords immediately

2. **Load demo data (optional):**

   ```bash
   # Extract the demo data script
   ./extract-scripts.sh
   scp load-demo-data.sh azureuser@<PUBLIC_IP>:~/
   ssh azureuser@<PUBLIC_IP>
   cd ~/archivesspace/archivesspace
   ../load-demo-data.sh
   ```

3. **Setup digital objects (optional):**

   ```bash
   # Extract the digital objects script
   ./extract-scripts.sh
   scp setup-digital-objects.sh azureuser@<PUBLIC_IP>:~/
   ssh azureuser@<PUBLIC_IP>
   cd ~/archivesspace/archivesspace
   ../setup-digital-objects.sh
   ```

4. **Monitor the deployment:**

   ```bash
   ssh azureuser@<PUBLIC_IP>
   cd ~/archivesspace/archivesspace
   docker compose ps
   docker compose logs
   ./check-status.sh
   ```

## Project Structure

```
terraform-mainifest/
├── main.tf                    # Main Terraform configuration with inlined scripts
├── README.md                  # This documentation
├── DEVELOPMENT_GUIDELINES.md  # Development practices and commit standards
├── extract-scripts.sh         # Helper script to extract optional scripts
├── .gitignore                 # Git ignore rules
├── .terraform.lock.hcl        # Terraform dependency lock file
└── terraform.tfstate*         # Terraform state files
```

### Inlined Scripts in `main.tf`

All installation scripts are now inlined using Terraform `locals`:

- `local.install_archivesspace` - Core ArchivesSpace installation
- `local.install_fedora` - Fedora digital repository setup
- `local.install_fedora_integration` - Integration between ArchivesSpace and Fedora
- `local.load_demo_data` - Demo data loading (available as output)
- `local.setup_digital_objects` - Digital objects configuration (available as output)

## Troubleshooting

### Common Issues

1. **502 Bad Gateway on first access:**

   - ArchivesSpace takes 5-10 minutes to fully start on first deployment
   - Check container status: `docker compose ps`
   - Monitor logs: `docker compose logs app`

2. **Container health issues:**

   ```bash
   ssh azureuser@<PUBLIC_IP>
   cd ~/archivesspace/archivesspace
   docker compose restart
   ```

3. **Port access issues:**
   - Verify Azure NSG rules are applied
   - Check if services are listening: `ss -tlnp`

### Useful Commands

```bash
# Check container status
docker compose ps

# View logs
docker compose logs app
docker compose logs mysql
docker compose logs solr

# Restart services
docker compose restart

# Access ArchivesSpace shell
docker compose exec app bash

# Backup database
docker compose exec db mysqldump -u root -p archivesspace > backup.sql

# Check Fedora status
cd ~/fedora
docker compose ps
```

## Benefits of Inlined Scripts

✅ **Single File**: All configuration in one `main.tf` file  
✅ **Version Control**: Scripts are versioned with Terraform code  
✅ **No File Dependencies**: No external .sh files to manage  
✅ **Easier Deployment**: One command deploys everything  
✅ **Better Portability**: Self-contained configuration  
✅ **Consistent Execution**: Scripts are always in sync with infrastructure

## Cleanup

To destroy the deployment:

```bash
terraform destroy -auto-approve
```

## Security Notes

⚠️ **Important Security Considerations:**

- This is a demo configuration with relaxed security for testing
- For production use:
  - Restrict NSG rules to specific IP ranges
  - Use Azure Key Vault for secrets
  - Enable Azure Backup
  - Configure SSL/TLS certificates
  - Use Azure Application Gateway for load balancing
  - Implement proper monitoring and logging

## Contributing

Please read [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) before contributing to understand our development practices and commit standards.

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.

# ArchiveSpaces

Archive mgmt

> > > > > > > f5dade704b34907e3ad514ab80200ee8ff01e821
