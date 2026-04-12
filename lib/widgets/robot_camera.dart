import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class RobotCamera extends StatelessWidget {
  final String ipAddress;
  final String topicName;
  final double height;
  final double width;

  const RobotCamera({
    super.key,
    required this.ipAddress,
    this.topicName = '/image_raw',
    this.height = 640,
    this.width = 480,
  });

  @override
  Widget build(BuildContext context) {
    int reqWidth = width.isFinite ? width.toInt() : 480;
    int reqHeight = height.isFinite ? height.toInt() : 640;

    final String streamUrl =
        'http://$ipAddress:8080/stream?topic=$topicName&type=mjpeg&default_transport=compressed&width=1280&height=720&quality=30&qos_profile=sensor_data';
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lớp 1: Video Stream
          Mjpeg(
            isLive: true,
            stream: streamUrl,
            fit: BoxFit.fill,
            error: (context, error, stack) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.red, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      'NO SIGNAL\n$ipAddress',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              );
            },
            loading: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),

          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final centerPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx - 20, cy), Offset(cx + 20, cy), centerPaint);
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx, cy + 20), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
