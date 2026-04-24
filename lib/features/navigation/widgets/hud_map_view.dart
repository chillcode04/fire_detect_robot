import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/navigation_provider.dart';

class HudMapView extends StatefulWidget {
  const HudMapView({super.key});

  @override
  State<HudMapView> createState() => _HudMapViewState();
}

class _HudMapViewState extends State<HudMapView> {
  final TransformationController _viewController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerRobot();
    });
  }

  void _zoomIn() => setState(
      () => _viewController.value = _viewController.value.clone()..scale(1.5));
  void _zoomOut() => setState(
      () => _viewController.value = _viewController.value.clone()..scale(0.66));

  void _centerRobot() {
    final nav = context.read<NavigationProvider>();
    if (nav.mapWidth == 0) return;

    double zoom = 4.0;
    double px = (nav.currentX - nav.mapOriginX) / nav.mapResolution;
    double py =
        nav.mapHeight - ((nav.currentY - nav.mapOriginY) / nav.mapResolution);

    double centerX = 300.0;
    double centerY = 150.0;

    setState(() {
      _viewController.value = Matrix4.identity()
        ..translate(centerX - (px * zoom), centerY - (py * zoom))
        ..scale(zoom);
    });
  }

  @override
  void dispose() {
    _viewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border:
            Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ==========================================
          // LỚP 1: LƯỚI GRID ĐIỀU HƯỚNG
          // ==========================================
          Center(
            child: InteractiveViewer(
              transformationController: _viewController,
              maxScale: 10.0,
              minScale: 0.1,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(2000),
              child: SizedBox(
                width: navProvider.mapWidth.toDouble(),
                height: navProvider.mapHeight.toDouble(),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: GridLayerPainter(
                      mapResolution: navProvider.mapResolution),
                ),
              ),
            ),
          ),

          // ==========================================
          // KHU VỰC CHÍNH: MAP SLAM & ROBOT & WAYPOINT
          // ==========================================
          navProvider.slamImage == null
              ? const Center(
                  child: Text("AWAITING SLAM MAP DATA...",
                      style: TextStyle(
                          color: Colors.cyanAccent, fontFamily: 'monospace')),
                )
              : Center(
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    maxScale: 10.0,
                    minScale: 0.1,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(2000),
                    // 🌟 BỌC GESTURE DETECTOR Ở ĐÂY ĐỂ CẮM CỜ
                    child: GestureDetector(
                      onTapUp: (TapUpDetails details) {
                        double px = details.localPosition.dx;
                        double py = details.localPosition.dy;

                        double realX = (px * navProvider.mapResolution) +
                            navProvider.mapOriginX;
                        double realY = navProvider.mapOriginY +
                            ((navProvider.mapHeight - py) *
                                navProvider.mapResolution);

                        int nextNum = navProvider.waypoints.length + 1;
                        context
                            .read<NavigationProvider>()
                            .addWaypoint("WP $nextNum", realX, realY);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📍 Đã thêm WP $nextNum',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFF00E676),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: navProvider.mapWidth.toDouble(),
                        height: navProvider.mapHeight.toDouble(),
                        child: Stack(
                          children: [
                            // 🌟 LỚP BẢN ĐỒ SLAM TĨNH (Dùng ui.Image)
                            CustomPaint(
                              size: Size.infinite,
                              painter: StaticMapPainter(
                                slamImage: navProvider.slamImage!,
                                width: navProvider.mapWidth,
                                height: navProvider.mapHeight,
                                resolution: navProvider.mapResolution,
                                originX: navProvider.mapOriginX,
                                originY: navProvider.mapOriginY,
                                waypoints: navProvider.waypoints,
                              ),
                            ),

                            // 🌟 LỚP ROBOT ĐỘNG (Lái mượt 30Hz)
                            CustomPaint(
                              size: Size.infinite,
                              painter: RobotLayerPainter(
                                height: navProvider.mapHeight,
                                resolution: navProvider.mapResolution,
                                originX: navProvider.mapOriginX,
                                originY: navProvider.mapOriginY,
                                robotX: navProvider.currentX,
                                robotY: navProvider.currentY,
                                robotYaw: navProvider.currentYaw,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

          // Các Nút Công Cụ và Ghi chú giữ nguyên...
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _buildMapTool(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _buildMapTool(Icons.remove, _zoomOut),
                const SizedBox(height: 10),
                _buildMapTool(Icons.my_location, _centerRobot),
              ],
            ),
          ),

          Positioned(
            bottom: 10,
            left: 10,
            child: Text(
                "RESOLUTION: ${navProvider.mapResolution} m/px\nGRID: MAP ACTIVE",
                style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'monospace')),
          )
        ],
      ),
    );
  }

  Widget _buildMapTool(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(color: Colors.cyanAccent)),
        child: Icon(icon, color: Colors.cyanAccent, size: 20),
      ),
    );
  }
}

// ==========================================
// PAINTER TĨNH: LỚP GRID (Để map đỡ chìm)
// ==========================================
class GridLayerPainter extends CustomPainter {
  final double mapResolution;
  GridLayerPainter({required this.mapResolution});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.05)
      ..strokeWidth = 1.0;

    double stepX = 20.0;
    double stepY = 20.0;

    for (double i = 0; i < size.width; i += stepX) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += stepY) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLayerPainter oldDelegate) => false;
}

// ==========================================
// 🌟 TÁCH LỚP 1: PAINTER TĨNH (VẼ IMAGE & WAYPOINT)
// ==========================================
class StaticMapPainter extends CustomPainter {
  final ui.Image slamImage;
  final int width;
  final int height;
  final double resolution;
  final double originX;
  final double originY;
  final List<Waypoint> waypoints;

  StaticMapPainter({
    required this.slamImage,
    required this.width,
    required this.height,
    required this.resolution,
    required this.originX,
    required this.originY,
    required this.waypoints,
  });

  Offset _toPixel(double realX, double realY) {
    double px = (realX - originX) / resolution;
    double py = height - ((realY - originY) / resolution);
    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 🌟 KHÔNG CÒN VÒNG LẶP FOR NỮA. CHỈ CẦN 1 LỆNH VẼ ẢNH!
    canvas.drawImage(slamImage, Offset.zero, Paint());

    // Vẽ Waypoints
    final pointPaint = Paint()..color = Colors.cyanAccent;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < waypoints.length; i++) {
      final pos = _toPixel(waypoints[i].x, waypoints[i].y);
      canvas.drawCircle(pos, 2.5, pointPaint);
      canvas.drawCircle(pos, 2.5, borderPaint);

      TextPainter tp = TextPainter(
        text: TextSpan(
            style: const TextStyle(
                color: Colors.black,
                fontSize: 3.5,
                fontWeight: FontWeight.bold),
            text: '${i + 1}'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant StaticMapPainter oldDelegate) => true;
}

// ==========================================
// TÁCH LỚP 2: PAINTER ĐỘNG (CHỈ VẼ ROBOT)
// ==========================================
class RobotLayerPainter extends CustomPainter {
  final int height;
  final double resolution;
  final double originX;
  final double originY;
  final double robotX;
  final double robotY;
  final double robotYaw;

  RobotLayerPainter({
    required this.height,
    required this.resolution,
    required this.originX,
    required this.originY,
    required this.robotX,
    required this.robotY,
    required this.robotYaw,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double px = (robotX - originX) / resolution;
    double py = height - ((robotY - originY) / resolution);

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(-robotYaw * pi / 180);

    final robotPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(4, 0);
    path.lineTo(-3, 3);
    path.lineTo(-1.5, 0);
    path.lineTo(-3, -3);
    path.close();
    canvas.drawPath(path, robotPaint);

    canvas.drawCircle(
        Offset.zero,
        15,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.2)
          ..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotLayerPainter oldDelegate) => true;
}
