import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ros_service.dart';

enum WaypointStatus { pending, active, completed }

enum RunMode { continuous, stop5s }

enum AppMode { manual, waypoint, map, settings }

class Waypoint {
  final String id;
  String name;
  final double x;
  final double y;
  WaypointStatus status;

  Waypoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.status = WaypointStatus.pending,
  });
}

// 🌟 Model lưu trữ thông tin báo động
class AlarmLog {
  final DateTime timestamp;
  final String type; // "FIRE" hoặc "SMOKE"
  final double x;
  final double y;
  final String imageUrl;

  AlarmLog(
      {required this.timestamp,
      required this.type,
      required this.x,
      required this.y,
      required this.imageUrl});
}

class NavigationProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.manual;
  AppMode get currentMode => _currentMode;
  bool isFireAlarmActive = false;

  List<Waypoint> waypoints = [];
  List<AlarmLog> alarmLogs = []; // 🌟 Đã mang vào đúng vị trí bên trong class

  ui.Image? slamImage;
  List<int> mapData = [];
  int mapWidth = 0;
  int mapHeight = 0;
  double mapResolution = 0.05;
  double mapOriginX = 0.0;
  double mapOriginY = 0.0;

  double currentX = 0.0;
  double currentY = 0.0;
  double currentYaw = 0.0;

  int? selectedIndex;
  bool isNavigating = false;
  bool isPaused = false;

  RunMode _currentRunMode = RunMode.continuous;
  String _searchQuery = "";

  RunMode get currentRunMode => _currentRunMode;
  String get searchQuery => _searchQuery;

  NavigationProvider() {
    // 1. Lắng nghe Odom
    rosService.odomStream.listen((msg) {
      try {
        final position = msg['pose']['pose']['position'];
        currentX = position['x'];
        currentY = position['y'];
        final ori = msg['pose']['pose']['orientation'];
        currentYaw = _quaternionToYaw(ori['x'], ori['y'], ori['z'], ori['w']);
        notifyListeners();

        if (isNavigating && !isPaused && waypoints.isNotEmpty) {
          _checkProximity(currentX, currentY);
        }
      } catch (e) {
        debugPrint("🚨 LỖI ODOM: $e");
      }
    });

    // 2. Lắng nghe Map
    rosService.mapStream.listen((msg) {
      try {
        final info = msg['info'];
        mapWidth = info['width'];
        mapHeight = info['height'];
        mapResolution = info['resolution'].toDouble();
        mapOriginX = info['origin']['position']['x'].toDouble();
        mapOriginY = info['origin']['position']['y'].toDouble();
        mapData = List<int>.from(msg['data']);
        _createSlamImageFromOccupancyGrid();
      } catch (e) {
        debugPrint("🚨 LỖI MAP: $e");
      }
    });

    // 3. Lắng nghe AI YOLO
    rosService.cameraResultStream.listen((jsonString) {
      _handleCameraAI(jsonString);
    });
  }

  // ==========================================
  // 🌟 LOGIC XỬ LÝ HỎA HOẠN VÀ LƯU NHẬT KÝ
  // ==========================================
  void _handleCameraAI(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      String detectedClass = data['class'] ?? "";
      double confidence = data['conf'] ?? 0.0;

      if ((detectedClass == "fire" || detectedClass == "smoke") &&
          confidence > 0.7) {
        if (!isFireAlarmActive) {
          // 🌟 Truyền loại sự cố vào hàm
          _triggerFireEmergency(detectedClass.toUpperCase());
        }
      }
    } catch (e) {
      debugPrint("🚨 LỖI AI: $e");
    }
  }

  // 🌟 Hàm báo động ĐÃ ĐƯỢC CHUẨN HOÁ
  void _triggerFireEmergency(String type) {
    isFireAlarmActive = true;
    isNavigating = false;
    isPaused = true;
    rosService.stopRobot();

    try {
      // Tự động tách địa chỉ IP từ kết nối ROS hiện tại
      String currentIp =
          rosService.ros.url.replaceAll('ws://', '').split(':')[0];
      String snapshotUrl =
          "http://$currentIp:8080/snapshot?topic=/camera/image_raw";

      // LƯU LOG MỚI VÀO DANH SÁCH
      alarmLogs.insert(
          0,
          AlarmLog(
            timestamp: DateTime.now(),
            type: type,
            x: currentX,
            y: currentY,
            imageUrl: snapshotUrl,
          ));

      debugPrint("🔥 ĐÃ LƯU NHẬT KÝ ($type) TẠI X: $currentX, Y: $currentY");
    } catch (e) {
      debugPrint("Lỗi khi lưu log ảnh: $e");
    }

    notifyListeners();
  }

  void clearFireAlarm() {
    isFireAlarmActive = false;
    notifyListeners();
  }

  // ==========================================
  // LOGIC TUẦN TRA & BẢN ĐỒ (GIỮ NGUYÊN)
  // ==========================================
  void _checkProximity(double robotX, double robotY) {
    int targetIndex =
        waypoints.indexWhere((wp) => wp.status == WaypointStatus.active);
    if (targetIndex == -1) return;

    Waypoint target = waypoints[targetIndex];
    double distance =
        sqrt(pow(target.x - robotX, 2) + pow(target.y - robotY, 2));

    if (distance < 0.25) {
      target.status = WaypointStatus.completed;
      notifyListeners();

      if (targetIndex < waypoints.length - 1) {
        int nextIndex = targetIndex + 1;
        if (_currentRunMode == RunMode.continuous) {
          waypoints[nextIndex].status = WaypointStatus.active;
          _sendCurrentGoalToRos();
        } else {
          _pauseAndGo(nextIndex);
        }
      } else {
        isNavigating = false;
        notifyListeners();
      }
    }
  }

  void _pauseAndGo(int nextIndex) async {
    await Future.delayed(const Duration(seconds: 5));
    if (isNavigating && !isPaused) {
      waypoints[nextIndex].status = WaypointStatus.active;
      _sendCurrentGoalToRos();
    }
  }

  void selectWaypoint(int index) {
    selectedIndex = index;
    isNavigating = true;
    isPaused = false;
    for (var i = 0; i < waypoints.length; i++) {
      if (waypoints[i].status != WaypointStatus.completed) {
        waypoints[i].status = WaypointStatus.pending;
      }
    }
    waypoints[index].status = WaypointStatus.active;
    _sendCurrentGoalToRos();
    notifyListeners();
  }

  Future<void> _createSlamImageFromOccupancyGrid() async {
    if (mapData.isEmpty || mapWidth == 0 || mapHeight == 0) return;
    final pixels = Uint8List(mapWidth * mapHeight * 4);
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        int index = x + y * mapWidth;
        int drawY = mapHeight - 1 - y;
        int imgIndex = (x + drawY * mapWidth) * 4;
        int cellData = mapData[index];
        if (cellData == 100) {
          pixels[imgIndex] = 0;
          pixels[imgIndex + 1] = 255;
          pixels[imgIndex + 2] = 255;
          pixels[imgIndex + 3] = 255;
        } else if (cellData == 0) {
          pixels[imgIndex] = 38;
          pixels[imgIndex + 1] = 50;
          pixels[imgIndex + 2] = 56;
          pixels[imgIndex + 3] = 255;
        } else {
          pixels[imgIndex + 3] = 0;
        }
      }
    }
    ui.decodeImageFromPixels(
        pixels, mapWidth, mapHeight, ui.PixelFormat.rgba8888, (img) {
      slamImage = img;
      notifyListeners();
    });
  }

  double _quaternionToYaw(double x, double y, double z, double w) {
    double siny_cosp = 2 * (w * z + x * y);
    double cosy_cosp = 1 - 2 * (y * y + z * z);
    return atan2(siny_cosp, cosy_cosp) * 180 / pi;
  }

  List<Waypoint> get filteredWaypoints {
    if (_searchQuery.isEmpty) return waypoints;
    return waypoints
        .where(
            (wp) => wp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRunMode(RunMode mode) {
    _currentRunMode = mode;
    notifyListeners();
  }

  void addWaypoint(String name, double x, double y) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    waypoints.add(Waypoint(id: newId, name: name, x: x, y: y));
    notifyListeners();
  }

  void removeWaypoint(int index) {
    waypoints.removeAt(index);
    if (selectedIndex == index) selectedIndex = null;
    notifyListeners();
  }

  void renameWaypoint(int index, String newName) {
    waypoints[index].name = newName;
    notifyListeners();
  }

  void reorderWaypoints(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = waypoints.removeAt(oldIndex);
    waypoints.insert(newIndex, item);
    notifyListeners();
  }

  void togglePause() {
    isPaused = !isPaused;
    if (isPaused) {
      rosService.move(0.0, 0.0);
    } else {
      _sendCurrentGoalToRos();
    }
    notifyListeners();
  }

  void startMission() {
    if (waypoints.isNotEmpty) {
      isNavigating = true;
      isPaused = false;
      if (waypoints.every((wp) => wp.status == WaypointStatus.completed)) {
        for (var wp in waypoints) {
          wp.status = WaypointStatus.pending;
        }
      }
      var nextWp = waypoints.firstWhere(
          (wp) => wp.status != WaypointStatus.completed,
          orElse: () => waypoints.first);
      nextWp.status = WaypointStatus.active;
      _sendCurrentGoalToRos();
      notifyListeners();
    }
  }

  void _sendCurrentGoalToRos() {
    try {
      Waypoint target =
          waypoints.firstWhere((wp) => wp.status == WaypointStatus.active);
      rosService.sendNav2Goal(target.x, target.y, 0.0);
    } catch (e) {
      debugPrint("Hành trình kết thúc.");
    }
  }

  void setMode(AppMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
}
