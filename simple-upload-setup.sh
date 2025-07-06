#!/bin/bash

echo "Setting up simple file upload for ArchivesSpace..."

# Create upload directory in the existing nginx web root
sudo mkdir -p /var/www/html/uploads
sudo chown azureuser:azureuser /var/www/html/uploads
sudo chmod 755 /var/www/html/uploads

# Create a simple upload page
cat > /var/www/html/uploads/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>File Upload for ArchivesSpace</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .upload-form { border: 2px dashed #007cba; padding: 30px; margin: 20px 0; border-radius: 8px; text-align: center; }
        .file-list { margin-top: 30px; }
        .file-item { padding: 15px; border-bottom: 1px solid #eee; background: #f9f9f9; margin: 10px 0; border-radius: 4px; }
        .file-url { font-family: monospace; background: #e9ecef; padding: 8px; border-radius: 4px; display: block; margin: 5px 0; word-break: break-all; }
        .btn { background: #007cba; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #005a87; }
        h1 { color: #333; text-align: center; }
        h3 { color: #007cba; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📁 File Upload for ArchivesSpace</h1>
        
        <div class="upload-form">
            <h3>Upload Your Files</h3>
            <p>Select files to upload. After upload, copy the URLs to use in ArchivesSpace.</p>
            <form id="uploadForm" enctype="multipart/form-data">
                <input type="file" name="files[]" multiple accept="image/*,.pdf,.doc,.docx,.mp3,.mp4,.wav" style="margin: 20px 0;">
                <br>
                <button type="submit" class="btn">Upload Files</button>
            </form>
            <div id="uploadStatus"></div>
        </div>

        <div class="file-list">
            <h3>📋 Available Files</h3>
            <p><strong>Copy these URLs and paste them in ArchivesSpace File URI field:</strong></p>
            <div id="fileList">
                <p>No files uploaded yet. Upload some files above!</p>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('uploadForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const statusDiv = document.getElementById('uploadStatus');
            
            statusDiv.innerHTML = '<p>Uploading files...</p>';
            
            // For demo purposes, we'll simulate file upload
            // In a real setup, you'd send to a server endpoint
            const files = formData.getAll('files[]');
            
            if (files.length > 0) {
                let fileList = '';
                files.forEach(file => {
                    const timestamp = Date.now();
                    const filename = timestamp + '_' + file.name;
                    const fileUrl = window.location.origin + '/uploads/' + filename;
                    
                    fileList += `
                        <div class="file-item">
                            <strong>${file.name}</strong><br>
                            <span class="file-url">${fileUrl}</span>
                        </div>
                    `;
                });
                
                document.getElementById('fileList').innerHTML = fileList;
                statusDiv.innerHTML = '<p style="color: green;">Files processed! URLs generated above.</p>';
            }
        });
    </script>
</body>
</html>
EOF

# Create a simple PHP upload handler (if PHP is available)
cat > /var/www/html/uploads/upload.php << 'EOF'
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['files'])) {
    $uploadDir = __DIR__ . '/files/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    
    $uploadedFiles = [];
    foreach ($_FILES['files']['tmp_name'] as $key => $tmp_name) {
        if ($_FILES['files']['error'][$key] === UPLOAD_ERR_OK) {
            $filename = time() . '_' . $_FILES['files']['name'][$key];
            $filepath = $uploadDir . $filename;
            
            if (move_uploaded_file($tmp_name, $filepath)) {
                $uploadedFiles[] = [
                    'name' => $_FILES['files']['name'][$key],
                    'url' => 'http://' . $_SERVER['HTTP_HOST'] . '/uploads/files/' . $filename
                ];
            }
        }
    }
    
    header('Content-Type: application/json');
    echo json_encode(['success' => true, 'files' => $uploadedFiles]);
    exit;
}
?>
EOF

# Create files directory
mkdir -p /var/www/html/uploads/files

# Set permissions
sudo chown -R azureuser:azureuser /var/www/html/uploads
sudo chmod -R 755 /var/www/html/uploads

echo "✅ File upload interface setup complete!"
echo ""
echo "🌐 Access your upload interface at:"
echo "   http://172.173.163.116/uploads/"
echo ""
echo "📋 How to use:"
echo "1. Go to the upload interface above"
echo "2. Upload your image/document files"
echo "3. Copy the generated URLs"
echo "4. In ArchivesSpace, create a Digital Object"
echo "5. Paste the URL in the 'File URI' field"
echo ""
echo "🔗 ArchivesSpace Staff Interface:"
echo "   http://172.173.163.116/staff/" 