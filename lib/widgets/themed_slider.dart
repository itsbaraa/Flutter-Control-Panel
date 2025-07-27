import 'package:flutter/material.dart';
import 'package:flutter_control_panel/theme.dart';

class ThemedSlider extends StatelessWidget {
  final int servoIndex;
  final double value;
  final ValueChanged<double> onChanged;

  const ThemedSlider({
    super.key,
    required this.servoIndex,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(
            'S$servoIndex',
            style: const TextStyle(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.accentColor.withAlpha(77),
                  trackHeight: 4.0,
                  thumbColor: AppTheme.primaryColor,
                  showValueIndicator: ShowValueIndicator.never,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 0.0,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: 180,
                  label: value.round().toString(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${value.round()}°',
                style: const TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
