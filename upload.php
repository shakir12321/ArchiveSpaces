<?php
// Fedora Upload Handler
// This script receives file uploads and uses the Python script to upload to Fedora

header('Content-Type: application/json');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Log the request details
error_log("Upload request received: " . json_encode([
    'method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'not set',
    'has_files' => isset($_FILES['file']),
    'files_count' => count($_FILES),
    'post_count' => count($_POST)
]));

// Check if file was uploaded
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $error_details = [
        'error' => 'No file uploaded or upload error',
        'files_present' => isset($_FILES['file']),
        'upload_error' => $_FILES['file']['error'] ?? 'no file',
        'upload_errors' => [
            UPLOAD_ERR_OK => 'No error',
            UPLOAD_ERR_INI_SIZE => 'File exceeds upload_max_filesize',
            UPLOAD_ERR_FORM_SIZE => 'File exceeds MAX_FILE_SIZE',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'A PHP extension stopped the file upload'
        ]
    ];
    
    // Log the error details
    error_log("Upload error details: " . json_encode($error_details));
    
    http_response_code(400);
    echo json_encode($error_details);
    exit;
}

$uploadedFile = $_FILES['file'];
$fileName = $uploadedFile['name'];
$tempPath = $uploadedFile['tmp_name'];

// Log file details
error_log("File details: " . json_encode([
    'name' => $fileName,
    'temp_path' => $tempPath,
    'size' => $uploadedFile['size'],
    'error' => $uploadedFile['error']
]));

// Validate file
if (!is_uploaded_file($tempPath)) {
    $error_details = [
        'error' => 'Invalid file upload',
        'temp_path' => $tempPath,
        'file_exists' => file_exists($tempPath),
        'is_uploaded_file' => is_uploaded_file($tempPath)
    ];
    
    error_log("Invalid file upload: " . json_encode($error_details));
    
    http_response_code(400);
    echo json_encode($error_details);
    exit;
}

// Create uploads directory if it doesn't exist
$uploadsDir = '/var/www/html/uploads';
if (!is_dir($uploadsDir)) {
    mkdir($uploadsDir, 0755, true);
}

// Move file to uploads directory
$targetPath = $uploadsDir . '/' . $fileName;
if (!move_uploaded_file($tempPath, $targetPath)) {
    $error_details = [
        'error' => 'Failed to save uploaded file',
        'temp_path' => $tempPath,
        'target_path' => $targetPath,
        'uploads_dir_exists' => is_dir($uploadsDir),
        'uploads_dir_writable' => is_writable($uploadsDir)
    ];
    
    error_log("Failed to save file: " . json_encode($error_details));
    
    http_response_code(500);
    echo json_encode($error_details);
    exit;
}

// Run the Python script to upload to Fedora
$command = "cd /var/www/html && python3 fedora-upload.py " . escapeshellarg($targetPath) . " 2>&1";
$output = shell_exec($command);

// Log the Python output
error_log("Python script output: " . $output);

// Check if upload was successful
if (strpos($output, '✅ File uploaded successfully!') !== false) {
    // Extract Fedora URI from output
    preg_match('/🔗 Fedora URI: (.*)/', $output, $matches);
    $fedoraUri = trim($matches[1] ?? '');
    
    // Convert localhost to the external IP for the Fedora URI
    $fedoraUri = str_replace('http://localhost:8086', 'http://172.173.163.116:8086', $fedoraUri);
    
    $success_response = [
        'success' => true,
        'message' => 'File uploaded to Fedora successfully!',
        'fedora_uri' => $fedoraUri,
        'file_name' => $fileName,
        'output' => $output
    ];
    
    error_log("Upload successful: " . json_encode($success_response));
    echo json_encode($success_response);
} else {
    $error_response = [
        'error' => 'Failed to upload to Fedora',
        'output' => $output,
        'command' => $command
    ];
    
    error_log("Fedora upload failed: " . json_encode($error_response));
    
    http_response_code(500);
    echo json_encode($error_response);
}
?> 