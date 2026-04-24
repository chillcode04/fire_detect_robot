import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../providers/navigation_provider.dart'; // 🌟 SỬA 1: Thêm import NavigationProvider

class HudSettingsView extends StatefulWidget {
  const HudSettingsView({super.key});

  @override
  State<HudSettingsView> createState() => _HudSettingsViewState();
}

class _HudSettingsViewState extends State<HudSettingsView> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    final initialIp = context.read<ConnectionProvider>().ipAddress;
    _ipController = TextEditingController(text: initialIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 SỬA 2: Lắng nghe cả 2 bộ não (Connection và Navigation)
    final connProvider = context.watch<ConnectionProvider>();
    final navProvider = context.watch<NavigationProvider>();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          // TIÊU ĐỀ
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.tune, color: Color(0xFF00E676), size: 28),
                SizedBox(width: 10),
                Text("HỆ THỐNG CẤU HÌNH",
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 30),

          // --- PHẦN 1: KẾT NỐI ROS 2 ---
          _buildSectionTitle("1. KẾT NỐI ROBOT (ROSBRIDGE)"),
          const SizedBox(height: 15),
          TextField(
            controller: _ipController,
            style: const TextStyle(color: Colors.cyanAccent),
            decoration:
                _buildInputDecoration("Địa chỉ IP Robot (ví dụ: 192.168.x.x)"),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildActionButton(
                      "LƯU IP", Icons.save, Colors.blueGrey, () {
                context.read<ConnectionProvider>().saveIp(_ipController.text);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Đã lưu IP thành công!"),
                    backgroundColor: Colors.green));
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildActionButton(
                      connProvider.isConnecting
                          ? "ĐANG THỬ..."
                          : (connProvider.isConnected
                              ? "NGẮT KẾT NỐI"
                              : "KẾT NỐI"),
                      connProvider.isConnecting ? Icons.sync : Icons.sensors,
                      connProvider.isConnecting
                          ? Colors.orange
                          : (connProvider.isConnected
                              ? Colors.redAccent
                              : const Color(0xFF00E676)), () {
                context.read<ConnectionProvider>().toggleConnection();
              })),
            ],
          ),

          const SizedBox(height: 40),

          // --- PHẦN 2: NHẬT KÝ ẢNH HỎA HOẠN (Đã fix lỗi dấu ngoặc) ---
          _buildSectionTitle("2. NHẬT KÝ BÁO ĐỘNG AI"),
          const SizedBox(height: 15),

          navProvider.alarmLogs.isEmpty
              ? _buildSettingTile("Chưa có dữ liệu", "Hệ thống an toàn",
                  const Icon(Icons.check_circle, color: Colors.green))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: navProvider.alarmLogs.length,
                  itemBuilder: (context, index) {
                    final log = navProvider.alarmLogs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          // Ảnh chụp từ Robot
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              log.imageUrl,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) => Container(
                                  width: 80,
                                  height: 60,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Thông tin tọa độ và thời gian
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${log.type} DETECTED",
                                    style: TextStyle(
                                        color: log.type == "FIRE"
                                            ? Colors.redAccent
                                            : Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(
                                    "Vị trí: X:${log.x.toStringAsFixed(1)}, Y:${log.y.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                Text(
                                    "Lúc: ${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}",
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white24, size: 14),
                        ],
                      ),
                    );
                  },
                ),

          const SizedBox(height: 15),
          _buildActionButton("MỞ ALBUM ẢNH TRÊN MÁY", Icons.photo_library,
              Colors.cyanAccent.withOpacity(0.2), () {
            print("Đang mở thư viện ảnh...");
          }, isFullWidth: true),
        ], // 🌟 Danh sách UI kết thúc gọn gàng tại đây
      ),
    );
  }

  // --- CÁC HÀM PHỤ TRỢ UI ---
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14));
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00E676)),
          borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, Widget trailing) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed,
      {bool isFullWidth = false}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor:
            color == const Color(0xFF00E676) ? Colors.black : Colors.white,
        minimumSize: Size(isFullWidth ? double.infinity : 0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
