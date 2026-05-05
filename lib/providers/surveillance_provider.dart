import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ros_service.dart';

class SurveillanceProvider extends ChangeNotifier {
  bool _isAlarmActive = false;
  String _alarmType = "NONE"; //

  bool get isAlarmActive => _isAlarmActive;
  String get alarmType => _alarmType;

  SurveillanceProvider() {
    rosService.cameraResultStream.listen((jsonString) {
      try {
        final data = jsonDecode(jsonString);
        String label = data['class'] ?? "";
        double conf = data['conf'] ?? 0.0;

        if ((label == "fire" || label == "smoke") && conf > 0.7) {
          if (!_isAlarmActive || _alarmType != label.toUpperCase()) {
            _isAlarmActive = true;
            _alarmType = label.toUpperCase();
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint("Lỗi đọc JSON AI: $e");
      }
    });

    rosService.fireAlarmStream.listen((detected) {
      if (detected && !_isAlarmActive) {
        _isAlarmActive = true;
        _alarmType = "FIRE";
        notifyListeners();
      }
    });
  }

  String getCameraStreamUrl(String ipAddress) {
    return "http://$ipAddress:8080/stream?topic=/camera/image_raw";
    // return "http://$ipAddress:8080/stream?topic=/image_raw";
  }

  void resetAlarm() {
    _isAlarmActive = false;
    _alarmType = "NONE";
    notifyListeners();
  }
}
