<?php

// Validasi input
if (empty($_POST['image'])) {
    http_response_code(400);
    echo json_encode(['error' => 'No image data received', 'success' => false]);
    exit();
}

// Buat folder capture jika belum ada
$captureDir = 'capture';
if (!is_dir($captureDir)) {
    if (!mkdir($captureDir, 0755, true)) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create capture directory', 'success' => false]);
        exit();
    }
}

// Ambil data image dari POST
$imageData = $_POST['image'];

// Validasi format data URL
if (strpos($imageData, 'data:image') === false) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid image format', 'success' => false]);
    exit();
}

// Extract base64 data dari data URL
$filteredData = substr($imageData, strpos($imageData, ",") + 1);

// Decode base64
$unencodedData = base64_decode($filteredData);

// Validasi hasil decode
if ($unencodedData === false) {
    http_response_code(400);
    echo json_encode(['error' => 'Failed to decode image data', 'success' => false]);
    exit();
}

// Validasi ukuran data (minimal 1KB untuk image valid)
if (strlen($unencodedData) < 1024) {
    error_log("Warning: Image data too small (" . strlen($unencodedData) . " bytes) - possibly incomplete capture\n", 3, "capture/capture.log");
}

// Generate nama file unik dengan timestamp
$timestamp = microtime(true);
$filename = $captureDir . '/capture_' . str_replace('.', '_', $timestamp) . '.png';

// Simpan file
$fp = fopen($filename, 'wb');
if (!$fp) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to open file for writing', 'success' => false]);
    exit();
}

$bytesWritten = fwrite($fp, $unencodedData);
fclose($fp);

// Validasi penulisan file
if ($bytesWritten === false || $bytesWritten === 0) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to write image data to file', 'success' => false]);
    unlink($filename);
    exit();
}

// Log sukses
error_log("Capture saved: " . $filename . " (" . $bytesWritten . " bytes)\n", 3, "capture/capture.log");

// Return response
echo json_encode([
    'success' => true, 
    'filename' => $filename, 
    'bytes' => $bytesWritten,
    'timestamp' => date('Y-m-d H:i:s'),
    'message' => 'Image saved successfully'
]);
exit();
?>
