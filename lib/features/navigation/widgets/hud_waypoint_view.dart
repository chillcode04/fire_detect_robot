import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/navigation_provider.dart';

class HudWaypointView extends StatefulWidget {
  const HudWaypointView({super.key});

  @override
  State<HudWaypointView> createState() => _HudWaypointViewState();
}

class _HudWaypointViewState extends State<HudWaypointView> {
  final TextEditingController _searchController = TextEditingController();

  // 🌟 BẢNG MÀU ĐỒNG BỘ ĐỎ - TRẮNG
  final Color primaryRed = const Color.fromARGB(255, 237, 109, 109);
  final Color lightPanel = const Color(0xFFF0F0F0); // Xám cực nhạt cho các khối
  final Color background = Colors.white; // Nền trắng

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final waypoints = navProvider.filteredWaypoints;

    return Container(
      color: background, // 🌟 Nền tổng thể màu trắng
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. HEADER & NÚT PLAY/PAUSE
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSION CONTROL',
                style: TextStyle(
                    color: primaryRed, // 🌟 Tiêu đề Đỏ
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      navProvider.isNavigating && !navProvider.isPaused
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 32,
                    ),
                    color: primaryRed, // 🌟 Nút Play/Pause Đỏ
                    onPressed: () {
                      if (navProvider.isNavigating) {
                        navProvider.togglePause();
                      } else {
                        navProvider.startMission();
                      }
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 15),

          // ==========================================
          // 2. THANH TÌM KIẾM
          // ==========================================
          TextField(
            controller: _searchController,
            onChanged: (value) => navProvider.updateSearchQuery(value),
            style: const TextStyle(
                color: Colors.black87, fontSize: 13), // 🌟 Chữ đen
            decoration: InputDecoration(
              filled: true,
              fillColor: lightPanel, // 🌟 Nền thanh tìm kiếm xám nhạt
              hintText: 'Nhập tên Waypoint để tìm...',
              hintStyle: const TextStyle(
                  color: Colors.black45, fontSize: 13), // 🌟 Hint xám
              prefixIcon:
                  Icon(Icons.search, color: primaryRed.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Colors.black12, width: 1), // 🌟 Viền xám mờ
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: primaryRed, width: 1), // 🌟 Focus viền đỏ
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 15),

          // ==========================================
          // 3. CHỌN CHẾ ĐỘ CHẠY
          // ==========================================
          Row(
            children: [
              Expanded(
                  child: _buildModeButton(
                      navProvider, RunMode.continuous, 'LIÊN TỤC')),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _buildModeButton(navProvider, RunMode.stop5s, 'DỪNG 5S')),
              const SizedBox(width: 8),
              // Thêm nút mới này
              Expanded(
                  child: _buildModeButton(
                      navProvider, RunMode.single, 'CHẠY 1 ĐIỂM')),
            ],
          ),
          const SizedBox(height: 20),

          // ==========================================
          // 4. DANH SÁCH WAYPOINT
          // ==========================================
          Expanded(
            child: waypoints.isEmpty
                ? const Center(
                    child: Text(
                      "KHÔNG TÌM THẤY WAYPOINT",
                      style: TextStyle(
                          color: Colors.black26, // 🌟 Chữ trống xám mờ
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  )
                : Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      itemCount: waypoints.length,
                      onReorder: (oldIndex, newIndex) {
                        final actualOldIndex = navProvider.waypoints
                            .indexOf(navProvider.filteredWaypoints[oldIndex]);
                        final actualNewIndex =
                            newIndex < navProvider.filteredWaypoints.length
                                ? navProvider.waypoints.indexOf(
                                    navProvider.filteredWaypoints[newIndex])
                                : navProvider.waypoints.length;

                        context
                            .read<NavigationProvider>()
                            .reorderWaypoints(actualOldIndex, actualNewIndex);
                      },
                      itemBuilder: (context, index) {
                        final wp = waypoints[index];
                        final actualIndex = navProvider.waypoints.indexOf(wp);
                        return _buildWaypointItem(wp, actualIndex, navProvider);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Widget Build Nút Chế Độ Chạy ---
  Widget _buildModeButton(
      NavigationProvider provider, RunMode mode, String label) {
    bool isActive = provider.currentRunMode == mode;
    return GestureDetector(
      onTap: () => provider.setRunMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? primaryRed.withOpacity(0.1)
              : lightPanel, // 🌟 Active: nền đỏ nhạt | Inactive: nền xám nhạt
          border: Border.all(
            color:
                isActive ? primaryRed : Colors.black12, // 🌟 Viền đỏ hoặc xám
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:
                isActive ? primaryRed : Colors.black54, // 🌟 Chữ đỏ hoặc đen mờ
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Widget Build Từng Dòng Waypoint ---
  Widget _buildWaypointItem(
      Waypoint wp, int actualIndex, NavigationProvider provider) {
    bool isActive = wp.status == WaypointStatus.active;

    return Container(
      key: ValueKey(wp.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? primaryRed.withOpacity(0.05)
            : lightPanel, // 🌟 Dòng đang chạy sẽ có nền hơi đỏ
        border: Border(
            left: BorderSide(
                color: isActive
                    ? primaryRed
                    : Colors.black26, // 🌟 Vạch bên trái Đỏ hoặc Xám
                width: isActive ? 5 : 3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          for (var item in provider.waypoints) {
            if (item.status != WaypointStatus.completed) {
              item.status = WaypointStatus.pending;
            }
          }
          wp.status = WaypointStatus.active;
          provider.selectWaypoint(actualIndex);
        },
        onLongPress: () =>
            _showRenameDialog(context, wp, actualIndex, provider),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? primaryRed.withOpacity(0.2)
              : Colors.black12, // 🌟 Hình tròn Đỏ nhạt hoặc Xám nhạt
          child: Text('${actualIndex + 1}',
              style: TextStyle(
                  color: isActive ? primaryRed : Colors.black87, // 🌟 Số thứ tự
                  fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Text(wp.name,
                style: TextStyle(
                    color: isActive
                        ? primaryRed
                        : Colors.black87, // 🌟 Tên điểm Đỏ hoặc Đen
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  _showRenameDialog(context, wp, actualIndex, provider),
              child: const Icon(Icons.edit,
                  color: Colors.black38, size: 16), // 🌟 Nút Edit xám mờ
            ),
          ],
        ),
        subtitle: Text(
          'X: ${wp.x.toStringAsFixed(2)}  |  Y: ${wp.y.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.black54,
              fontFamily: 'monospace',
              fontSize: 11), // 🌟 Tọa độ xám mờ
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Icon(Icons.directions_run,
                  color: primaryRed, size: 20) // 🌟 Icon đang chạy màu đỏ
            else if (wp.status == WaypointStatus.completed)
              const Icon(Icons.check_circle,
                  color: Colors.green,
                  size: 20), // Giữ màu xanh lá cho điểm đã hoàn thành
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.black38), // 🌟 Thùng rác xám mờ
              onPressed: () => provider.removeWaypoint(actualIndex),
            ),
            const Icon(Icons.drag_handle,
                color: Colors.black26), // 🌟 Icon kéo xám mờ
          ],
        ),
      ),
    );
  }

  // --- HÀM PHỤ: POPUP ĐỔI TÊN ---
  void _showRenameDialog(BuildContext context, Waypoint wp, int index,
      NavigationProvider provider) {
    TextEditingController renameController =
        TextEditingController(text: wp.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: background, // 🌟 Nền hộp thoại Trắng
          title: Text("Đổi Tên Waypoint",
              style: TextStyle(
                  color: primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          content: TextField(
            controller: renameController,
            style: const TextStyle(
                color: Colors.black87), // 🌟 Chữ nhập vào màu đen
            decoration: InputDecoration(
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: primaryRed)), // 🌟 Gạch chân đỏ khi focus
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("HỦY", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryRed.withOpacity(0.1), // 🌟 Nút lưu nền đỏ nhạt
                  elevation: 0),
              onPressed: () {
                if (renameController.text.isNotEmpty) {
                  provider.renameWaypoint(index, renameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text("LƯU",
                  style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold)), // 🌟 Chữ nút lưu màu đỏ
            ),
          ],
        );
      },
    );
  }
}
