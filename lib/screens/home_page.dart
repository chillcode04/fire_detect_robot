import 'package:flutter/material.dart';
import '../providers/robot_provider.dart';
import '../widgets/manual_control_tab.dart';
import '../widgets/waypoint_tab.dart';
import '../config/app_config.dart';
import '../widgets/robot_camera.dart';
import '../widgets/map_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RobotProvider _provider = RobotProvider();
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.defaultWsUrl);
  }

  @override
  void dispose() {
    _provider.disconnect();
    _provider.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _getIpFromUrl(String url) {
    try {
      if (url.isEmpty) return '192.168.1.15';
      String cleanUrl = url.replaceAll('ws://', '').replaceAll('wss://', '');
      return cleanUrl.split(':')[0];
    } catch (e) {
      return '192.168.1.15';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0F15),
          body: SafeArea(
            child: Column(
              children: [
               
                _buildCustomAppBar(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  color: Colors.black26,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: TextField(
                            controller: _urlController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white10,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.wifi,
                                  color: Colors.grey, size: 16),
                              hintText: "ws://127.0.0.1:9090",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 35,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _provider.isConnected
                                ? Colors.red.withOpacity(0.8)
                                : const Color(0xFF00E5FF),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                          onPressed: () {
                            if (_provider.isConnected) {
                              _provider.disconnect();
                            } else {
                              _provider.connect(_urlController.text);
                            }
                          },
                          child: Icon(
                              _provider.isConnected
                                  ? Icons.power_settings_new
                                  : Icons.link,
                              color: Colors.white,
                              size: 18),
                        ),
                      )
                    ],
                  ),
                ),

              
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          const TabBar(
                            indicatorColor: Color(0xFF00E5FF),
                            labelColor: Color(0xFF00E5FF),
                            unselectedLabelColor: Colors.grey,
                            tabs: [
                              Tab(
                                  icon: Icon(Icons.gamepad_outlined),
                                  text: "MANUAL"),
                              Tab(
                                  icon: Icon(Icons.route_outlined),
                                  text: "AUTO"),
                              Tab(icon: Icon(Icons.map_outlined), text: "MAP"),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Container(
                                        width: double.infinity,
                                        color: Colors.black,
                                        child: Stack(
                                          children: [
                                            Row(
                                              children: [
                                                // Left stats
                                                Container(
                                                  width: 90,
                                                  color: Colors.black,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      _buildSideStats(
                                                        "POS X",
                                                        (_provider.odom?.x ??
                                                                0.0)
                                                            .toStringAsFixed(2),
                                                        const Color(0xFF00E5FF),
                                                        Icons.unfold_more,
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      _buildSideStats(
                                                        "POS Y",
                                                        (_provider.odom?.y ??
                                                                0.0)
                                                            .toStringAsFixed(2),
                                                        const Color(0xFF00E5FF),
                                                        Icons
                                                            .unfold_less_double,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Camera center
                                                Expanded(
                                                  child: ClipRect(
                                                    child: RobotCamera(
                                                      ipAddress: _getIpFromUrl(
                                                          _urlController.text),
                                                      topicName: '/image_raw',
                                                      height: double.infinity,
                                                      width: double.infinity,
                                                    ),
                                                  ),
                                                ),

                                                // Right stats
                                                Container(
                                                  width: 90,
                                                  color: Colors.black,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      _buildSideStats(
                                                        "HEADING",
                                                        "${(_provider.odom?.yaw ?? 0.0).toStringAsFixed(2)} rad",
                                                        Colors.orangeAccent,
                                                        Icons.explore,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Fire overlay
                                            if (_provider.isFireWarning)
                                              Positioned.fill(
                                                child: Container(
                                                  color: Colors.red
                                                      .withOpacity(0.5),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 4),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .redAccent,
                                                                blurRadius: 20)
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                            Icons
                                                                .local_fire_department,
                                                            size: 50,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      const Text(
                                                        "CẢNH BÁO CÓ CHÁY!",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 28,
                                                          shadows: [
                                                            Shadow(
                                                                color: Colors
                                                                    .black,
                                                                blurRadius: 10)
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            if (_provider.isSmokeWarning &&
                                                !_provider
                                                    .isFireWarning) 
                                              Positioned.fill(
                                                child: Container(
                                                  color: Colors.blueGrey
                                                      .withOpacity(
                                                          0.6), 
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Colors
                                                                        .grey[
                                                                    700], 
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white, width: 4),
                                                                boxShadow: const [
                                                              BoxShadow(
                                                                  color: Colors
                                                                      .white24,
                                                                  blurRadius:
                                                                      20)
                                                            ]),
                                                        child: const Icon(
                                                            Icons
                                                                .cloud, 
                                                            size: 50,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      const Text(
                                                        "PHÁT HIỆN KHÓI!",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 28,
                                                            shadows: [
                                                              Shadow(
                                                                  color: Colors
                                                                      .black,
                                                                  blurRadius:
                                                                      10)
                                                            ]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child:
                                          ManualControlTab(provider: _provider),
                                    ),
                                  ],
                                ),
                                WaypointTab(provider: _provider),
                                MapView(
                                    map: _provider.map,
                                    robotPose: _provider.odom,
                                    goals: _provider.goals),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy, color: Color(0xFF00E5FF)),
              ),
              const SizedBox(width: 10),
              const Text(
                "ROS2 COMMANDER",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Icon(Icons.battery_charging_full,
              color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildSideStats(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: 80, 
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)), 
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
