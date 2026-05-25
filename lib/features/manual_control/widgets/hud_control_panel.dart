import 'package:flutter/material.dart';
import '../../../services/ros_service.dart';
import 'dart:async';

class HudControlPanel extends StatefulWidget {
  const HudControlPanel({super.key});

  @override
  State<HudControlPanel> createState() => _HudControlPanelState();
}

class _HudControlPanelState extends State<HudControlPanel> {
  double maxLinearSpeed = 0.1;
  double maxAngularSpeed = 1.0;

  bool isAutoMode = false;
  Timer? _driveTimer;
  String activeDirection = 'NONE';

  final Color primaryRed = Colors.red;
  final Color autoModeColor = Colors.orange[800]!;

  @override
  void dispose() {
    _driveTimer?.cancel();
    super.dispose();
  }

  void _stopRobot() {
    setState(() => activeDirection = 'NONE');
    _driveTimer?.cancel();
    rosService.move(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Hàng nút chức năng
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(Icons.videocam, 'Record'),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.camera_alt, color: primaryRed),
            ),
            const SizedBox(width: 15),
            _buildActionButton(Icons.zoom_in, null),
            const SizedBox(width: 15),
            _buildActionButton(null, '480P'),
          ],
        ),

        const SizedBox(height: 10),
        _buildModeButton(),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVerticalSlider(
                  label: 'Velocity\n${maxLinearSpeed.toStringAsFixed(1)} m/s',
                  value: maxLinearSpeed,
                  min: 0.1,
                  max: 1.0,
                  color: primaryRed,
                  onChanged: (val) => setState(() => maxLinearSpeed = val),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Opacity(
                        opacity: isAutoMode ? 0.3 : 1.0,
                        child: IgnorePointer(
                            ignoring: isAutoMode, child: _buildDPad()),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _buildVerticalSlider(
                  label: 'Omega\n${maxAngularSpeed.toStringAsFixed(1)} rad',
                  value: maxAngularSpeed,
                  min: 0.2,
                  max: 2.0,
                  color: primaryRed,
                  onChanged: (val) => setState(() => maxAngularSpeed = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildVerticalSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: color,
                  trackHeight: 8.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                ),
                child: Slider(
                    value: value, min: min, max: max, onChanged: onChanged),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isAutoMode = !isAutoMode;
        });
        if (isAutoMode) {
          _stopRobot();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
              color: isAutoMode ? autoModeColor : primaryRed, width: 1.5),
          borderRadius: BorderRadius.circular(30),
          color: (isAutoMode ? autoModeColor : primaryRed).withOpacity(0.1),
        ),
        child: Text(
          isAutoMode ? 'MODE: AUTONOMOUS' : 'MODE: MANUAL',
          style: TextStyle(
            color: isAutoMode ? autoModeColor : primaryRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ]),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
              top: 5,
              child: _buildDirectionButton(
                  Icons.keyboard_arrow_up, 1.0, 0.0, 'UP')),
          Positioned(
              bottom: 5,
              child: _buildDirectionButton(
                  Icons.keyboard_arrow_down, -1.0, 0.0, 'DOWN')),
          Positioned(
              left: 5,
              child: _buildDirectionButton(
                  Icons.keyboard_arrow_left, 0.0, 1.0, 'LEFT')),
          Positioned(
              right: 5,
              child: _buildDirectionButton(
                  Icons.keyboard_arrow_right, 0.0, -1.0, 'RIGHT')),
          GestureDetector(
            onTap: _stopRobot,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: activeDirection == 'NONE'
                      ? primaryRed.withOpacity(0.2)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryRed, width: 2)),
              child: const Center(
                child: Text('STOP',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDirectionButton(
      IconData icon, double linearDir, double angularDir, String dirName) {
    bool isActive = activeDirection == dirName;

    return GestureDetector(
      onTap: () {
        if (isAutoMode) return;

        setState(() {
          activeDirection = dirName;
        });

        double currentLinear = maxLinearSpeed * linearDir;
        double currentAngular = maxAngularSpeed * angularDir;

        _driveTimer?.cancel();
        _driveTimer =
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
          rosService.move(currentLinear, currentAngular);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? primaryRed.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child:
            Icon(icon, color: isActive ? primaryRed : Colors.black38, size: 36),
      ),
    );
  }

  Widget _buildActionButton(IconData? icon, String? text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey[200], // 🌟 Nền nút xám nhạt
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: Colors.black87, size: 18), // 🌟 Icon đen
          if (icon != null && text != null) const SizedBox(width: 6),
          if (text != null)
            Text(text,
                style: const TextStyle(
                    color: Colors.black87, fontSize: 14)), // 🌟 Chữ đen
        ],
      ),
    );
  }
}
