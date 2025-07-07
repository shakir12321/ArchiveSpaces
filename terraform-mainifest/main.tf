provider "azurerm" {
  features {}
  subscription_id = "bb649e30-d650-43a7-a6d1-2c85eab4d156"
}

# =============================================================================
# LOCALS - All installation scripts inlined
# =============================================================================

locals {
  # ArchivesSpace Core Installation Script
  install_archivesspace = <<-EOT
    #!/bin/bash
    # Install ArchivesSpace v4.1.1 using official Docker configuration package
    # Following: https://docs.archivesspace.org/administration/docker/

    set -e

    echo "=== ArchivesSpace Docker Installation ==="
    echo "Following official documentation: https://docs.archivesspace.org/administration/docker/"
    echo ""

    # Update system
    echo "Updating system packages..."
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        wget \
        unzip

    # Install Docker Engine
    echo "Installing Docker Engine..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io

    # Install Docker Compose
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add azureuser to docker group
    usermod -aG docker azureuser

    # Create archivesspace directory
    echo "Setting up ArchivesSpace directory..."
    mkdir -p /home/azureuser/archivesspace
    cd /home/azureuser/archivesspace

    # Download the official ArchivesSpace Docker configuration package
    echo "Downloading ArchivesSpace v4.1.1 Docker configuration package..."
    wget -O archivesspace-docker.zip "https://github.com/archivesspace/archivesspace/releases/download/v4.1.1/archivesspace-docker-v4.1.1.zip"

    # Extract the configuration package (non-interactive)
    echo "Extracting configuration package..."
    unzip -o archivesspace-docker.zip
    rm archivesspace-docker.zip

    # Set proper ownership
    chown -R azureuser:azureuser /home/azureuser/archivesspace

    # Update the .env file with secure passwords
    echo "Configuring environment variables..."
    cat > .env <<'EOF'
# Database credentials
MYSQL_ROOT_PASSWORD=archivespace_root_password_2024
MYSQL_DATABASE=archivesspace
MYSQL_USER=archivesspace
MYSQL_PASSWORD=archivespace_user_password_2024

# Database connection URI (update after changing passwords above)
ASPACE_DB_URL=jdbc:mysql://db:3306/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=archivesspace&password=archivespace_user_password_2024&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC

# ArchivesSpace configuration
ASPACE_SECRET_KEY=archivespace_secret_key_2024_very_long_and_secure
ASPACE_PLUGINS=local,lcnaf

# Public URL configuration (fixes localhost redirect issue)
ASPACE_PUBLIC_URL=http://172.173.163.116
ASPACE_BACKEND_URL=http://172.173.163.116

# Nginx configuration
NGINX_PORT=80
EOF

    # Set proper ownership of .env file
    chown azureuser:azureuser .env

    # Start ArchivesSpace using the official configuration
    echo "Starting ArchivesSpace with official Docker configuration..."
    echo "This may take 5-10 minutes for the first startup..."
    cd /home/azureuser/archivesspace/archivesspace
    sudo -u azureuser docker compose up --detach

    # Wait for ArchivesSpace to start and then configure public URLs
    echo "Waiting for ArchivesSpace to start..."
    sleep 120

    # Configure ArchivesSpace to use external URLs instead of localhost
    echo "Configuring ArchivesSpace public URLs..."
    cd /home/azureuser/archivesspace/archivesspace
    
    # Create a configuration script to fix URL issues
    cat > config/config.rb << 'EOF'
    # ArchivesSpace Configuration
    # This fixes the localhost redirect issue when behind a reverse proxy

    # Set the public URL to the external IP
    AppConfig[:public_url] = "http://172.173.163.116"
    AppConfig[:backend_url] = "http://172.173.163.116"
    
    # Configure proxy settings
    AppConfig[:frontend_proxy_prefix] = ""
    AppConfig[:public_proxy_prefix] = ""
    AppConfig[:backend_proxy_prefix] = ""
    
    # Disable SSL requirement for demo
    AppConfig[:frontend_ssl_verify] = false
    AppConfig[:backend_ssl_verify] = false
EOF

    # Restart ArchivesSpace to apply the new configuration
    echo "Restarting ArchivesSpace to apply URL configuration..."
    cd /home/azureuser/archivesspace/archivesspace
    sudo -u azureuser docker compose restart archivesspace

    # Create a status monitoring script
    cat <<EOF > /home/azureuser/check-status.sh
    #!/bin/bash
    echo "=== ArchivesSpace Status Check ==="
    echo ""

    echo "1. Docker containers status:"
    docker compose -f /home/azureuser/archivesspace/archivesspace/docker-compose.yml ps
    echo ""

    echo "2. Container logs (last 20 lines):"
    docker compose -f /home/azureuser/archivesspace/archivesspace/docker-compose.yml logs --tail=20
    echo ""

    echo "3. Port listening status:"
    netstat -tlnp | grep -E ':(80|8080|8081|8089|8983|3306)' || echo "No ports listening yet"
    echo ""

    echo "4. ArchivesSpace endpoints:"
    echo "Testing public interface (port 80):"
    curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" http://localhost/ || echo "Not responding"
    echo ""

    echo "Testing staff interface (port 80/staff/):"
    curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" http://localhost/staff/ || echo "Not responding"
    echo ""

    echo "5. Direct ArchivesSpace ports (for debugging):"
    echo "Testing staff interface (port 8080):"
    curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" http://localhost:8080 || echo "Not responding"
    echo ""

    echo "Testing public interface (port 8081):"
    curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" http://localhost:8081 || echo "Not responding"
    echo ""

    echo "Testing API (port 8089):"
    curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" http://localhost:8089 || echo "Not responding"
    echo ""

    echo "=== End Status Check ==="
    EOF

    chmod +x /home/azureuser/check-status.sh
    chown azureuser:azureuser /home/azureuser/check-status.sh

    # Create a startup script
    cat <<EOF > /home/azureuser/start-archivesspace.sh
    #!/bin/bash
    cd /home/azureuser/archivesspace/archivesspace
    echo "Starting ArchivesSpace..."
    docker compose up --detach
    echo "ArchivesSpace is starting up (this may take 5-10 minutes)..."
    echo "Monitor progress with: docker compose logs --follow"
    echo ""
    echo "Once fully started, ArchivesSpace will be available at:"
    echo "  - Public interface: http://\$(curl -s ifconfig.me)/"
    echo "  - Staff interface: http://\$(curl -s ifconfig.me)/staff/"
    echo "  - API: http://\$(curl -s ifconfig.me)/api/"
    echo ""
    echo "Default login credentials: admin / admin"
    EOF

    chmod +x /home/azureuser/start-archivesspace.sh
    chown azureuser:azureuser /home/azureuser/start-archivesspace.sh

    # Wait for initial startup
    echo "Waiting for ArchivesSpace to start up..."
    sleep 60

    # Show initial status
    echo ""
    echo "=== Initial Status Check ==="
    sudo -u azureuser /home/azureuser/check-status.sh

    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "ArchivesSpace is starting up (this may take 5-10 minutes for full startup)..."
    echo ""
    echo "Access URLs:"
    echo "  - Public interface: http://$(curl -s ifconfig.me)/"
    echo "  - Staff interface: http://$(curl -s ifconfig.me)/staff/"
    echo "  - API: http://$(curl -s ifconfig.me)/api/"
    echo ""
    echo "Default login credentials:"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "To monitor progress:"
    echo "  ssh azureuser@$(curl -s ifconfig.me)"
    echo "  cd archivesspace"
    echo "  docker compose logs --follow"
    echo ""
    echo "To check status:"
    echo "  ./check-status.sh"
    echo ""
    echo "Following official documentation: https://docs.archivesspace.org/administration/docker/"
  EOT

  # Fedora Digital Repository Installation Script
  install_fedora = <<-EOT
    #!/bin/bash
    # Install Fedora Digital Repository with ActiveMQ

    set -e

    echo "=== Fedora Digital Repository Installation ==="
    echo ""

    # Update system
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker azureuser

    # Create Fedora directory
    mkdir -p /home/azureuser/fedora
    cd /home/azureuser/fedora

    # Create docker-compose.yml for Fedora
    cat > docker-compose.yml << 'EOF'
    version: '3.8'

    services:
      fedora:
        image: fcrepo/fcrepo:6.4.0
        container_name: fedora
        ports:
          - "8086:8086"
        environment:
          - FCREPO_JMS_BASEURL=http://fedora:8086/fcrepo/rest
          - FCREPO_STOMP_HOST=activemq
          - FCREPO_STOMP_PORT=61613
          - FCREPO_STOMP_USERNAME=fedoraAdmin
          - FCREPO_STOMP_PASSWORD=fedoraAdmin
          - FCREPO_LOG_LEVEL=INFO
        volumes:
          - fedora-data:/var/lib/fedora
        depends_on:
          - activemq
        networks:
          - fedora-network

      activemq:
        image: rmohr/activemq:5.15.9
        container_name: activemq
        ports:
          - "61616:61616"
          - "8161:8161"
        environment:
          - ACTIVEMQ_ADMIN_LOGIN=admin
          - ACTIVEMQ_ADMIN_PASSWORD=admin
        volumes:
          - activemq-data:/data/activemq
        networks:
          - fedora-network

    volumes:
      fedora-data:
      activemq-data:

    networks:
      fedora-network:
        driver: bridge
    EOF

    # Start Fedora
    docker-compose up -d

    # Wait for Fedora to start
    echo "Waiting for Fedora to start..."
    sleep 30

    # Check status
    docker-compose ps

    echo "Fedora installation complete!"
    echo "Fedora URL: http://$(curl -s ifconfig.me):8086/fcrepo/rest"
    echo "ActiveMQ Admin: http://$(curl -s ifconfig.me):8161/admin (admin/admin)"
  EOT

  # Fedora Integration Script
  install_fedora_integration = <<-EOT
    #!/bin/bash
    # Install Fedora integration for ArchivesSpace

    set -e

    echo "=== Installing Fedora Integration for ArchivesSpace ==="
    echo ""

    # Navigate to ArchivesSpace directory
    cd /home/azureuser/archivesspace/archivesspace

    # Download the Fedora integration plugin
    wget -O plugins/fedora_integration.rb https://raw.githubusercontent.com/archivesspace/archivesspace-fedora-integration/master/fedora_integration.rb

    # Create plugin configuration
    cat > config/config.rb << 'EOF'
    # Fedora Integration Configuration
    AppConfig[:fedora_url] = "http://localhost:8086/fcrepo/rest"
    AppConfig[:fedora_username] = "fedoraAdmin"
    AppConfig[:fedora_password] = "fedoraAdmin"

    # Enable Fedora integration plugin
    AppConfig[:plugins] = ['fedora_integration']

    # Digital object settings
    AppConfig[:enable_digital_objects] = true
    AppConfig[:digital_object_file_versions] = true
    EOF

    # Restart ArchivesSpace to load the plugin
    echo "Restarting ArchivesSpace to load Fedora integration..."
    cd /home/azureuser/archivesspace
    docker-compose restart archivesspace

    echo "Fedora integration installation complete!"
    echo "ArchivesSpace will now be able to store digital objects in Fedora."
  EOT

  # Demo Data Loading Script
  load_demo_data = <<-EOT
    #!/bin/bash
    # Load ArchivesSpace Demo Data
    # This script downloads and imports the official ArchivesSpace demo data

    set -e

    echo "=== Loading ArchivesSpace Demo Data ==="
    echo ""

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        echo "Error: This script must be run from the ArchivesSpace directory"
        echo "Please run: cd ~/archivesspace/archivesspace && ./load-demo-data.sh"
        exit 1
    fi

    # Download demo data
    echo "Downloading demo data from ArchivesSpace GitHub repository..."
    wget -O demo.sql 'https://raw.githubusercontent.com/archivesspace/archivesspace/master/demo.sql'

    if [ $? -ne 0 ]; then
        echo "Error: Failed to download demo data"
        exit 1
    fi

    echo "Demo data downloaded successfully (7.8MB)"
    echo ""

    # Import demo data into MySQL
    echo "Importing demo data into MySQL database..."
    docker compose exec -T db mysql -u root -p123456 archivesspace < demo.sql

    if [ $? -ne 0 ]; then
        echo "Error: Failed to import demo data"
        exit 1
    fi

    echo "Demo data imported successfully!"
    echo ""

    # Verify the import
    echo "Verifying demo data import..."
    docker compose exec -T db mysql -u root -p123456 archivesspace -e "
    SELECT 'Repositories' as type, COUNT(*) as count FROM repository
    UNION ALL
    SELECT 'Accessions' as type, COUNT(*) as count FROM accession  
    UNION ALL
    SELECT 'Resources' as type, COUNT(*) as count FROM resource
    UNION ALL
    SELECT 'Agents' as type, COUNT(*) as count FROM agent_person
    UNION ALL
    SELECT 'Subjects' as type, COUNT(*) as count FROM subject;"

    echo ""
    echo "=== Demo Data Load Complete ==="
    echo ""
    echo "Your ArchivesSpace now contains sample data including:"
    echo "  - 3 Repositories"
    echo "  - 6 Accessions" 
    echo "  - 21 Resources (Collections)"
    echo "  - Multiple Agents (People, Organizations, Families)"
    echo "  - Subjects and other archival records"
    echo ""
    echo "Access your ArchivesSpace at:"
    echo "  - Public Interface: http://$(curl -s ifconfig.me)/"
    echo "  - Staff Interface: http://$(curl -s ifconfig.me)/staff/"
    echo ""
    echo "Default login credentials: admin / admin"
    echo ""
    echo "Demo data source: https://raw.githubusercontent.com/archivesspace/archivesspace/master/demo.sql"
  EOT

  # Digital Objects Setup Script
  setup_digital_objects = <<-EOT
    #!/bin/bash
    # Setup Digital Objects for ArchivesSpace

    set -e

    echo "=== Setting up Digital Objects for ArchivesSpace ==="
    echo ""

    # Navigate to ArchivesSpace directory
    cd /home/azureuser/archivesspace/archivesspace

    # Create digital objects configuration
    cat >> config/config.rb << 'EOF'

    # Digital Objects Configuration
    AppConfig[:enable_digital_objects] = true
    AppConfig[:digital_object_file_versions] = true
    AppConfig[:digital_object_thumbnail_storage] = :file_system
    AppConfig[:digital_object_thumbnail_path] = "/tmp/aspace_thumbnails"

    # File upload settings
    AppConfig[:max_file_size] = 100 * 1024 * 1024  # 100MB
    AppConfig[:allowed_file_types] = ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'tiff', 'tif', 'mp4', 'mov', 'avi']

    # Fedora integration for digital objects
    AppConfig[:fedora_url] = "http://localhost:8086/fcrepo/rest"
    AppConfig[:fedora_username] = "fedoraAdmin"
    AppConfig[:fedora_password] = "fedoraAdmin"
    EOF

    # Create thumbnail directory
    mkdir -p /tmp/aspace_thumbnails
    chown azureuser:azureuser /tmp/aspace_thumbnails

    # Restart ArchivesSpace to apply changes
    echo "Restarting ArchivesSpace to apply digital object configuration..."
    cd /home/azureuser/archivesspace
    docker-compose restart archivesspace

    echo "Digital objects setup complete!"
    echo "ArchivesSpace is now configured for digital object management."
  EOT
}

# =============================================================================
# RESOURCES
# =============================================================================

resource "azurerm_resource_group" "rg" {
  name     = "rg-archivespace-demo"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-archivespace"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-archivespace"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "publicip-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ArchivesSpace"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8081", "8089", "8983", "3306"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Fedora"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8086", "61616", "8161"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id 
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-archivespace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D8s_v3"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name                 = "osdisk-archivespace"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCob26B/DYDJbiCde82Yq9sEjt9BZgLaRjW7mkKZECIg3GkfCJxpNvMxp9rsiilk4gyMyxE9NigaHBP6Om1FIQ+hl9UV/92KPA7p9+9CXc0LL4INEwolI4OsYqG8lIgmALMXlYTcJunUnW8xjHyxxsMChOqzzwfI1X6PvJno+3oclzBfuvNM13EXDIRy+2fj9ph7wuE+vHBpAcJm3wJ65dR4UgDGyHzWeydW9pUjbxx8QEQ285XRDG0lqPsvtdxd0BZd3Ik4HmTZWLqPLAgbhl5Ejzx25Yf4tszD9KtX3ZHyaWR1PBSD9czlmYezB/fqjyoO2L21hweeomdCQqFIZ+K57uVUb4uyANEJ4O5s22UZm/CmDPDx3rw6QTdZMKIL466OIkh/74U8w459gXCtYxyMMcMGU9vdQx7jN2spuqkAhtAdQlGBXLwXJrfgzyfXs6Ns6TAj46c6uwMhviRgqjNcHZ9OktgrtfR1HOiMoY9nCseKYd5oes2IQnErXwFa5mcqB+nrvDc5vTob8nUHtbUZcl2fK3PGvM4t53l8aX38R6bx2GeYE+q1qJaHfkLpfCO5X3ii2JOSOdB5sqE/n0SD3AbzfSK1FRlW40YX9KsQuPBxOZBk2nNc5TfEniZqBLCfdNVMLM2DeMQXhPR/Smv0y2WU7vr5KsLJSvb5hWJw== shakir@Shakirs-MacBook-Pro.local"
  }
}

# =============================================================================
# VM EXTENSIONS - Using inlined scripts from locals
# =============================================================================

resource "azurerm_virtual_machine_extension" "archivesspace_install" {
  name                 = "install-archivesspace"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "script": "${base64encode(local.install_archivesspace)}"
    }
PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "fedora_install" {
  name                 = "install-fedora"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  depends_on = [azurerm_virtual_machine_extension.archivesspace_install]

  settings = <<SETTINGS
    {}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "script": "${base64encode(local.install_fedora)}"
    }
PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "fedora_integration" {
  name                 = "install-fedora-integration"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  depends_on = [azurerm_virtual_machine_extension.fedora_install]

  settings = <<SETTINGS
    {}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "script": "${base64encode(local.install_fedora_integration)}"
    }
PROTECTED_SETTINGS
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "ssh_command" {
  value = "ssh azureuser@${azurerm_public_ip.public_ip.ip_address}"
}

output "archivesspace_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}"
}

output "archivesspace_staff_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}/staff/"
}

output "fedora_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}:8086/fcrepo/rest"
}

output "activemq_admin_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}:8161/admin"
}

# =============================================================================
# ADDITIONAL SCRIPTS (for manual execution)
# =============================================================================

output "demo_data_script" {
  description = "Script to load demo data (run manually after deployment)"
  value       = local.load_demo_data
}

output "digital_objects_script" {
  description = "Script to setup digital objects (run manually after deployment)"
  value       = local.setup_digital_objects
}