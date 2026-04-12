import 'package:flutter/material.dart';
import '../models/occupancy_grid.dart';
import '../models/odom_data.dart';
import 'dart:math' as math;
import '../models/goal.dart';

class MapView extends StatelessWidget {
  final OccupancyGrid? map;
  final OdomData? robotPose;
  final List<Goal> goals;

  const MapView({
    super.key,
    required this.map,
    required this.robotPose,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    if (map == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00E5FF)),
              SizedBox(height: 10),
              Text("Waiting for Map...", style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 5.0,
        constrained: false,
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: CustomPaint(
            painter: _MapPainter(map: map!, robotPose: robotPose, goals: goals),
          ),
        ),
      ),
    );
  } // <-- Đóng ngoặc của hàm build
} // <-- Đ

class _MapPainter extends CustomPainter {
  final OccupancyGrid map;
  final OdomData? robotPose;
  final List<Goal> goals;

  _MapPainter(
      {required this.map, required this.robotPose, required this.goals});

  @override
  void paint(Canvas canvas, Size size) {
    final paintWall = Paint()..color = Colors.black;
    final paintRobot = Paint()
      ..color = Colors.cyanAccent[400]!
      ..style = PaintingStyle.fill;
    final paintGoal = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.fill;
    final paintGoalBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    double scale = 50;

    canvas.save();

    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, -scale);

    if (robotPose != null) {
      canvas.translate(-robotPose!.x, -robotPose!.y);
    }

    for (int i = 0; i < map.data.length; i++) {
      int val = map.data[i];
      if (val == 100) {
        // 100 là Tường
        int gridX = i % map.width;
        int gridY = i ~/ map.width;

        double worldX = map.originX + (gridX * map.resolution);
        double worldY = map.originY + (gridY * map.resolution);

        canvas.drawRect(
          Rect.fromLTWH(worldX, worldY, map.resolution, map.resolution),
          paintWall,
        );
      }
    }

    for (int i = 0; i < goals.length; i++) {
      final g = goals[i];

      canvas.drawCircle(Offset(g.x, g.y), 0.2, paintGoal);
      canvas.drawCircle(Offset(g.x, g.y), 0.2, paintGoalBorder);

      canvas.save();
      canvas.translate(g.x, g.y);
      canvas.scale(1 / scale, -1 / scale);

      // Cấu hình chữ
      final textSpan = TextSpan(
        text: "${i + 1}",
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
    // 4. VẼ ROBOT
    if (robotPose != null) {
      canvas.drawCircle(Offset(robotPose!.x, robotPose!.y), 0.2, paintRobot);

      final paintHead = Paint()
        ..color = const Color.fromARGB(255, 152, 14, 28)
        ..strokeWidth = 0.05
        ..strokeCap = StrokeCap.round;

      double arrowLen = 0.4;

      canvas.drawLine(
          Offset(robotPose!.x, robotPose!.y),
          Offset(robotPose!.x + arrowLen * math.cos(robotPose!.yaw),
              robotPose!.y + arrowLen * math.sin(robotPose!.yaw)),
          paintHead);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
