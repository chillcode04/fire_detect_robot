import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/odom_data.dart';

class RosService {
  WebSocketChannel? _channel;
  int _idCounter = 0;

  void Function(OdomData)? _odomCallback;
  String? _currentOdomTopic;

  bool get isConnected => _channel != null;

  String _nextId() => 'flutter_client_${_idCounter++}';

  // 1. KẾT NỐI / NGẮT KẾT NỐI

  void connect(String url) {
    disconnect();

    try {
      debugPrint('[ROS] Connecting to $url...');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message),
        onDone: () {
          debugPrint('[ROS] Connection closed.');
          _cleanup();
        },
        onError: (error) {
          debugPrint('[ROS] Connection error: $error');
          _cleanup();
        },
      );
    } catch (e) {
      debugPrint('[ROS] Exception connecting: $e');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _cleanup();
    }
  }

  void _cleanup() {
    _channel = null;
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      final jsonStr = jsonEncode(data);
      _channel!.sink.add(jsonStr);
    } catch (e) {
      debugPrint('[ROS] Error sending JSON: $e');
    }
  }

  void advertiseGoalPose(String topic) {
    final msg = {
      'op': 'advertise',
      'topic': topic,
      'type': 'geometry_msgs/msg/PoseStamped',
    };
    _sendJson(msg);
    debugPrint('[ROS] Advertised PoseStamped on $topic');
  }

  // 2. GỬI LỆNH ĐIỀU KHIỂN (PUBLISH)

  /// Gửi vận tốc (/cmd_vel)
  void publishCmdVel(double linearX, double angularZ, {required String topic}) {
    final msg = {
      'op': 'publish',
      'topic': topic,
      'type': 'geometry_msgs/msg/Twist',
      'msg': {
        'linear': {'x': linearX, 'y': 0.0, 'z': 0.0},
        'angular': {'x': 0.0, 'y': 0.0, 'z': angularZ},
      }
    };
    _sendJson(msg);
  }

  void publishGoalPose({
    required double x,
    required double y,
    required double yaw,
    required String topic,
    String frameId = 'map',
  }) {
    final now = DateTime.now().toUtc();
    final sec = now.millisecondsSinceEpoch ~/ 1000;
    final nanosec = (now.microsecondsSinceEpoch % 1000000) * 1000;

    final halfYaw = yaw / 2.0;
    final qz = math.sin(halfYaw);
    final qw = math.cos(halfYaw);

    final msg = {
      "op": "publish",
      "topic": topic,
      "type": "geometry_msgs/msg/PoseStamped",
      "msg": {
        "header": {
          "stamp": {"sec": sec, "nanosec": nanosec},
          "frame_id": frameId,
        },
        "pose": {
          "position": {
            "x": x,
            "y": y,
            "z": 0.0 // Robot mặt đất thì z luôn = 0
          },
          "orientation": {
            "x": 0.0,
            "y": 0.0,
            "z": qz, // Giá trị Quaternion Z
            "w": qw // Giá trị Quaternion W
          },
        },
      },
    };

    _sendJson(msg);
    debugPrint('[ROS] Đã gửi Goal Pose chuẩn Quaternion: z=$qz, w=$qw');
  }

  // 3. NHẬN DỮ LIỆU (SUBSCRIBE)

  /// Đăng ký lắng nghe vị trí robot
  void subscribeOdom(void Function(OdomData) callback,
      {required String topic}) {
    _odomCallback = callback;
    _currentOdomTopic = topic;

    if (!isConnected) return;

    // Gửi lệnh subscribe lên Server
    _sendJson({
      'op': 'subscribe',
      'id': _nextId(),
      'topic': topic,

      //'type': 'geometry_msgs/msg/PoseWithCovarianceStamped', // AMCL
      'type': 'nav_msgs/msg/Odometry', //Odom
    });
  }

  final Map<String, Function(dynamic)> _topicCallbacks = {};

  void subscribe(String topic, String type, Function(dynamic) callback) {
    _topicCallbacks[topic] = callback;

    if (!isConnected) return;

    _sendJson({
      'op': 'subscribe',
      'id': _nextId(),
      'topic': topic,
      'type': type,
    });

    debugPrint('[ROS] Subscribed to $topic');
  }

  // 4. XỬ LÝ TIN NHẮN ĐẾN

  void _handleIncomingMessage(dynamic message) {
    try {
      final jsonMap = jsonDecode(message.toString());

      final op = jsonMap['op'];
      if (op != 'publish') return;

      final topic = jsonMap['topic'];
      final msg = jsonMap['msg'];

      if (topic == _currentOdomTopic && _odomCallback != null) {
        final data = OdomData.fromJson(jsonMap);
        final odom = OdomData.fromJson(msg);
        _odomCallback!(odom);
      }
      if (_topicCallbacks.containsKey(topic)) {
        _topicCallbacks[topic]!(msg);
      }
    } catch (e) {}
  }
}
