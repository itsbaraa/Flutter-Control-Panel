#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define ARDUINO_SERIAL Serial2
const int ARDUINO_RX_PIN = 27;
const int ARDUINO_TX_PIN = 25;

const char* ssid = "ssid";
const char* password = "password";
const char* serverIP = "ip";

String checkStatusUrl = String("http://") + serverIP + "/servo_api/check_status.php";
String markMovedUrl = String("http://") + serverIP + "/servo_api/mark_moved.php";

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME         "Baraa_ESP32"
const int LED_PIN = 2;

BLECharacteristic *pCharacteristic = nullptr;
bool deviceConnected = false;
unsigned long lastCheckTime = 0;
unsigned long lastLedBlinkTime = 0;
bool ledState = false;
const long checkInterval = 1000;
const long ledBlinkInterval = 500;

void markServosMoved();

class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String value = pCharacteristic->getValue();
        if (value.length() > 0) {
            Serial.println("[BLE] Received: " + value + ". Sending to Arduino.");
            ARDUINO_SERIAL.println(value);
            
            markServosMoved();
        }
    }
};

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      digitalWrite(LED_PIN, HIGH);
      Serial.println("[BLE] Device Connected");
    }
    
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] Device Disconnected.");
      // Restart advertising to make the device discoverable again.
      pServer->getAdvertising()->start();
      Serial.println("[BLE] Advertising restarted.");
    }
};

// --- SETUP FUNCTIONS ---
void setupWifi() {
  Serial.println("[WIFI] Initializing Wi-Fi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("[WIFI] Connecting");
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI] Connected!");
    Serial.print("[WIFI] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WIFI] Failed to connect, will retry in main loop");
  }
}

void setupBluetooth() {
    Serial.println("[BLE] Initializing Bluetooth...");
    BLEDevice::init(DEVICE_NAME);
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
                      );
    pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    
    // Start advertising
    BLEDevice::getAdvertising()->start();
    Serial.println("[BLE] Advertising started. Ready to connect.");
}

// --- MAIN SETUP ---
void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    ARDUINO_SERIAL.begin(9600, SERIAL_8N1, ARDUINO_RX_PIN, ARDUINO_TX_PIN);
    Serial.println("\n[ESP32] Booting and initializing services...");
    
    // Initialize both Wi-Fi and Bluetooth
    setupBluetooth();
    setupWifi();
}

// --- MAIN LOOP ---
void loop() {
  // --- Wi-Fi Logic ---
  if (WiFi.status() == WL_CONNECTED) {
      if (millis() - lastCheckTime > checkInterval) {
        lastCheckTime = millis();
        HTTPClient http;
        http.setTimeout(5000);
        http.begin(checkStatusUrl);
        
        int httpCode = http.GET();

        if (httpCode == HTTP_CODE_OK) {
          String response = http.getString();
          
          // Parse JSON response
          if (response.indexOf("\"has_data\":true") > -1) {
            // Extract angles from JSON response
            int anglesStart = response.indexOf("\"angles\":\"") + 10;
            int anglesEnd = response.indexOf("\"", anglesStart);
            if (anglesStart > 9 && anglesEnd > anglesStart) {
              String angles = response.substring(anglesStart, anglesEnd);
              Serial.println("[HTTP] NEW SERVO COMMAND: '" + angles + "'. Sending to Arduino.");
              ARDUINO_SERIAL.println(angles);
              
              // Mark that servos moved via Wi-Fi
              markServosMoved();
            } else {
              Serial.println("[HTTP] Could not parse angles from response");
            }
          } else if (response.indexOf("\"has_data\":false") > -1) {
            Serial.println("[HTTP] No pending commands");
          } else {
            Serial.println("[HTTP] Unexpected response format");
          }
        } else if(httpCode > 0) {
            Serial.printf("[HTTP] GET failed, code: %d, error: %s\n", httpCode, http.errorToString(httpCode).c_str());
        } else {
            Serial.println("[HTTP] Connection failed");
        }
        http.end();
      }
  } else {
    // Try to reconnect Wi-Fi if disconnected
    Serial.println("[WIFI] Connection lost, attempting reconnect...");
    WiFi.begin(ssid, password);
    delay(1000);
  }

  if (!deviceConnected) {
      if (millis() - lastLedBlinkTime > ledBlinkInterval) {
        lastLedBlinkTime = millis();
        ledState = !ledState;
        digitalWrite(LED_PIN, ledState);
      }
  } else {
      // Keep the LED solid when a device is connected
      digitalWrite(LED_PIN, HIGH);
  }
  
  // --- Check for messages from Arduino ---
  if (ARDUINO_SERIAL.available() > 0) {
    String message = ARDUINO_SERIAL.readStringUntil('\n');
    message.trim();
    
    if (message == "MARK_MOVED") {
      markServosMoved();
    } else {
      Serial.println("[ARDUINO] Unexpected message: " + message);
    }
  }
  
  // Small delay to prevent excessive CPU usage and improve stability
  delay(50);
}

// --- HELPER FUNCTIONS ---
void markServosMoved() {
  // Send HTTP request to mark that servos have moved
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.setTimeout(3000);
    http.begin(markMovedUrl);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    
    int httpCode = http.POST("moved=true");
    if (httpCode == HTTP_CODE_OK) {
      Serial.println("[HTTP] Marked servos as moved");
    } else {
      Serial.println("[HTTP] Could not mark servos as moved");
    }
    http.end();
  }
}