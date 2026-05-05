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

  // 🌟 BẢNG MÀU ĐỒNG BỘ ĐỎ - TRẮNG
  final Color primaryRed = const Color.fromARGB(255, 237, 109, 109);
  final Color mapBackground = const Color(0xFFF9F9F9); // Trắng xám nhạt

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
        color: mapBackground, // 🌟 Nền trắng thay vì đen
        border: Border.all(
            color: primaryRed.withOpacity(0.5), width: 1.5), // 🌟 Viền đỏ
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
              ? Center(
                  child: Text("AWAITING SLAM MAP DATA...",
                      style: TextStyle(
                          color: primaryRed, // 🌟 Chữ báo lỗi màu đỏ
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')),
                )
              : Center(
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    maxScale: 10.0,
                    minScale: 0.1,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(2000),
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
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            backgroundColor: primaryRed, // 🌟 Thông báo màu đỏ
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: navProvider.mapWidth.toDouble(),
                        height: navProvider.mapHeight.toDouble(),
                        child: Stack(
                          children: [
                            // LỚP BẢN ĐỒ SLAM TĨNH
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

                            // LỚP ROBOT ĐỘNG
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

          // ==========================================
          // CÁC NÚT CÔNG CỤ (ZOOM, CENTER)
          // ==========================================
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

          // THÔNG TIN ĐỘ PHÂN GIẢI
          Positioned(
            bottom: 10,
            left: 10,
            child: Text(
                "RESOLUTION: ${navProvider.mapResolution} m/px\nGRID: MAP ACTIVE",
                style: TextStyle(
                    color: Colors.black54, // 🌟 Chữ đen mờ trên nền trắng
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
            color: Colors.white, // 🌟 Nút màu trắng
            borderRadius:
                BorderRadius.circular(8), // Thêm bo góc cho nút mềm mại hơn
            border: Border.all(color: primaryRed.withOpacity(0.5))),
        child: Icon(icon, color: primaryRed, size: 20), // 🌟 Icon màu đỏ
      ),
    );
  }
}

// ==========================================
// PAINTER TĨNH: LỚP GRID
// ==========================================
class GridLayerPainter extends CustomPainter {
  final double mapResolution;
  GridLayerPainter({required this.mapResolution});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color =
          Colors.black12 // 🌟 Lưới mờ màu xám đen để nhìn rõ trên nền trắng
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
// PAINTER TĨNH: VẼ IMAGE & WAYPOINT
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
    canvas.drawImage(slamImage, Offset.zero, Paint());

    // Vẽ Waypoints
    final pointPaint = Paint()..color = Colors.red; // 🌟 Điểm màu Đỏ
    final borderPaint = Paint()
      ..color = Colors.white // 🌟 Viền màu trắng bao quanh điểm đỏ
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < waypoints.length; i++) {
      final pos = _toPixel(waypoints[i].x, waypoints[i].y);
      canvas.drawCircle(pos, 3.0, pointPaint);
      canvas.drawCircle(pos, 3.0, borderPaint);

      TextPainter tp = TextPainter(
        text: TextSpan(
            style: const TextStyle(
                color: Colors.white, // 🌟 Số thứ tự màu trắng
                fontSize: 4.0,
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
// PAINTER ĐỘNG: VẼ ROBOT
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
      ..color = Colors.red // 🌟 Mũi tên robot màu Đỏ
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(5, 0);
    path.lineTo(-4, 4);
    path.lineTo(-2, 0);
    path.lineTo(-4, -4);
    path.close();

    canvas.drawPath(path, robotPaint);

    canvas.drawCircle(
        Offset.zero,
        15,
        Paint()
          ..color = Colors.red.withOpacity(0.15)
          ..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotLayerPainter oldDelegate) => true;
}
