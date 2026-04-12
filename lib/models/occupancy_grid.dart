class OccupancyGrid {
  final int width;
  final int height;
  final double resolution;
  final double originX;
  final double originY;
  final List<int> data;

  OccupancyGrid({
    required this.width,
    required this.height,
    required this.resolution,
    required this.originX,
    required this.originY,
    required this.data,
  });

  factory OccupancyGrid.fromJson(Map<String, dynamic> json) {
    final info = json['info'];
    final origin = info['origin'];
    final pos = origin['position'];

    return OccupancyGrid(
      width: (info['width'] as num).toInt(),
      height: (info['height'] as num).toInt(),
      resolution: (info['resolution'] as num).toDouble(),
      originX: (pos['x'] as num).toDouble(),
      originY: (pos['y'] as num).toDouble(),
      data: (json['data'] as List).map((e) => (e as num).toInt()).toList(),
    );
  }
}
