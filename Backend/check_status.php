<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');

require_once 'db_config.php';

error_log("Check status request received");

if (ob_get_level()) {
    ob_end_clean();
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    try {
        // Check if there are pending servo commands
        $stmt = $pdo->prepare("SELECT servo1, servo2, servo3, servo4, status FROM servo_status WHERE id = 1");
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        error_log("Database query result: " . json_encode($result));
        
        if ($result && $result['status'] == 0) {
            // Status is FALSE (0) - send angles and set status to TRUE to mark as processed
            $angles = $result['servo1'] . ',' . $result['servo2'] . ',' . $result['servo3'] . ',' . $result['servo4'];
            
            error_log("Found new command to apply: " . $angles);
            
            // Set status to TRUE to indicate servos have been moved
            $updateStmt = $pdo->prepare("UPDATE servo_status SET status = TRUE WHERE id = 1");
            $updateStmt->execute();
            
            echo json_encode([
                'status' => 'success',
                'has_data' => true,
                'angles' => $angles
            ]);
        } else {
            // Status is TRUE (1) - servos already moved, ignore
            error_log("Status is TRUE - servos already moved, ignoring command");
            echo json_encode([
                'status' => 'success',
                'has_data' => false,
                'message' => 'Servos already moved, no action needed'
            ]);
        }
        
    } catch (PDOException $e) {
        error_log("Database error in check_status: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
    }
} else {
    error_log("Invalid method in check_status: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method.']);
}
?>