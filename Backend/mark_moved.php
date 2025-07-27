<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        
        error_log("[MARK_MOVED] Marking servos as moved (status=TRUE)");
        
        // Set status to TRUE to indicate servos have moved
        $stmt = $pdo->prepare("UPDATE servo_status SET status = TRUE WHERE id = 1");
        $result = $stmt->execute();
        
        if ($result) {
            $response = [
                'success' => true,
                'message' => 'Servos marked as moved successfully',
                'debug' => [
                    'action' => 'mark_moved',
                    'status_set_to' => true,
                    'timestamp' => date('Y-m-d H:i:s')
                ]
            ];
            error_log("[MARK_MOVED] SUCCESS: Successfully marked servos as moved");
        } else {
            $response = [
                'success' => false,
                'message' => 'Failed to mark servos as moved',
                'debug' => [
                    'action' => 'mark_moved',
                    'error' => 'Database update failed'
                ]
            ];
            error_log("[MARK_MOVED] ERROR: Failed to update database");
        }
        
    } catch (PDOException $e) {
        $response = [
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage(),
            'debug' => [
                'action' => 'mark_moved',
                'error' => $e->getMessage()
            ]
        ];
        error_log("[MARK_MOVED] ERROR: Database error: " . $e->getMessage());
    }
} else {
    $response = [
        'success' => false,
        'message' => 'Only POST method allowed',
        'debug' => [
            'action' => 'mark_moved',
            'method' => $_SERVER['REQUEST_METHOD']
        ]
    ];
    error_log("[MARK_MOVED] ERROR: Invalid method: " . $_SERVER['REQUEST_METHOD']);
}

echo json_encode($response);
?>
