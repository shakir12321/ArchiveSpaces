#!/bin/bash

echo "Setting up file upload interface for ArchivesSpace..."

# Create upload directory
sudo mkdir -p /var/www/uploads
sudo chown azureuser:azureuser /var/www/uploads
sudo chmod 755 /var/www/uploads

# Create a simple upload interface
cat > /var/www/uploads/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>File Upload for ArchivesSpace</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .upload-form { border: 2px dashed #ccc; padding: 20px; margin: 20px 0; }
        .file-list { margin-top: 20px; }
        .file-item { padding: 10px; border-bottom: 1px solid #eee; }
        .file-url { font-family: monospace; background: #f5f5f5; padding: 5px; }
    </style>
</head>
<body>
    <h1>File Upload for ArchivesSpace</h1>
    
    <div class="upload-form">
        <h3>Upload Files</h3>
        <form action="/cgi-bin/upload.cgi" method="post" enctype="multipart/form-data">
            <input type="file" name="file" multiple>
            <input type="submit" value="Upload Files">
        </form>
    </div>

    <div class="file-list">
        <h3>Uploaded Files</h3>
        <p>Use these URLs in ArchivesSpace File URI field:</p>
        <div id="fileList">
            <!-- Files will be listed here -->
        </div>
    </div>

    <script>
        // Simple file listing (you can enhance this)
        fetch('/cgi-bin/list.cgi')
            .then(response => response.text())
            .then(data => {
                document.getElementById('fileList').innerHTML = data;
            });
    </script>
</body>
</html>
EOF

# Create upload CGI script
cat > /var/www/uploads/cgi-bin/upload.cgi << 'EOF'
#!/bin/bash
echo "Content-type: text/html"
echo ""

UPLOAD_DIR="/var/www/uploads/files"
mkdir -p $UPLOAD_DIR

# Get the uploaded file
if [ "$REQUEST_METHOD" = "POST" ]; then
    # Parse the multipart form data
    boundary=$(echo "$CONTENT_TYPE" | sed 's/.*boundary=//')
    
    # Save uploaded file
    filename=$(date +%s)_$(basename "$QUERY_STRING")
    cat > "$UPLOAD_DIR/$filename"
    
    echo "<html><body>"
    echo "<h2>File uploaded successfully!</h2>"
    echo "<p>File: $filename</p>"
    echo "<p>URL: http://$(hostname -I | awk '{print $1}')/uploads/files/$filename</p>"
    echo "<a href='/uploads/'>Back to upload page</a>"
    echo "</body></html>"
else
    echo "<html><body><h2>Invalid request method</h2></body></html>"
fi
EOF

# Create file listing CGI script
cat > /var/www/uploads/cgi-bin/list.cgi << 'EOF'
#!/bin/bash
echo "Content-type: text/html"
echo ""

UPLOAD_DIR="/var/www/uploads/files"
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "<h4>Available Files:</h4>"
if [ -d "$UPLOAD_DIR" ]; then
    for file in "$UPLOAD_DIR"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "<div class='file-item'>"
            echo "<strong>$filename</strong><br>"
            echo "<span class='file-url'>http://$SERVER_IP/uploads/files/$filename</span>"
            echo "</div>"
        fi
    done
else
    echo "<p>No files uploaded yet.</p>"
fi
EOF

# Make scripts executable
chmod +x /var/www/uploads/cgi-bin/upload.cgi
chmod +x /var/www/uploads/cgi-bin/list.cgi

# Create nginx configuration for uploads
cat > /etc/nginx/sites-available/uploads << 'EOF'
server {
    listen 8080;
    server_name _;
    
    location /uploads/ {
        alias /var/www/uploads/;
        autoindex on;
    }
    
    location /cgi-bin/ {
        alias /var/www/uploads/cgi-bin/;
        cgi_pass unix:/var/run/fcgiwrap.socket;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/uploads /etc/nginx/sites-enabled/
systemctl reload nginx

echo "File upload interface setup complete!"
echo "Access upload interface at: http://$(hostname -I | awk '{print $1}'):8080/uploads/"
echo ""
echo "Instructions:"
echo "1. Upload files using the web interface"
echo "2. Copy the generated URLs"
echo "3. Use those URLs in ArchivesSpace File URI field" 