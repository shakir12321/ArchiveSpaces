<?php
header('Content-Type: application/json');

$uploadDir = __DIR__ . '/files/';
$files = [];

if (is_dir($uploadDir)) {
    $fileList = scandir($uploadDir);
    
    foreach ($fileList as $file) {
        if ($file !== '.' && $file !== '..' && is_file($uploadDir . $file)) {
            $filePath = $uploadDir . $file;
            $fileInfo = pathinfo($file);
            
            // Extract original name from timestamp_filename format
            $originalName = $file;
            if (preg_match('/^\d+_(.+)$/', $file, $matches)) {
                $originalName = $matches[1];
            }
            
            $files[] = [
                'name' => $originalName,
                'filename' => $file,
                'url' => 'http://' . $_SERVER['HTTP_HOST'] . '/uploads/files/' . $file,
                'size' => filesize($filePath),
                'modified' => filemtime($filePath)
            ];
        }
    }
}

echo json_encode(['files' => $files]);
?> 