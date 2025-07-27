import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_control_panel/theme.dart';
import 'package:flutter_control_panel/widgets/themed_slider.dart';

final Guid serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
final Guid characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

class BluetoothControlScreen extends StatefulWidget {
  const BluetoothControlScreen({super.key});

  @override
  State<BluetoothControlScreen> createState() => _BluetoothControlScreenState();
}

class _BluetoothControlScreenState extends State<BluetoothControlScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  List<ScanResult> _scanResults = [];
  bool _isConnecting = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      final filteredResults = results
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() => _scanResults = filteredResults);
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: success ? const Color(0xFF2E7D32) : Colors.redAccent,
      ),
    );
  }

  Future<void> _startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == characteristicUuid) {
              if (!mounted) return;
              setState(() {
                _connectedDevice = device;
                _targetCharacteristic = characteristic;
              });
              _showSnackBar(
                'Controller connected successfully!',
                success: true,
              );
              return;
            }
          }
        }
      }
      _showSnackBar('Required servo service not found.');
      await device.disconnect();
    } catch (e) {
      _showSnackBar('Failed to connect: ${e.toString().split('.').last}');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectFromDevice() async {
    await _connectedDevice?.disconnect();
    setState(() {
      _connectedDevice = null;
      _targetCharacteristic = null;
    });
    _showSnackBar('Device disconnected.');
  }

  Future<void> _submitAngles() async {
    if (_targetCharacteristic == null) {
      _showSnackBar('Not connected to a device.');
      return;
    }
    String command =
        '${_servo1Value.round()},${_servo2Value.round()},${_servo3Value.round()},${_servo4Value.round()}';
    List<int> bytes = utf8.encode(command);
    await _targetCharacteristic!.write(bytes, withoutResponse: true);
    _showSnackBar('Angles submitted via Bluetooth!', success: true);
  }

  void _resetSliders() {
    setState(() {
      _servo1Value = 90.0;
      _servo2Value = 90.0;
      _servo3Value = 90.0;
      _servo4Value = 90.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _connectedDevice == null
              ? 'Find Bluetooth Controller'
              : 'Bluetooth Control',
        ),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 2.0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _connectedDevice == null ? _buildScanUI() : _buildControlUI(),
      ),
    );
  }

  Widget _buildScanUI() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          StreamBuilder<bool>(
            stream: FlutterBluePlus.isScanning,
            initialData: false,
            builder: (c, snapshot) {
              final isScanning = snapshot.data ?? false;
              return ElevatedButton.icon(
                icon: isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(isScanning ? 'SCANNING...' : 'SCAN FOR DEVICES'),
                onPressed: isScanning ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No devices found.",
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      return Card(
                        color: AppTheme.cardColor,
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: const Icon(
                            Icons.memory,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                          title: Text(
                            result.device.platformName,
                            style: const TextStyle(
                              color: AppTheme.primaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${result.device.remoteId}',
                            style: const TextStyle(
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                          trailing: _isConnecting
                              ? const CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                )
                              : ElevatedButton(
                                  onPressed: () =>
                                      _connectToDevice(result.device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor
                                        .withAlpha((255 * 0.8).round()),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlUI() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Card(
          elevation: 2.0,
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bluetooth_connected_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Connected to ${_connectedDevice!.platformName}',
                        style: const TextStyle(
                          color: AppTheme.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    onPressed: _disconnectFromDevice,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
                const Divider(height: 20),
                ThemedSlider(
                  servoIndex: 1,
                  value: _servo1Value,
                  onChanged: (v) => setState(() => _servo1Value = v),
                ),
                ThemedSlider(
                  servoIndex: 2,
                  value: _servo2Value,
                  onChanged: (v) => setState(() => _servo2Value = v),
                ),
                ThemedSlider(
                  servoIndex: 3,
                  value: _servo3Value,
                  onChanged: (v) => setState(() => _servo3Value = v),
                ),
                ThemedSlider(
                  servoIndex: 4,
                  value: _servo4Value,
                  onChanged: (v) => setState(() => _servo4Value = v),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: _resetSliders,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.neutralColor,
                          side: BorderSide(
                            color: AppTheme.neutralColor.withAlpha((255 * 0.5).round()),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: _submitAngles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
