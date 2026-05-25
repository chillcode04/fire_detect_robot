import 'dart:async';
import 'dart:math';
import 'package:roslibdart/roslibdart.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart';

class RosService {
  static final RosService _instance = RosService._internal();
  factory RosService() => _instance;
  RosService._internal();

  late Ros ros;
  Timer? _connectionTimer;

  // --- 1. KHAI BÁO CÁC TOPIC ---
  Topic? tempTopic;
  Topic? humTopic;
  Topic? cmdVelTopic;
  Topic? goalTopic;
  Topic? odomTopic;
  Topic? mapTopic;
  Topic? fireAlarmTopic;
  Topic? cameraResultTopic;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _fireAlarmController = StreamController<bool>.broadcast();
  Stream<bool> get fireAlarmStream => _fireAlarmController.stream;

  final _odomController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get odomStream => _odomController.stream;

  final _mapController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get mapStream => _mapController.stream;

  final _cameraResultController = StreamController<String>.broadcast();
  Stream<String> get cameraResultStream => _cameraResultController.stream;

  final _tempController = StreamController<double>.broadcast();
  Stream<double> get tempStream => _tempController.stream;

  final _humController = StreamController<double>.broadcast();
  Stream<double> get humStream => _humController.stream;

  void connectToRobot(String ipAddress) {
    _connectionTimer?.cancel();
    try {
      ros.close();
    } catch (_) {}

    ros = Ros(url: 'ws://$ipAddress:${AppConfig.defaultWsPort}');

    ros.statusStream.listen((status) {
      if (status == Status.connected) {
        _connectionTimer?.cancel();
        _connectionController.add(true);
        _setupSubscribers();
        _setupPublishers();
        debugPrint("🟢 KẾT NỐI THÀNH CÔNG & SẴN SÀNG LÀM VIỆC!");
      } else {
        _connectionController.add(false);
      }
    }, onError: (error) {
      _connectionController.add(false);
    });

    try {
      ros.connect();
      _connectionTimer = Timer(const Duration(seconds: 3), () {
        if (ros.status != Status.connected) {
          ros.close();
          _connectionController.add(false);
        }
      });
    } catch (e) {
      _connectionController.add(false);
    }
  }

  void _setupSubscribers() {
    odomTopic = Topic(
        ros: ros,
        name: AppConfig.topicOdom,
        type: 'geometry_msgs/msg/PoseWithCovarianceStamped');
    odomTopic?.subscribe((msg) async {
      _odomController.add(msg);
    });

    mapTopic = Topic(
        ros: ros, name: AppConfig.topicMap, type: 'nav_msgs/msg/OccupancyGrid');
    mapTopic?.subscribe((msg) async {
      _mapController.add(msg);
    });

    fireAlarmTopic = Topic(
        ros: ros, name: AppConfig.topicFireAlarm, type: 'std_msgs/msg/Bool');
    fireAlarmTopic?.subscribe((msg) async {
      bool isFire = msg['data'] ?? false;
      _fireAlarmController.add(isFire);
    });

    cameraResultTopic =
        Topic(ros: ros, name: '/camera_result', type: 'std_msgs/msg/String');
    cameraResultTopic?.subscribe((msg) async {
      try {
        String jsonString = msg['data'] ?? "";
        if (jsonString.isNotEmpty) {
          _cameraResultController.add(jsonString);
        }
      } catch (e) {
        debugPrint("🚨 LỖI KHI NHẬN DỮ LIỆU CAMERA RESULT: $e");
      }
    });

    tempTopic = Topic(
        ros: ros,
        name: '/bme280/temperature',
        type: 'sensor_msgs/msg/Temperature');
    tempTopic?.subscribe((msg) async {
      try {
        if (msg['temperature'] != null) {
          _tempController.add(msg['temperature'].toDouble());
        }
      } catch (e) {
        debugPrint("🚨 LỖI ĐỌC NHIỆT ĐỘ: $e");
      }
    });

    humTopic = Topic(
        ros: ros,
        name: '/bme280/humidity',
        type: 'sensor_msgs/msg/RelativeHumidity');
    humTopic?.subscribe((msg) async {
      try {
        if (msg['relative_humidity'] != null) {
          _humController.add(msg['relative_humidity'].toDouble());
        }
      } catch (e) {
        debugPrint("🚨 LỖI ĐỌC ĐỘ ẨM: $e");
      }
    });
  }

  void _setupPublishers() {
    cmdVelTopic = Topic(
        ros: ros, name: AppConfig.topicCmdVel, type: 'geometry_msgs/msg/Twist');
    cmdVelTopic?.advertise();

    goalTopic = Topic(
        ros: ros,
        name: AppConfig.topicGoal,
        type: 'geometry_msgs/msg/PoseStamped');
    goalTopic?.advertise();
  }

  void move(double linear, double angular) {
    if (ros.status != Status.connected) return;
    var msg = {
      'linear': {'x': linear, 'y': 0.0, 'z': 0.0},
      'angular': {'x': 0.0, 'y': 0.0, 'z': angular},
    };
    cmdVelTopic?.publish(msg);
  }

  void stopRobot() {
    if (ros.status != Status.connected) return;
    var msg = {
      'linear': {'x': 0.0, 'y': 0.0, 'z': 0.0},
      'angular': {'x': 0.0, 'y': 0.0, 'z': 0.0},
    };
    cmdVelTopic?.publish(msg);
    debugPrint("🛑 ĐÃ GỬI LỆNH DỪNG KHẨN CẤP!");
  }

  void sendNav2Goal(double x, double y, double yaw) {
    if (ros.status != Status.connected) return;

    double halfYaw = yaw * (pi / 180.0) / 2.0;
    double qZ = sin(halfYaw);
    double qW = cos(halfYaw);

    var msg = {
      'header': {
        'stamp': {'sec': 0, 'nanosec': 0},
        'frame_id': 'map',
      },
      'pose': {
        'position': {'x': x, 'y': y, 'z': 0.0},
        'orientation': {'x': 0.0, 'y': 0.0, 'z': qZ, 'w': qW}
      }
    };

    goalTopic?.publish(msg);
    debugPrint("📍 ĐÃ GỬI TỌA ĐỘ MỤC TIÊU XUỐNG ROS 2: X=$x, Y=$y");
  }

  void disconnect() {
    odomTopic?.unsubscribe();
    mapTopic?.unsubscribe();
    fireAlarmTopic?.unsubscribe();
    cameraResultTopic?.unsubscribe();

    tempTopic?.unsubscribe();
    humTopic?.unsubscribe();

    cmdVelTopic?.unadvertise();
    goalTopic?.unadvertise();
    ros.close();
    debugPrint("🔌 ĐÃ NGẮT KẾT NỐI AN TOÀN!");
  }
}

final rosService = RosService();
