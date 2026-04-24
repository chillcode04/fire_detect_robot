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
  final Color neonGreen = const Color(0xFF00E676);
  final Color darkPanel = const Color(0xFF111111);

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
      color: Colors.black,
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
                    color: neonGreen,
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
                    color: Colors.cyanAccent,
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
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: darkPanel,
              hintText: 'Nhập tên Waypoint để tìm...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: neonGreen.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                // 🌟 Thêm chữ Input vào đây
                borderSide: const BorderSide(color: Colors.white12, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                // 🌟 Thêm chữ Input vào đây
                borderSide:
                    BorderSide(color: neonGreen.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 15),

          // ==========================================
          // 3. CHỌN CHẾ ĐỘ CHẠY (LIÊN TỤC / DỪNG 5S)
          // ==========================================
          Row(
            children: [
              Expanded(
                  child: _buildModeButton(
                      navProvider, RunMode.continuous, 'LIÊN TỤC')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildModeButton(
                      navProvider, RunMode.stop5s, 'DỪNG 5 GIÂY')),
            ],
          ),
          const SizedBox(height: 20),

          // ==========================================
          // 4. DANH SÁCH WAYPOINT (CÓ THỂ KÉO THẢ)
          // ==========================================
          Expanded(
            child: waypoints.isEmpty
                ? const Center(
                    child: Text(
                      "KHÔNG TÌM THẤY WAYPOINT",
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  )
                : Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor:
                          Colors.transparent, // Nền trong suốt khi đang kéo
                    ),
                    child: ReorderableListView.builder(
                      itemCount: waypoints.length,
                      onReorder: (oldIndex, newIndex) {
                        // Tính toán đúng index trong list gốc
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
                        // Tìm đúng index gốc
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
          color: isActive ? neonGreen.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? neonGreen : Colors.white12,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? neonGreen : Colors.white54,
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
        color: isActive ? neonGreen.withOpacity(0.05) : darkPanel,
        border: Border(
            left: BorderSide(
                color: isActive ? Colors.cyanAccent : neonGreen,
                width: isActive ? 5 : 3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

        // 🌟 CHỌN NHANH ĐIỂM ĐẾN
        onTap: () {
          for (var item in provider.waypoints) {
            if (item.status != WaypointStatus.completed) {
              item.status = WaypointStatus.pending;
            }
          }
          wp.status = WaypointStatus.active;
          // Thông báo cho UI vẽ lại (hàm selectWaypoint đã gọi notifyListeners)
          provider.selectWaypoint(actualIndex);
        },

        // 🌟 SỬA TÊN BẰNG LONG PRESS
        onLongPress: () =>
            _showRenameDialog(context, wp, actualIndex, provider),

        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.cyanAccent.withOpacity(0.2)
              : neonGreen.withOpacity(0.2),
          child: Text('${actualIndex + 1}',
              style: TextStyle(
                  color: isActive ? Colors.cyanAccent : neonGreen,
                  fontWeight: FontWeight.bold)),
        ),
        // 🌟 Bọc Text bằng Row để nhét thêm nút Edit kế bên
        title: Row(
          children: [
            Text(wp.name,
                style: TextStyle(
                    color: isActive ? Colors.cyanAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(width: 8), // Khoảng cách nhỏ

            // 🌟 NÚT EDIT RÕ RÀNG
            GestureDetector(
              onTap: () =>
                  _showRenameDialog(context, wp, actualIndex, provider),
              child: const Icon(Icons.edit, color: Colors.white54, size: 16),
            ),
          ],
        ),
        subtitle: Text(
          'X: ${wp.x.toStringAsFixed(2)}  |  Y: ${wp.y.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.white54, fontFamily: 'monospace', fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              const Icon(Icons.directions_run,
                  color: Colors.cyanAccent, size: 20)
            else if (wp.status == WaypointStatus.completed)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => provider.removeWaypoint(actualIndex),
            ),
            const Icon(Icons.drag_handle, color: Colors.white24),
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
          backgroundColor: darkPanel,
          title: Text("Đổi Tên Waypoint",
              style: TextStyle(color: neonGreen, fontSize: 16)),
          content: TextField(
            controller: renameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: neonGreen)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("HỦY", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen.withOpacity(0.2)),
              onPressed: () {
                if (renameController.text.isNotEmpty) {
                  provider.renameWaypoint(index, renameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text("LƯU", style: TextStyle(color: neonGreen)),
            ),
          ],
        );
      },
    );
  }
}
