import 'package:flutter/material.dart';
import 'package:flutter_control_panel/screens/bluetooth_control_screen.dart';
import 'package:flutter_control_panel/screens/usb_serial_control_screen.dart';
import 'package:flutter_control_panel/screens/wifi_control_screen.dart';
import 'package:flutter_control_panel/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Servo Control System',
          style: TextStyle(
            color: AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.cardColor,
        elevation: 2.0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Icon(
                Icons.precision_manufacturing_rounded,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a connection method to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            _buildConnectionCard(
              context: context,
              icon: Icons.wifi_rounded,
              title: 'Wi-Fi Control',
              subtitle: 'Control over the network',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WifiControlScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildConnectionCard(
              context: context,
              icon: Icons.bluetooth_searching_rounded,
              title: 'Bluetooth Control',
              subtitle: 'Direct BLE connection',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothControlScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildConnectionCard(
              context: context,
              icon: Icons.usb_rounded,
              title: 'USB Serial Control',
              subtitle: 'Wired serial connection',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UsbSerialControlScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the selection cards
  Widget _buildConnectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppTheme.primaryColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}