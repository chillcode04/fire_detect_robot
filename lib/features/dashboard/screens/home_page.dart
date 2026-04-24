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

  // Khai báo màu chủ đạo cho giao diện HUD
  final Color neonGreen = const Color.fromARGB(255, 0, 177, 80);
  final Color darkPanel = const Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    bool isLargeMap = navProvider.currentMode == AppMode.map ||
        navProvider.currentMode == AppMode.waypoint ||
        navProvider.currentMode == AppMode.settings; // Thêm dòng này
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(), // Đăng ký Drawer vào đây
      body: SafeArea(
        child: Stack(
          children: [
            // 1. GIAO DIỆN CHÍNH (Được bọc bởi Consumer để lắng nghe Mode)
            Consumer<NavigationProvider>(
              builder: (context, nav, child) {
                // NẾU LÀ SETTINGS: Trả về Full màn hình, KHÔNG CÓ COLUMN & CAMERA
                if (nav.currentMode == AppMode.settings) {
                  return const HudSettingsView();
                }

                // 3 TAB CÒN LẠI: Trả về Column có Camera
                bool isLargeBottom = nav.currentMode == AppMode.map ||
                    nav.currentMode == AppMode.waypoint;
                return Column(
                  children: [
                    // NỬA TRÊN: CAMERA
                    Expanded(
                      flex: isLargeBottom ? 40 : 65,
                      child: const HudCameraView(),
                    ),
                    // NỬA DƯỚI: MAP / WAYPOINT / ĐIỀU KHIỂN
                    Expanded(
                      flex: isLargeBottom ? 60 : 35,
                      child: Builder(
                        builder: (context) {
                          if (nav.currentMode == AppMode.map)
                            return const HudMapView();
                          if (nav.currentMode == AppMode.waypoint)
                            return const HudWaypointView();
                          return const HudControlPanel(); // Mặc định là lái tay
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            // NÚT MỞ MENU (Nằm đè lên góc trên bên trái)
            Builder(
              builder: (context) => Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- CÁC HÀM PHỤ TRỢ ĐỂ CODE GỌN GÀNG HƠN ---

  // Hàm tạo chữ kiểu HUD (Màu xanh neon, font máy tính)
  Widget _buildHudText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: neonGreen,
          fontSize: 12,
          fontFamily: 'monospace', // Dùng font chữ vi tính cho giống thật
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2)
          ], // Tạo viền đen để dễ đọc trên nền sáng
        ),
      ),
    );
  }

  // Hàm tạo nút chức năng nhỏ màu xám
  Widget _buildActionButton(IconData? icon, String? text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2C),
        borderRadius: BorderRadius.circular(8),
      ),
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

  // Hàm vẽ cụm D-Pad lái xe
  Widget _buildDPad() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF222224),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 Mũi tên
          Positioned(
              top: 10,
              child: Icon(Icons.keyboard_arrow_up,
                  color: Colors.white54, size: 30)),
          Positioned(
              bottom: 10,
              child: Icon(Icons.keyboard_arrow_down,
                  color: Colors.white54, size: 30)),
          Positioned(
              left: 10,
              child: Icon(Icons.keyboard_arrow_left,
                  color: Colors.white54, size: 30)),
          Positioned(
              right: 10,
              child: Icon(Icons.keyboard_arrow_right,
                  color: Colors.white54, size: 30)),

          // Nút tròn ở giữa (FUNC)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF333335),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('FUNC',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
