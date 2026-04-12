import 'dart:math' as math;

class OdomData {
  final double x;
  final double y;
  final double yaw;

  OdomData({required this.x, required this.y, required this.yaw});

  factory OdomData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('theta')) {
      return OdomData(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        yaw: (json['theta'] as num).toDouble(),
      );
    }

    if (json.containsKey('pose')) {
      final pose = json['pose']['pose'];
      final pos = pose['position'];
      final ori = pose['orientation'];

      double qz = (ori['z'] as num).toDouble();
      double qw = (ori['w'] as num).toDouble();

      // Công thức: Quaternion -> Yaw
      double yaw = math.atan2(2.0 * (qw * qz), 1.0 - 2.0 * (qz * qz));

      return OdomData(
        x: (pos['x'] as num).toDouble(),
        y: (pos['y'] as num).toDouble(),
        yaw: yaw,
      );
    }
    return OdomData(x: 0, y: 0, yaw: 0);
  }
}
