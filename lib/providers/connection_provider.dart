import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ros_service.dart';

class ConnectionProvider extends ChangeNotifier {
  String _ipAddress = "192.168.1.100";
  bool _isConnected = false;
  bool _isConnecting = false;

  String get ipAddress => _ipAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  ConnectionProvider() {
    _loadSavedIp();

    rosService.connectionStream.listen((isConnected) {
      _isConnected = isConnected;
      _isConnecting = false;
      notifyListeners();
    });
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ipAddress = prefs.getString('robot_ip') ?? "192.168.1.100";
    notifyListeners();
  }

  Future<void> saveIp(String newIp) async {
    _ipAddress = newIp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('robot_ip', newIp);
    print("Đã lưu IP vào bộ nhớ: $newIp");
    notifyListeners();
  }

  void toggleConnection() {
    if (_isConnected) {
      print("Đang ngắt kết nối với $_ipAddress...");
      rosService.disconnect();
    } else {
      if (_isConnecting) return;

      _isConnecting = true; // Bật trạng thái "ĐANG THỬ..."
      notifyListeners();

      print("Bắt đầu kết nối tới $_ipAddress...");
      rosService.connectToRobot(_ipAddress);
    }
  }
}
