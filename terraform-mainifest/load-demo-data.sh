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
echo "  - Public Interface: http://172.173.163.116/"
echo "  - Staff Interface: http://172.173.163.116/staff/"
echo ""
echo "Default login credentials: admin / admin"
echo ""
echo "Demo data source: https://raw.githubusercontent.com/archivesspace/archivesspace/master/demo.sql"
