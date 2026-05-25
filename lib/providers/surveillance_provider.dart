import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ros_service.dart';

class SurveillanceProvider extends ChangeNotifier {
  bool _isAlarmActive = false;
  String _alarmType = "NONE";
  Timer? _alarmClearTimer;

  bool get isAlarmActive => _isAlarmActive;
  String get alarmType => _alarmType;

  SurveillanceProvider() {
    rosService.cameraResultStream.listen((jsonString) {
      try {
        final data = jsonDecode(jsonString);
        String label = data['class'] ?? "";
        double conf = (data['conf'] ?? 0.0).toDouble();

        if ((label == "fire" || label == "smoke") && conf > 0.5) {
          if (!_isAlarmActive) {
            _isAlarmActive = true;
            _alarmType = label.toUpperCase();
            notifyListeners();
          }
          _alarmClearTimer?.cancel();
          _alarmClearTimer = Timer(const Duration(seconds: 3), () {
            _isAlarmActive = false;
            _alarmType = "NONE";
            notifyListeners();
          });
        }
      } catch (e) {
        debugPrint("Lỗi đọc JSON AI: $e");
      }
    });
  }

  // String getCameraStreamUrl() {
  //   final uri = Uri.parse(rosService.ros.url.replaceFirst('ws://', 'http://'));
  //   //return 'http://${uri.host}:8080/stream?topic=/image_raw&&type=mjpeg&default_transport=compressed&width=640&height=480&quality=30&qos_profile=sensor_data';
  //   return 'http://localhost:8080/stream?topic=/image_raw&type=ros_compressed';
  // }
  String getCameraStreamUrl() {
    final uri = Uri.parse(rosService.ros.url.replaceFirst('ws://', 'http://'));
    return 'http://${uri.host}:8080/stream?topic=/image_raw&type=mjpeg&quality=60&fps=20';
  }

  void resetAlarm() {
    _alarmClearTimer?.cancel();
    _isAlarmActive = false;
    _alarmType = "NONE";
    notifyListeners();
  }
}
