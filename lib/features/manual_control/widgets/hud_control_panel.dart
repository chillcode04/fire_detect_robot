import 'package:flutter/material.dart';
import '../../../services/ros_service.dart';
import 'dart:async';

class HudControlPanel extends StatefulWidget {
  const HudControlPanel({super.key});

  @override
  State<HudControlPanel> createState() => _HudControlPanelState();
}

class _HudControlPanelState extends State<HudControlPanel> {
  // Biến lưu trữ tốc độ
  double maxLinearSpeed = 0.5;
  double maxAngularSpeed = 1.0;

  // Biến trạng thái chế độ (Manual hoặc Auto)
  bool isAutoMode = false;
  Timer? _driveTimer; // Bộ đếm nhịp bắn lệnh
  String activeDirection = 'NONE'; // Lưu tên hướng đang chạy để làm sáng nút

  final Color neonGreen = const Color(0xFF00E676);
  final Color alertOrange =
      const Color.fromARGB(255, 5, 8, 196); // Màu cam cho chế độ Auto

  @override
  void dispose() {
    _driveTimer?.cancel(); // Tắt vòng lặp khi chuyển tab
    super.dispose();
  }

  void _stopRobot() {
    setState(() => activeDirection = 'NONE'); // Tắt đèn tất cả các nút
    _driveTimer?.cancel(); // Dừng spam lệnh
    rosService.move(0.0, 0.0); // Bắn lệnh phanh xuống ROS 2
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
              decoration: const BoxDecoration(
                  color: Color(0xFF2C3E3A), shape: BoxShape.circle),
              child: Icon(Icons.camera_alt, color: neonGreen),
            ),
            const SizedBox(width: 15),
            _buildActionButton(Icons.zoom_in, null),
            const SizedBox(width: 15),
            _buildActionButton(null, '480P'),
          ],
        ),

        // Nút chuyển chế độ
        const SizedBox(height: 10),
        _buildModeButton(),

        // PHẦN QUAN TRỌNG: Khu vực lái xe tự co giãn
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Slider trái
              _buildVerticalSlider(
                label: 'V-SPEED\n${maxLinearSpeed.toStringAsFixed(1)} m/s',
                value: maxLinearSpeed,
                min: 0.1,
                max: 1.0,
                color: neonGreen,
                onChanged: (val) => setState(() => maxLinearSpeed = val),
              ),

              // D-Pad ở giữa - Dùng FittedBox để không bao giờ bị Overflow
              Expanded(
                flex: 2,
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

              // Slider phải
              _buildVerticalSlider(
                label: 'OMEGA\n${maxAngularSpeed.toStringAsFixed(1)} rad',
                value: maxAngularSpeed,
                min: 0.2,
                max: 2.0,
                color: neonGreen,
                onChanged: (val) => setState(() => maxAngularSpeed = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15), // Khoảng đệm dưới đáy điện thoại
      ],
    );
  }

  // ==========================================
  // CÁC WIDGET PHỤ TRỢ ĐÃ ĐƯỢC NÂNG CẤP
  // ==========================================

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
                color: color,
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
                  inactiveTrackColor: Colors.grey[800],
                  thumbColor: Colors.white,
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
        // 🌟 SỬA: Khi đang chạy tay mà gạt sang chế độ Auto thì phải ngắt ga ngay lập tức
        if (isAutoMode) {
          _stopRobot();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
              color: isAutoMode ? alertOrange : neonGreen, width: 1.5),
          borderRadius: BorderRadius.circular(30),
          color: (isAutoMode ? alertOrange : neonGreen).withOpacity(0.1),
        ),
        child: Text(
          isAutoMode ? 'MODE: AUTONOMOUS' : 'MODE: MANUAL',
          style: TextStyle(
            color: isAutoMode ? alertOrange : neonGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // Widget cụm D-Pad
  Widget _buildDPad() {
    return Container(
      width: 160,
      height: 160,
      decoration:
          const BoxDecoration(color: Color(0xFF222224), shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🌟 SỬA: Đã truyền đủ 4 tham số (Thêm tên hướng)
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

          // 🌟 SỬA: Gắn hàm _stopRobot và đổi màu nền khi nút STOP đang được kích hoạt
          GestureDetector(
            onTap: _stopRobot,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: activeDirection == 'NONE'
                      ? Colors.redAccent.withOpacity(0.2)
                      : const Color(0xFF333335),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 2)),
              child: const Center(
                child: Text('STOP',
                    style: TextStyle(
                        color: Colors.redAccent,
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

        // 1. Sáng nút vừa bấm lên
        setState(() {
          activeDirection = dirName;
        });

        double currentLinear = maxLinearSpeed * linearDir;
        double currentAngular = maxAngularSpeed * angularDir;

        // 2. Dừng bộ đếm cũ (nếu đang chạy hướng khác)
        _driveTimer?.cancel();

        // 3. Spam lệnh liên tục 10Hz để Rùa không bị phanh lại
        _driveTimer =
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
          rosService.move(currentLinear, currentAngular);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? neonGreen.withOpacity(0.3) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child:
            Icon(icon, color: isActive ? neonGreen : Colors.white54, size: 36),
      ),
    );
  }

  Widget _buildActionButton(IconData? icon, String? text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF2A2A2C),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.white70, size: 18),
          if (icon != null && text != null) const SizedBox(width: 6),
          if (text != null)
            Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
