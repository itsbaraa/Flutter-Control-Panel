# Flutter Control Panel

A servo motor control app built with Flutter, featuring multiple communication methods (Wi-Fi, Bluetooth, USB Serial) to control 4 servo motors.

##  Features

### Core Functionality
- **Multi-Protocol Communication**: Support for Wi-Fi, Bluetooth Low Energy (BLE), and USB Serial connections
- **Real-Time Servo Control**: Individual control of 4 servo motors with smooth slider interfaces
- **Pose Management**: Save, load, and delete servo positions for quick access
- **Visual Feedback**: Real-time angle display and responsive UI elements
- **Cross-Platform**: Compatible with Android devices

### Communication Protocols
- **Wi-Fi Control**: Network-based control with HTTP API integration
- **Bluetooth Control**: Direct BLE connection for wireless operation
- **USB Serial Control**: Wired connection for stable communication

### Hardware Integration
- **Arduino Support**: Complete Arduino sketch for servo control
- **ESP32 Integration**: Wi-Fi and Bluetooth communication handling
- **Backend API**: PHP-based server for pose storage and retrieval


## Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Android Studio or VS Code with Flutter extensions
- Arduino IDE
- PHP server (for Wi-Fi functionality)
- MySQL database (for pose storage)

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # HTTP requests for Wi-Fi communication
  flutter_blue_plus: ^1.14.16    # Bluetooth Low Energy support
  usb_serial: ^0.4.0             # USB Serial communication
  cupertino_icons: ^1.0.8        # iOS-style icons
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/itsbaraa/Flutter-Control-Panel.git
   cd Flutter-Control-Panel
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Hardware Setup**
   - Upload `Arduino/Arduino.ino` to your Arduino board
   - Upload `Arduino/ESP32.ino` to your ESP32 module
   - Connect servos to pins 10, 11, 12, 13 on Arduino
   - Wire Arduino and ESP32 for serial communication

4. **Backend Setup** (for Wi-Fi functionality)
   - Deploy PHP files from `Backend/` to your web server
   - Import `database.sql` to create the required database schema
   - Configure `db_config.php` with your database credentials

5. **Run the application**
   ```bash
   flutter run
   ```

## Screenshots

### Home Screen
![1000158104](https://github.com/user-attachments/assets/6f194dcb-c5d8-4e88-9083-0fb7b04ca651)

### Wi-Fi Control Interface
![1000158105](https://github.com/user-attachments/assets/7b0449a8-1039-40b5-a2ed-a818e9b0d7f7)

### Bluetooth Control Interface
![1000158107](https://github.com/user-attachments/assets/13aa79e8-9ed0-4be3-83ea-12d592d5cabb)

### USB Serial Control Interface
![1000158111](https://github.com/user-attachments/assets/e6236756-60fb-493c-8e5c-5513a4444fca)
