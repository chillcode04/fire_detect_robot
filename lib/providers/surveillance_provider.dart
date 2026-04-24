import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ros_service.dart';

class SurveillanceProvider extends ChangeNotifier {
  bool _isAlarmActive = false;
  String _alarmType =
      "NONE"; // 🌟 THÊM BIẾN NÀY: Lưu loại báo động "FIRE" hoặc "SMOKE"

  bool get isAlarmActive => _isAlarmActive;
  String get alarmType => _alarmType;

  SurveillanceProvider() {
    // 1. Lắng nghe AI YOLO (Biết chính xác là khói hay lửa)
    rosService.cameraResultStream.listen((jsonString) {
      try {
        final data = jsonDecode(jsonString);
        String label = data['class'] ?? "";
        double conf = data['conf'] ?? 0.0;

        // Bắt lỗi khói hoặc lửa với độ tin cậy > 70%
        if ((label == "fire" || label == "smoke") && conf > 0.7) {
          if (!_isAlarmActive || _alarmType != label.toUpperCase()) {
            _isAlarmActive = true;
            _alarmType =
                label.toUpperCase(); // 🌟 Ghi nhớ hệ thống đang bắt được cái gì
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint("Lỗi đọc JSON AI: $e");
      }
    });

    // 2. Lắng nghe Topic cũ (Phòng hờ trường hợp không dùng JSON)
    rosService.fireAlarmStream.listen((detected) {
      if (detected && !_isAlarmActive) {
        _isAlarmActive = true;
        _alarmType = "FIRE"; // Mặc định báo lửa nếu ko có thông tin chi tiết
        notifyListeners();
      }
    });
  }

  String getCameraStreamUrl(String ipAddress) {
    return "http://$ipAddress:8080/stream?topic=/camera/image_raw";
  }

  // Hàm tắt báo động thủ công
  void resetAlarm() {
    _isAlarmActive = false;
    _alarmType = "NONE";
    notifyListeners();
  }
}
