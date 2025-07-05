<<<<<<< HEAD
# ArchivesSpace Azure Deployment

This repository contains Terraform configuration to deploy ArchivesSpace v4.1.1 on Azure using the official Docker configuration package.

## Overview

This setup deploys ArchivesSpace following the [official ArchivesSpace Docker documentation](https://docs.archivesspace.org/administration/docker/) on an Azure VM with:

- **ArchivesSpace v4.1.1** - Latest stable version
- **MySQL 8** - Database backend
- **Solr 4.1.1** - Search engine
- **Nginx** - Reverse proxy
- **Automated backups** - Database backup service

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
   - Solr Admin: `http://<PUBLIC_IP>:8983/solr/`

## Architecture

```
Internet
    ↓
Azure Load Balancer (port 80)
    ↓
Ubuntu VM (Standard_B2s)
    ↓
Docker Compose
    ├── ArchivesSpace App (port 8080)
    ├── MySQL Database (port 3306)
    ├── Solr Search (port 8983)
    ├── Nginx Proxy (port 80)
    └── Backup Service
```

## Configuration Details

### VM Specifications

- **Size**: Standard_B2s (2 vCPUs, 4 GB RAM)
- **OS**: Ubuntu 20.04 LTS
- **Location**: East US

### Network Security

- **SSH**: Port 22 (for management)
- **HTTP**: Port 80 (ArchivesSpace web interface)
- **Additional ports**: 8080, 8081, 8089, 8983, 3306 (for services)

### ArchivesSpace Configuration

- Uses official Docker configuration package from GitHub releases
- Automatic database initialization and migrations
- Secure default passwords (should be changed after deployment)
- Nginx reverse proxy for web access

## Post-Deployment Steps

1. **Change default passwords:**

   - Access the staff interface at `http://<PUBLIC_IP>/staff/`
   - Default credentials: `admin` / `admin`
   - Change passwords immediately

2. **Configure ArchivesSpace:**

   - Set up repositories
   - Configure user accounts
   - Import data as needed

3. **Monitor the deployment:**
   ```bash
   ssh azureuser@<PUBLIC_IP>
   cd ~/archivesspace/archivesspace
   docker compose ps
   docker compose logs
   ```

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
```

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

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License.
=======
# ArchiveSpaces
Archive mgmt 
>>>>>>> f5dade704b34907e3ad514ab80200ee8ff01e821
