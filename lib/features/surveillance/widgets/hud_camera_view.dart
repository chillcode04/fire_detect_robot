import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:provider/provider.dart';

import '../../../providers/connection_provider.dart';
import '../../../providers/surveillance_provider.dart';
import '../../../providers/navigation_provider.dart';

class HudCameraView extends StatelessWidget {
  const HudCameraView({super.key});

  final Color neonGreen = const Color(0xFF00E676);
  final Color darkPanel = const Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    // Lắng nghe các Provider
    final connProvider = context.watch<ConnectionProvider>();
    final survProvider = context.watch<SurveillanceProvider>();
    final navProvider = context.watch<NavigationProvider>();

    return Container(
      color: Colors.black,
      child: Row(
        children: [
          // ==========================================
          // 1. CỘT TRÁI: TỌA ĐỘ VỊ TRÍ (X, Y) & HỆ THỐNG
          // ==========================================
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: darkPanel,
                border: Border(
                    right: BorderSide(
                        color: neonGreen.withOpacity(0.3), width: 1)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPanelHeader('ROBOT_POSITION'),
                  const SizedBox(height: 15),
                  _buildHudText(
                      'COORD_X: ${navProvider.currentX.toStringAsFixed(2)} m'),
                  _buildHudText(
                      'COORD_Y: ${navProvider.currentY.toStringAsFixed(2)} m'),
                  const Divider(color: Colors.white24, height: 30),
                  _buildPanelHeader('SYS_DIAGNOSTICS'),
                  const SizedBox(height: 15),
                  _buildHudText('CPU_LOAD:  22.3%'),
                  _buildHudText('BATTERY:   11.9 V'),
                  _buildHudText('PING:      12ms'),
                  const Spacer(),
                  _buildPanelHeader('EVENT_LOG'),
                  const SizedBox(height: 10),
                  Text(
                    "> Odom_Stream: ACTIVE\n> Link: ${connProvider.isConnected ? 'SECURE' : 'LOST'}",
                    style: TextStyle(
                        color: neonGreen.withOpacity(0.6),
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  )
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. CỘT GIỮA: CAMERA STREAM (60%)
          // ==========================================
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF050505),
                  child: connProvider.isConnected &&
                          connProvider.ipAddress.isNotEmpty
                      ? Mjpeg(
                          stream: survProvider
                              .getCameraStreamUrl(connProvider.ipAddress),
                          isLive: true,
                          fit: BoxFit.contain,
                          error: (context, error, stack) => const Center(
                            child: Text("MẤT TÍN HIỆU CAMERA",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                          loading: (context) => Center(
                              child:
                                  CircularProgressIndicator(color: neonGreen)),
                        )
                      : const Center(
                          child: Icon(Icons.videocam_off,
                              color: Colors.white24, size: 50)),
                ),
                // Tâm ngắm
                Center(
                    child: Icon(Icons.add,
                        color: neonGreen.withOpacity(0.5), size: 40)),

                // 🌟 CẬP NHẬT: Cảnh báo hỏa hoạn & Khói
                if (survProvider.isAlarmActive)
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: survProvider.alarmType == 'SMOKE'
                                ? Colors.orangeAccent
                                : Colors.redAccent,
                            width: 3),
                        color: (survProvider.alarmType == 'SMOKE'
                                ? Colors.orangeAccent
                                : Colors.redAccent)
                            .withOpacity(0.1)),
                    child: Center(
                      child: Text(
                          survProvider.alarmType == 'SMOKE'
                              ? "💨 SMOKE DETECTED 💨"
                              : "🔥 FIRE DETECTED 🔥",
                          style: TextStyle(
                              color: survProvider.alarmType == 'SMOKE'
                                  ? Colors.orangeAccent
                                  : Colors.redAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3)),
                    ),
                  )
              ],
            ),
          ),

          // ==========================================
          // 3. CỘT PHẢI: HƯỚNG QUAY (YAW) & AI (20%)
          // ==========================================
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: darkPanel,
                border: Border(
                    left: BorderSide(
                        color: neonGreen.withOpacity(0.3), width: 1)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPanelHeader('NAVIGATION_DATA'),
                  const SizedBox(height: 15),
                  _buildHudText(
                      'HEADING: ${navProvider.currentYaw.toStringAsFixed(1)}°'),
                  _buildHudText(
                      'MODE: ${navProvider.currentMode.name.toUpperCase()}'),

                  const Divider(color: Colors.white24, height: 30),

                  _buildPanelHeader('AI_VISION_NODE'),
                  const SizedBox(height: 15),
                  _buildHudText('MODEL: YOLOv11'),
                  _buildHudText('FPS:   25'),

                  const Spacer(),

                  // 🌟 CẬP NHẬT: Box trạng thái an ninh (Phân biệt Lửa / Khói)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: survProvider.isAlarmActive
                          ? (survProvider.alarmType == 'SMOKE'
                              ? Colors.orangeAccent.withOpacity(0.2)
                              : Colors.redAccent.withOpacity(0.2))
                          : Colors.transparent,
                      border: Border.all(
                          color: survProvider.isAlarmActive
                              ? (survProvider.alarmType == 'SMOKE'
                                  ? Colors.orangeAccent
                                  : Colors.redAccent)
                              : Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            survProvider.isAlarmActive
                                ? (survProvider.alarmType == 'SMOKE'
                                    ? Icons.smoking_rooms
                                    : Icons.warning_amber_rounded)
                                : Icons.security,
                            color: survProvider.isAlarmActive
                                ? (survProvider.alarmType == 'SMOKE'
                                    ? Colors.orangeAccent
                                    : Colors.redAccent)
                                : Colors.white54),
                        const SizedBox(height: 5),
                        Text(
                            survProvider.isAlarmActive
                                ? "${survProvider.alarmType} ALARM!"
                                : "AREA CLEAR",
                            style: TextStyle(
                                color: survProvider.isAlarmActive
                                    ? (survProvider.alarmType == 'SMOKE'
                                        ? Colors.orangeAccent
                                        : Colors.redAccent)
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildPanelHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: neonGreen.withOpacity(0.2),
          border: Border(left: BorderSide(color: neonGreen, width: 3))),
      child: Text(title,
          style: TextStyle(
              color: neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }

  Widget _buildHudText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text,
          style: TextStyle(
              color: neonGreen,
              fontSize: 15,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600)),
    );
  }
}
