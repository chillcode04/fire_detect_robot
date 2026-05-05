import 'package:flutter/material.dart';
import '../../manual_control/widgets/hud_control_panel.dart';
import '../widgets/app_drawer.dart';
import '../../surveillance/widgets/hud_camera_view.dart';
import '../../../providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import '../../navigation/widgets/hud_map_view.dart';
import '../../navigation/widgets/hud_waypoint_view.dart';
import '../../settings/widgets/hud_settings_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Color primaryRed = const Color.fromARGB(255, 237, 109, 109);
  final Color lightPanel = const Color.fromARGB(255, 244, 242, 242);

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    bool isLargeBottom = navProvider.currentMode == AppMode.map ||
        navProvider.currentMode == AppMode.waypoint;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 244, 244), // Nền sáng
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. GIAO DIỆN CHÍNH
            Consumer<NavigationProvider>(
              builder: (context, nav, child) {
                if (nav.currentMode == AppMode.settings) {
                  return const HudSettingsView();
                }

                return Column(
                  children: [
                    // NỬA TRÊN: CAMERA
                    Expanded(
                      flex: 40,
                      child: const HudCameraView(),
                    ),

                    Expanded(
                      flex: 60,
                      child: Builder(
                        builder: (context) {
                          if (nav.currentMode == AppMode.map) {
                            return const HudMapView();
                          }
                          if (nav.currentMode == AppMode.waypoint) {
                            return const HudWaypointView();
                          }
                          return const HudControlPanel();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            Builder(
              builder: (context) => Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.menu, color: primaryRed, size: 30),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: primaryRed, // 🌟 Chữ đỏ
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData? icon, String? text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200], // 🌟 Nền xám nhạt
        borderRadius: BorderRadius.circular(8),
      ),
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

  Widget _buildDPad() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[200], // 🌟 Nền D-Pad xám nhạt
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 Mũi tên xám đậm
          Positioned(
              top: 10,
              child: Icon(Icons.keyboard_arrow_up,
                  color: Colors.black54, size: 30)),
          Positioned(
              bottom: 10,
              child: Icon(Icons.keyboard_arrow_down,
                  color: Colors.black54, size: 30)),
          Positioned(
              left: 10,
              child: Icon(Icons.keyboard_arrow_left,
                  color: Colors.black54, size: 30)),
          Positioned(
              right: 10,
              child: Icon(Icons.keyboard_arrow_right,
                  color: Colors.black54, size: 30)),

          // Nút tròn ở giữa
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.white, // 🌟 Nền trắng viền đỏ
                shape: BoxShape.circle,
                border: Border.all(color: primaryRed, width: 2)),
            child: Center(
              child: Text('FUNC',
                  style: TextStyle(
                      color: primaryRed, // 🌟 Chữ đỏ
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
