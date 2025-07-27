<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');

require_once 'db_config.php';

if (ob_get_level()) {
    ob_end_clean();
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['servo1']) && isset($_POST['servo2']) && isset($_POST['servo3']) && isset($_POST['servo4'])) {
        
        $s1 = intval($_POST['servo1']);
        $s2 = intval($_POST['servo2']);
        $s3 = intval($_POST['servo3']);
        $s4 = intval($_POST['servo4']);

        if ($s1 >= 0 && $s1 <= 180 && $s2 >= 0 && $s2 <= 180 && 
            $s3 >= 0 && $s3 <= 180 && $s4 >= 0 && $s4 <= 180) {
            
            try {
                $stmt = $pdo->prepare("UPDATE servo_status SET servo1 = ?, servo2 = ?, servo3 = ?, servo4 = ?, status = FALSE WHERE id = 1");
                $stmt->execute([$s1, $s2, $s3, $s4]);
                
                echo json_encode(['status' => 'success', 'message' => 'Servo angles updated.']);
                
                if (function_exists('fastcgi_finish_request')) {
                    fastcgi_finish_request();
                } else {
                    flush();
                }
                
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
            }
            
        } else {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Invalid angle values. Must be 0-180.']);
        }

    } else {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Missing servo parameters.']);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method.']);
}
?>