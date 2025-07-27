import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_control_panel/models/pose.dart';
import 'package:flutter_control_panel/theme.dart';
import 'package:flutter_control_panel/widgets/themed_slider.dart';

const String serverIp = "ip";
const String baseUrl = "http://$serverIp/servo_api";

class WifiControlScreen extends StatefulWidget {
  const WifiControlScreen({super.key});

  @override
  State<WifiControlScreen> createState() => _WifiControlScreenState();
}

class _WifiControlScreenState extends State<WifiControlScreen> {
  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;
  List<Pose> _savedPoses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPoses();
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828),
      ),
    );
  }

  Future<void> _fetchPoses() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/get_poses.php'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        setState(
          () => _savedPoses = jsonResponse
              .map((data) => Pose.fromJson(data))
              .toList(),
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAngles() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update_angles.php'),
            body: {
              'servo1': _servo1Value.round().toString(),
              'servo2': _servo2Value.round().toString(),
              'servo3': _servo3Value.round().toString(),
              'servo4': _servo4Value.round().toString(),
            },
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == 'success') {
            _showSnackBar(
              'Servo angles updated! ESP32 will read new positions.',
              success: true,
            );
          } else {
            _showSnackBar(
              'Error: ${jsonResponse['message'] ?? 'Unknown error'}',
            );
          }
        } catch (e) {
          // Fallback for non-JSON responses
          _showSnackBar('Angles submitted successfully!', success: true);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showSnackBar('Request timeout - check your connection');
      } else {
        _showSnackBar('Failed to submit angles: ${e.toString()}');
      }
    }
  }

  Future<void> _savePose() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_pose.php'),
        body: {
          'servo1': _servo1Value.round().toString(),
          'servo2': _servo2Value.round().toString(),
          'servo3': _servo3Value.round().toString(),
          'servo4': _servo4Value.round().toString(),
        },
      );
      if (response.statusCode == 200 &&
          json.decode(response.body)['status'] == 'success') {
        _showSnackBar('Pose saved successfully!', success: true);
        _fetchPoses();
      } else {
        throw Exception('Failed to save pose.');
      }
    } catch (e) {
      _showSnackBar('Error saving pose: ${e.toString()}');
    }
  }

  Future<void> _deletePose(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_pose.php'),
        body: {'id': id.toString()},
      );
      if (response.statusCode == 200 &&
          json.decode(response.body)['status'] == 'success') {
        _showSnackBar('Pose deleted.', success: true);
        _fetchPoses();
      } else {
        throw Exception('Failed to delete pose.');
      }
    } catch (e) {
      _showSnackBar('Error deleting pose: ${e.toString()}');
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

  void _loadPoseToSliders(Pose pose) {
    setState(() {
      _servo1Value = pose.servo1.toDouble();
      _servo2Value = pose.servo2.toDouble();
      _servo3Value = pose.servo3.toDouble();
      _servo4Value = pose.servo4.toDouble();
    });
    _showSnackBar('Pose ${pose.id} loaded into sliders.', success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Wi-Fi Control'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 2.0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
              child: _buildLiveControlCard(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                child: _buildSavedPosesCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveControlCard() {
    return Card(
      elevation: 2.0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Live Control",
                  style: TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
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
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    onPressed: _resetSliders,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neutralColor,
                      side: BorderSide(
                        color: AppTheme.neutralColor.withAlpha(128),
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
                    icon: const Icon(Icons.save_alt_rounded, size: 16),
                    label: const Text('Save', style: TextStyle(fontSize: 12)),
                    onPressed: _savePose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
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
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit', style: TextStyle(fontSize: 12)),
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
    );
  }

  Widget _buildSavedPosesCard() {
    return Card(
      elevation: 2.0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Saved Poses",
                      style: TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.secondaryTextColor,
                  ),
                  onPressed: _fetchPoses,
                  tooltip: 'Refresh List',
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        "Error: Could not load poses.",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : _savedPoses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No poses saved yet.",
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _savedPoses.length,
                      itemBuilder: (context, index) {
                        final pose = _savedPoses[index];
                        return _buildPoseListItem(pose);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoseListItem(Pose pose) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            pose.id.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Pose ${pose.id}',
          style: const TextStyle(
            color: AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${pose.servo1}, ${pose.servo2}, ${pose.servo3}, ${pose.servo4}',
          style: const TextStyle(color: AppTheme.secondaryTextColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => _loadPoseToSliders(pose),
              tooltip: 'Load Pose',
              color: AppTheme.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _deletePose(pose.id),
              tooltip: 'Delete Pose',
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
