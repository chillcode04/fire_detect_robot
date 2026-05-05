import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌟 Đã thêm thư viện mở link ảnh
import '../../../providers/connection_provider.dart';
import '../../../providers/navigation_provider.dart';

class HudSettingsView extends StatefulWidget {
  const HudSettingsView({super.key});

  @override
  State<HudSettingsView> createState() => _HudSettingsViewState();
}

class _HudSettingsViewState extends State<HudSettingsView> {
  late TextEditingController _ipController;

  final Color primaryRed = const Color.fromARGB(255, 237, 109, 109);
  final Color lightPanel = const Color(0xFFF0F0F0); // Xám nhạt cho input/khối
  final Color background = Colors.white; // Nền trắng

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
    final connProvider = context.watch<ConnectionProvider>();
    final navProvider = context.watch<NavigationProvider>();

    return Container(
      color: background, // 🌟 Nền trắng
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          // ==========================================
          // TIÊU ĐỀ
          // ==========================================
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, color: primaryRed, size: 28), // 🌟 Icon đỏ
                const SizedBox(width: 10),
                Text("HỆ THỐNG CẤU HÌNH",
                    style: TextStyle(
                        color: primaryRed, // 🌟 Chữ đỏ
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const Divider(color: Colors.black12, height: 30), // 🌟 Viền xám mờ

          // ==========================================
          // PHẦN 1: KẾT NỐI ROS 2
          // ==========================================
          _buildSectionTitle("1. KẾT NỐI ROBOT (ROSBRIDGE)"),
          const SizedBox(height: 15),
          TextField(
            controller: _ipController,
            style:
                const TextStyle(color: Colors.black87), // 🌟 Chữ đen khi nhập
            decoration:
                _buildInputDecoration("Địa chỉ IP Robot (ví dụ: 192.168.x.x)"),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildActionButton(
                      "LƯU IP", Icons.save, Colors.grey[300]!, () {
                // 🌟 Nút lưu xám nhạt
                context.read<ConnectionProvider>().saveIp(_ipController.text);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("Đã lưu IP thành công!",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: primaryRed)); // 🌟 Thông báo lưu màu đỏ
              }, textColor: Colors.black87)),
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
                              ? primaryRed.withOpacity(
                                  0.8) // 🌟 Đang kết nối thì màu Đỏ
                              : primaryRed), () {
                // 🌟 Nút kết nối màu Đỏ
                context.read<ConnectionProvider>().toggleConnection();
              })),
            ],
          ),

          const SizedBox(height: 40),

          // ==========================================
          // PHẦN 2: NHẬT KÝ ẢNH HỎA HOẠN
          // ==========================================
          _buildSectionTitle("2. NHẬT KÝ BÁO ĐỘNG AI"),
          const SizedBox(height: 15),

          navProvider.alarmLogs.isEmpty
              ? _buildSettingTile(
                  "Chưa có dữ liệu",
                  "Hệ thống an toàn",
                  const Icon(Icons.security,
                      color: Colors.black38)) // 🌟 Icon an toàn xám
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: navProvider.alarmLogs.length,
                  itemBuilder: (context, index) {
                    final log = navProvider.alarmLogs[index];
                    bool isFire = log.type == "FIRE";

                    // 🌟 Sử dụng Material và InkWell để tạo hiệu ứng chạm đẹp mắt
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: isFire
                            ? Colors.red.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isFire
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            // Gọi hàm dẫn đường tới tọa độ của log
                            navProvider.selectWaypointByCoords(log.x, log.y);
                            navProvider.setMode(AppMode.map);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Robot đang di chuyển tới vị trí báo động...")));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
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
                                        color: Colors
                                            .black12, // 🌟 Nền lỗi ảnh xám
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.black26)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // Thông tin tọa độ và thời gian
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("${log.type} DETECTED",
                                          style: TextStyle(
                                              color: isFire
                                                  ? Colors.red
                                                  : Colors
                                                      .orange, // 🌟 Chữ đỏ hoặc cam
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      Text(
                                          "Vị trí: X:${log.x.toStringAsFixed(1)}, Y:${log.y.toStringAsFixed(1)}",
                                          style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize:
                                                  11)), // 🌟 Chữ thông tin đen

                                      Text(
                                          "Môi trường: ${log.temperature}°C | ${log.humidity}%",
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11)),
                                      // 🌟 ------------------------ 🌟

                                      Text(
                                          "Lúc: ${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}",
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8), // Khoảng cách nhỏ
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.black38, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Xác nhận xóa",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red)),
                                        content: const Text(
                                            "Bạn có chắc muốn xóa bản ghi báo động này không?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("HỦY",
                                                  style: TextStyle(
                                                      color: Colors.black54))),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.withOpacity(0.1),
                                                elevation: 0,
                                              ),
                                              onPressed: () {
                                                navProvider
                                                    .removeAlarmLog(index);
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Đã xóa nhật ký báo động"),
                                                    duration: Duration(
                                                        milliseconds: 500),
                                                  ),
                                                );
                                              },
                                              child: const Text("XÓA",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.black26,
                                    size: 14), // 🌟 Mũi tên xám mờ
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

          const SizedBox(height: 15),
          _buildActionButton("MỞ ALBUM ẢNH TRÊN MÁY", Icons.photo_library,
              primaryRed.withOpacity(0.1), () async {
            String currentIp = context.read<ConnectionProvider>().ipAddress;
            // 🌟 Thay đổi URL phù hợp với luồng của web_video_server
            final url = Uri.parse(
                "http://$currentIp:8080/snapshot?topic=/camera/image_raw");

            // Dùng thư viện url_launcher để mở trình duyệt
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Không thể mở liên kết này!"),
                  backgroundColor: Colors.red));
            }
          }, isFullWidth: true, textColor: primaryRed), // 🌟 Chữ nút Album Đỏ
        ],
      ),
    );
  }

  // --- CÁC HÀM PHỤ TRỢ UI (ĐÃ CHUYỂN SÁNG) ---
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14)); // 🌟 Tiêu đề mục màu đen
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: Colors.black38, fontSize: 13), // 🌟 Hint xám
      filled: true,
      fillColor: lightPanel, // 🌟 Nền form xám nhạt
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: Colors.black12), // 🌟 Viền chưa focus
          borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryRed), // 🌟 Viền đỏ khi đang nhập
          borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, Widget trailing) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: lightPanel, // 🌟 Nền khối xám nhạt
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12)), // 🌟 Thêm viền nhẹ
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold)), // 🌟 Chữ đen
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 11)), // 🌟 Phụ đề xám
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
      {bool isFullWidth = false, Color textColor = Colors.white}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0, // 🌟 Bỏ bóng đổ để nhìn phẳng và hiện đại hơn
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
