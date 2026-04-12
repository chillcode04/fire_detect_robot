import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:convert';

import '../config/app_config.dart';
import '../models/goal.dart';
import '../models/odom_data.dart';
import '../services/ros_service.dart'; //
import '../models/occupancy_grid.dart';

class RobotProvider extends ChangeNotifier {
  final RosService _ros = RosService();

  // State variables
  OccupancyGrid? map;
  OdomData? odom;
  List<Goal> goals = [];
  int currentGoalIndex = -1;
  bool isConnecting = false;
  bool _isSingleMode = false;

  // Manual control state
  double manualLinearX = 0.2;
  double manualAngularZ = 0.5;

  // Timers
  Timer? _navTimer;
  Timer? _cmdTimer;
  double _cmdLinear = 0.0;
  double _cmdAngular = 0.0;

  bool get isConnected => _ros.isConnected;

  bool isFireWarning = false; // trang thai chay
  bool isSmokeWarning = false;

  // CONNECT
  void connect(String url) {
    isConnecting = true;
    notifyListeners();

    _ros.connect(url);

    _ros.advertiseGoalPose(AppConfig.topicGoal); // topicGoal = '/goal_pose'

    // Subscribe Odom

    // Subscribe Map
    _ros.subscribe(AppConfig.topicMap, 'nav_msgs/msg/OccupancyGrid', (msg) {
      try {
        map = OccupancyGrid.fromJson(msg);
        notifyListeners();
      } catch (_) {}
    });

    _ros.subscribeOdom((newOdom) {
      odom = newOdom;
      notifyListeners();
    }, topic: AppConfig.topicOdom);

    _startTimers();
    isConnecting = false;
    notifyListeners();

    _ros.subscribe('/camera_result', 'std_msgs/String', (msg) {
      try {
        String jsonString = msg['data'];

        Map<String, dynamic> data = jsonDecode(jsonString);

        bool fireDetected = false;
        bool smokeDetected = false;
        if (data['objects'] != null) {
          for (var obj in data['objects']) {
            String className = obj['class'].toString().toLowerCase();
            if (className == 'fire') {
              fireDetected = true;
            }
            if (className == 'smoke') {
              smokeDetected = true;
            }
          }
        }

        if (isFireWarning != fireDetected || isSmokeWarning != smokeDetected) {
          isFireWarning = fireDetected;
          isSmokeWarning = smokeDetected;
          notifyListeners();
        }
      } catch (e) {
        print("Lỗi đọc JSON AI: $e");
      }
    });
  }

  void disconnect() {
    _stopTimers();
    _ros.disconnect();
    odom = null;
    currentGoalIndex = -1;
    notifyListeners();
  }

  //  MANUAL CONTROL
  void setManualSpeed(double lin, double ang) {
    manualLinearX = lin;
    manualAngularZ = ang;
    notifyListeners();
  }

  void moveManual(double lin, double ang) {
    _cmdLinear = lin;
    _cmdAngular = ang;
  }

  void stop() {
    _cmdLinear = 0.0;
    _cmdAngular = 0.0;
    currentGoalIndex = -1; // Tắt chế độ auto nếu đang chạy
    notifyListeners();
  }

  // WAYPOINT LOGIC
  void addGoalFromCurrentPose() {
    if (odom == null) return;
    goals.add(Goal(
      x: odom!.x,
      y: odom!.y,
      yaw: odom!.yaw,
      name: 'WP${goals.length + 1}',
    ));
    notifyListeners();
  }

  void deleteGoal(int index) {
    goals.removeAt(index);
    if (currentGoalIndex >= index) currentGoalIndex = -1;
    notifyListeners();
  }

  void startAuto(int index, {bool singleMode = false}) {
    if (index >= 0 && index < goals.length) {
      currentGoalIndex = index;
      _isSingleMode = singleMode;

      final target = goals[index];

      if (isConnected) {
        _ros.publishGoalPose(
          x: target.x,
          y: target.y,
          yaw: target.yaw,
          topic: AppConfig.topicGoal,
        );
      }

      notifyListeners();
    }
  }

  // INTERNAL LOOPS
  void _startTimers() {
    _cmdTimer?.cancel();
    _navTimer?.cancel();

    // Timer 1: Gửi lệnh cmd_vel liên tục (10Hz)
    _cmdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (isConnected) {
        _ros.publishCmdVel(_cmdLinear, _cmdAngular,
            topic: AppConfig.topicCmdVel);
      }
    });

    // Timer 2: Tính toán thuật toán dẫn đường (10Hz)
    _navTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _controlLoop());
  }

  void _stopTimers() {
    _cmdTimer?.cancel();
    _navTimer?.cancel();
  }

  void _controlLoop() {
    if (!isConnected || odom == null || currentGoalIndex == -1) return;
    if (currentGoalIndex >= goals.length) {
      stop();
    }

    final goal = goals[currentGoalIndex];
    final dx = goal.x - odom!.x;
    final dy = goal.y - odom!.y;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < AppConfig.distThreshold) {
      if (_isSingleMode) {
        stop();
      } else {
        currentGoalIndex++;
        if (currentGoalIndex >= goals.length) {
          stop();

          final nextTarget = goals[currentGoalIndex];
          _ros.publishGoalPose(
              x: nextTarget.x,
              y: nextTarget.y,
              yaw: nextTarget.yaw,
              topic: AppConfig.topicGoal);

          notifyListeners();
        }
      }
      return;
    }

    final angleToGoal = math.atan2(dy, dx);
    double angleError = angleToGoal - odom!.yaw;
    while (angleError > math.pi) angleError -= 2 * math.pi;
    while (angleError < -math.pi) angleError += 2 * math.pi;

    double lin = 0.0;
    double ang = 0.0;

    if (angleError.abs() > AppConfig.angleThreshold) {
      lin = 0.0;
      ang = AppConfig.kP_Angular * angleError;
    } else {
      lin = AppConfig.kP_Linear * dist;
      ang = AppConfig.kP_Angular * angleError;
    }

    _cmdLinear = lin.clamp(-AppConfig.maxLinearSpeed, AppConfig.maxLinearSpeed);
    _cmdAngular =
        ang.clamp(-AppConfig.maxAngularSpeed, AppConfig.maxAngularSpeed);
  }
}
