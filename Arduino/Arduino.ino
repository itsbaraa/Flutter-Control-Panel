#include <Servo.h>
#include <SoftwareSerial.h>

const int NUM_SERVOS = 4;
const int servoPins[NUM_SERVOS] = {13, 12, 11, 10}; 
Servo servos[NUM_SERVOS];
bool servosAttached = false;
int previousAngles[NUM_SERVOS] = {-1, -1, -1, -1}; // Initialize to -1 (invalid angle)

const byte rxPin = 2; // Connect to ESP32 TX pin 25
const byte txPin = 3; // Connect to ESP32 RX pin 27
SoftwareSerial espSerial(rxPin, txPin);

// Add a small tolerance to prevent micro-movements
const int ANGLE_TOLERANCE = 1; // Only move if angle changes by more than 1 degree

void setup() {
  Serial.begin(9600);
  Serial.println("[Arduino] Booting up...");

  espSerial.begin(9600);

  Serial.println("\n[Arduino] Ready to receive data");
}

void loop() {
  if (espSerial.available() > 0) {
    String data = espSerial.readStringUntil('\n');
    data.trim();

    Serial.println("[Arduino] Received: '" + data + "'");
    
    parseAndSetAngles(data);
  }
}

void parseAndSetAngles(String data) {
  int angles[NUM_SERVOS];
  int lastIndex = -1;

  for (int i = 0; i < NUM_SERVOS; i++) {
    int commaIndex = data.indexOf(',', lastIndex + 1);
    String valStr;

    if (commaIndex == -1 && i < NUM_SERVOS -1) {
        Serial.println("[Parser] Error: Malformed string. Not enough values.");
        return;
    }

    if (commaIndex == -1) {
      valStr = data.substring(lastIndex + 1);
    } else {
      valStr = data.substring(lastIndex + 1, commaIndex);
    }

    angles[i] = valStr.toInt();
    lastIndex = commaIndex;
    
    if (angles[i] < 0) angles[i] = 0;
    if (angles[i] > 180) angles[i] = 180;
  }
  
  // Attach all servos only when we first receive a command
  if (!servosAttached) {
    Serial.println("[Arduino] Attaching servos for first command...");
    for (int i = 0; i < NUM_SERVOS; i++) {
      servos[i].attach(servoPins[i]);
      // Set to current position to avoid initial movement
      if (previousAngles[i] == -1) {
        servos[i].write(90); // Default position
        previousAngles[i] = 90;
        Serial.println("  Servo " + String(i + 1) + " initialized at 90°");
      }
      delay(100); // Delay between servo attachments to reduce electrical noise
    }
    servosAttached = true;
    Serial.println("[Arduino] All servos attached and initialized");
  }
  
  Serial.println("--- Setting Servo Angles ---");
  bool anyServoMoved = false;
  int servosMoved = 0;
  
  // First pass: count how many servos need to move (with tolerance)
  for (int i = 0; i < NUM_SERVOS; i++) {
    if (abs(angles[i] - previousAngles[i]) > ANGLE_TOLERANCE) {
      servosMoved++;
    }
  }
  
  Serial.println("  Servos to move: " + String(servosMoved));
  
  // Update only the servos that changed significantly
  for (int i = 0; i < NUM_SERVOS; i++) {
    if (abs(angles[i] - previousAngles[i]) > ANGLE_TOLERANCE) {
      servos[i].write(angles[i]);
      Serial.println("  Servo " + String(i + 1) + " (Pin " + String(servoPins[i]) + "): " + String(previousAngles[i]) + "° -> " + String(angles[i]) + "°");
      previousAngles[i] = angles[i]; // Update the previous angle
      anyServoMoved = true;
      
      // Add small delay between servo movements to prevent electrical interference
      delay(20);
    } else {
      Serial.println("  Servo " + String(i + 1) + " (Pin " + String(servoPins[i]) + "): " + String(angles[i]) + "° (no significant change)");
    }
  }
  
  if (!anyServoMoved) {
    Serial.println("  No servos moved - all angles unchanged");
  }
  
  Serial.println("----------------------------");
  
  // Notify ESP32 to mark servos as moved (only if any servo actually moved)
  if (anyServoMoved) {
    espSerial.println("MARK_MOVED");
  }
}