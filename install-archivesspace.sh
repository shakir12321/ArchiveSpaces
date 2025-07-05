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

# Extract the configuration package
echo "Extracting configuration package..."
unzip archivesspace-docker.zip
rm archivesspace-docker.zip

# Set proper ownership
chown -R azureuser:azureuser /home/azureuser/archivesspace

# Update the .env file with secure passwords
echo "Configuring environment variables..."
cat > .env <<EOF
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
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "Not responding"
echo ""

echo "Testing staff interface (port 80/staff/):"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/staff/ || echo "Not responding"
echo ""

echo "5. Direct ArchivesSpace ports (for debugging):"
echo "Testing staff interface (port 8080):"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080 || echo "Not responding"
echo ""

echo "Testing public interface (port 8081):"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8081 || echo "Not responding"
echo ""

echo "Testing API (port 8089):"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8089 || echo "Not responding"
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
``` 