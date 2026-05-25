import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/navigation_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A), // Màu tối chuẩn HUD
      child: Column(
        children: [
          DrawerHeader(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 228, 119, 119)),
            child: const Center(
              child: Text('MENU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          _buildMenuItem(
              context, 'Manual Control', AppMode.manual, Icons.sports_esports),
          _buildMenuItem(context, 'Map View', AppMode.map, Icons.map),
          _buildMenuItem(context, 'Waypoint Navigation', AppMode.waypoint,
              Icons.location_on),
          const Divider(color: Colors.white24),
          _buildMenuItem(context, 'Settings', AppMode.settings, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, AppMode mode, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        context.read<NavigationProvider>().setMode(mode);
        Navigator.pop(context); // Đóng Menu sau khi chọn xong
      },
    );
  }
}
