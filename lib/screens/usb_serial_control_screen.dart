import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_control_panel/theme.dart';
import 'package:flutter_control_panel/widgets/themed_slider.dart';

class UsbSerialControlScreen extends StatefulWidget {
  const UsbSerialControlScreen({super.key});

  @override
  State<UsbSerialControlScreen> createState() => _UsbSerialControlScreenState();
}

class _UsbSerialControlScreenState extends State<UsbSerialControlScreen> {
  UsbPort? _port;
  List<UsbDevice> _devices = [];
  UsbDevice? _connectedDevice;
  StreamSubscription<Uint8List>? _subscription;
  bool _connected = false;
  bool _isConnecting = false;

  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;

  final List<String> _consoleLines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getPorts();
    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      _getPorts();
    });
  }

  @override
  void dispose() {
    _disconnect();
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

  Future<void> _getPorts() async {
    _devices = await UsbSerial.listDevices();
    setState(() {});
  }

  Future<void> _connect(UsbDevice device) async {
    setState(() => _isConnecting = true);
    _port = await device.create();
    try {
      if (!await (_port!.open())) {
        _showSnackBar('Failed to open port. Permission denied?');
        setState(() => _isConnecting = false);
        return;
      }
      await _port!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _subscription = _port!.inputStream?.listen((Uint8List data) {
        final message = String.fromCharCodes(data);
        final lines = message
            .split(RegExp(r'[\r\n]+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        if (mounted && lines.isNotEmpty) {
          setState(() {
            _consoleLines.addAll(lines);
            if (_consoleLines.length > 100) _consoleLines.removeRange(0, 50);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
      _showSnackBar(
        'Connected to ${device.productName ?? "USB Device"}!',
        success: true,
      );
      setState(() {
        _connectedDevice = device;
        _connected = true;
      });
    } catch (e) {
      _showSnackBar('Could not connect: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _subscription?.cancel();
    await _port?.close();
    setState(() {
      _port = null;
      _subscription = null;
      _connectedDevice = null;
      _connected = false;
      _consoleLines.clear();
    });
  }

  Future<void> _submitAngles() async {
    if (_port == null || !_connected) {
      _showSnackBar('Not connected to a device.');
      return;
    }
    String command =
        '${_servo1Value.round()},${_servo2Value.round()},${_servo3Value.round()},${_servo4Value.round()}\n';
    try {
      setState(() => _consoleLines.add("-> SENT: ${command.trim()}"));
      await _port!.write(Uint8List.fromList(command.codeUnits));
      _showSnackBar('Angles Submitted via USB!', success: true);
    } catch (e) {
      _showSnackBar('Failed to write to port: $e');
    }
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
        title: Text(_connected ? 'USB Control' : 'Find USB Device'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 2.0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _connected ? _buildControlUI() : _buildDeviceList(),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(Icons.usb_rounded, color: AppTheme.primaryColor, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Connect to Arduino',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect your phone to the Arduino.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Device List"),
            onPressed: _getPorts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.usb_off_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No USB devices found.",
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
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
                            Icons.developer_board,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                          title: Text(
                            device.productName ?? 'Unknown Device',
                            style: const TextStyle(
                              color: AppTheme.primaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'VID: ${device.vid} | PID: ${device.pid}',
                            style: const TextStyle(
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                          trailing: _isConnecting
                              ? const CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                )
                              : ElevatedButton(
                                  onPressed: () => _connect(device),
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
                    const Icon(Icons.usb_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Connected to: ${_connectedDevice?.productName ?? "USB Device"}',
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
                    onPressed: _disconnect,
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
        const SizedBox(height: 24),
        _buildSerialConsole(),
      ],
    );
  }

  Widget _buildSerialConsole() {
    return Card(
      elevation: 2.0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: SizedBox(
        height: 240,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Serial Console',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.clear_all,
                      color: AppTheme.secondaryTextColor,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _consoleLines.clear()),
                    tooltip: 'Clear Console',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _consoleLines.length,
                  itemBuilder: (context, index) {
                    final line = _consoleLines[index];
                    Color lineColor = line.startsWith("-> SENT:")
                        ? AppTheme.accentColor
                        : AppTheme.primaryTextColor;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '> $line',
                        style: TextStyle(
                          color: lineColor,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
