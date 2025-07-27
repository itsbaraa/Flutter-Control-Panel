CREATE DATABASE IF NOT EXISTS servo;
USE servo;

DROP TABLE IF EXISTS servo_status;


CREATE TABLE servo_status (
    id INT PRIMARY KEY AUTO_INCREMENT,
    servo1 INT NOT NULL DEFAULT 90 COMMENT 'Servo 1 angle (0-180 degrees)',
    servo2 INT NOT NULL DEFAULT 90 COMMENT 'Servo 2 angle (0-180 degrees)',
    servo3 INT NOT NULL DEFAULT 90 COMMENT 'Servo 3 angle (0-180 degrees)',
    servo4 INT NOT NULL DEFAULT 90 COMMENT 'Servo 4 angle (0-180 degrees)',
    status BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'FALSE = new angles to apply, TRUE = servos moved',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


INSERT INTO servo_status (id, servo1, servo2, servo3, servo4, status) 
VALUES (1, 90, 90, 90, 90, FALSE);

DROP TABLE IF EXISTS angles;

CREATE TABLE angles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pose_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Name of the saved pose',
    servo1 INT NOT NULL COMMENT 'Servo 1 angle (0-180 degrees)',
    servo2 INT NOT NULL COMMENT 'Servo 2 angle (0-180 degrees)',
    servo3 INT NOT NULL COMMENT 'Servo 3 angle (0-180 degrees)',
    servo4 INT NOT NULL COMMENT 'Servo 4 angle (0-180 degrees)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);