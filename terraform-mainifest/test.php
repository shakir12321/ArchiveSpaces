<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'success',
    'message' => 'PHP is working!',
    'php_version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'unknown'
]);
?> 