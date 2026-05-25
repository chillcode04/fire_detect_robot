import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ros_service.dart';

enum WaypointStatus { pending, active, completed }

enum RunMode { continuous, stop5s, single }

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

class AlarmLog {
  final DateTime timestamp;
  final String type;
  final double x;
  final double y;
  final Uint8List? imageBytes;
  final String imageUrl;
  final double temperature;
  final double humidity;

  AlarmLog({
    required this.timestamp,
    required this.type,
    required this.x,
    required this.y,
    required this.imageUrl,
    this.imageBytes,
    required this.temperature,
    required this.humidity,
  });
}

class NavigationProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.manual;
  AppMode get currentMode => _currentMode;
  bool isFireAlarmActive = false;

  List<Waypoint> waypoints = [];
  List<AlarmLog> alarmLogs = [];

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

  double currentTemp = 0.0;
  double currentHum = 0.0;

  int? selectedIndex;
  bool isNavigating = false;
  bool isPaused = false;

  RunMode _currentRunMode = RunMode.continuous;
  String _searchQuery = "";

  RunMode get currentRunMode => _currentRunMode;
  String get searchQuery => _searchQuery;

  NavigationProvider() {
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
    rosService.cameraResultStream.listen((jsonString) {
      _handleCameraAI(jsonString);
    });

    rosService.tempStream.listen((temp) {
      currentTemp = temp;
    });

    rosService.humStream.listen((hum) {
      currentHum = hum;
    });
  }

  DateTime? _lastAlarmTime;

  void _handleCameraAI(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      String detectedClass = data['class'] ?? "";
      double confidence = (data['conf'] ?? 0.0).toDouble();
      String base64Image = data['image'] ?? ""; // ← lấy ảnh từ JSON luôn

      if ((detectedClass == "fire" || detectedClass == "smoke") &&
          confidence > 0.5) {
        final now = DateTime.now();
        bool cooldownPassed = _lastAlarmTime == null ||
            now.difference(_lastAlarmTime!).inSeconds >= 10;

        if (cooldownPassed) {
          _lastAlarmTime = now;
          _triggerFireEmergency(detectedClass.toUpperCase(), base64Image);
        }
      }
    } catch (e) {
      debugPrint("🚨 LỖI AI: $e");
    }
  }

  void _triggerFireEmergency(String type, String base64Image) {
    final detectedAt = DateTime.now();
    final snapX = currentX;
    final snapY = currentY;
    final snapTemp = currentTemp;
    final snapHum = currentHum;

    if (!isFireAlarmActive) {
      isFireAlarmActive = true;
      isNavigating = false;
      isPaused = true;
      rosService.stopRobot();
    }

    Uint8List? imageBytes;
    if (base64Image.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Image);
      } catch (e) {
        debugPrint("Lỗi decode ảnh base64: $e");
      }
    }

    alarmLogs.insert(
      0,
      AlarmLog(
        timestamp: detectedAt,
        type: type,
        x: snapX,
        y: snapY,
        imageUrl: "",
        imageBytes: imageBytes,
        temperature: snapTemp,
        humidity: snapHum,
      ),
    );

    notifyListeners();
  }

  void clearFireAlarm() {
    isFireAlarmActive = false;
    isPaused = false;
    notifyListeners();
  }

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

      if (_currentRunMode == RunMode.single) {
        isNavigating = false;
        rosService.move(0.0, 0.0);
        notifyListeners();
        return;
      }

      if (targetIndex < waypoints.length - 1) {
        int nextIndex = targetIndex + 1;
        if (_currentRunMode == RunMode.continuous) {
          waypoints[nextIndex].status = WaypointStatus.active;
          _sendCurrentGoalToRos();
        } else if (_currentRunMode == RunMode.stop5s) {
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

  void selectWaypointByCoords(double x, double y) {
    isNavigating = true;
    isPaused = false;
    for (var wp in waypoints) {
      if (wp.status == WaypointStatus.active) {
        wp.status = WaypointStatus.pending;
      }
    }
    rosService.sendNav2Goal(x, y, 0.0);
    notifyListeners();
  }

  void clearAlarmLogs() {
    alarmLogs.clear();
    notifyListeners();
  }

  void removeAlarmLog(int index) {
    if (index >= 0 && index < alarmLogs.length) {
      alarmLogs.removeAt(index);
      notifyListeners();
    }
  }
}
