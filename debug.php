<?php
// Debug script to see what's being sent
header('Content-Type: application/json');

$debug_info = [
    'method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'not set',
    'has_files' => isset($_FILES['file']),
    'files_count' => count($_FILES),
    'post_count' => count($_POST),
    'file_details' => $_FILES['file'] ?? 'no file',
    'post_data' => $_POST,
    'server_vars' => [
        'HTTP_USER_AGENT' => $_SERVER['HTTP_USER_AGENT'] ?? 'not set',
        'HTTP_ACCEPT' => $_SERVER['HTTP_ACCEPT'] ?? 'not set',
        'CONTENT_LENGTH' => $_SERVER['CONTENT_LENGTH'] ?? 'not set'
    ],
    'all_files' => $_FILES,
    'all_post' => $_POST,
    'raw_input' => file_get_contents('php://input')
];

// If this is a POST request, also test the upload.php logic
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $debug_info['upload_test'] = [
        'file_exists' => file_exists($_FILES['file']['tmp_name']),
        'is_uploaded_file' => is_uploaded_file($_FILES['file']['tmp_name']),
        'upload_error' => $_FILES['file']['error'],
        'file_size' => $_FILES['file']['size']
    ];
}

echo json_encode($debug_info, JSON_PRETTY_PRINT);
?> 