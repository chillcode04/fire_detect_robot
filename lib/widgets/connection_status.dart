import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/robot_provider.dart';

class ConnectionStatus extends StatelessWidget {
  final RobotProvider provider;
  final TextEditingController urlController;

  const ConnectionStatus({
    super.key,
    required this.provider,
    required this.urlController,
  });

  @override
  Widget build(BuildContext context) {
    final connected = provider.isConnected;
    final odom = provider.odom;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
      
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: urlController,
                  style: const TextStyle(
                      color: Color(0xFF00E5FF), fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.wifi, color: Colors.grey),
                    hintText: "ws://IP:9090",
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (connected) {
                    provider.disconnect();
                  } else {
                    provider.connect(urlController.text);
                  }
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: connected
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF00E5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: connected ? Colors.red : const Color(0xFF00E5FF),
                    ),
                  ),
                  child: Icon(
                    connected ? Icons.power_settings_new : Icons.link,
                    color: connected ? Colors.red : const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Grid (X, Y, Yaw)
          Row(
            children: [
              _buildDataTile("X POS", odom?.x.toStringAsFixed(2)),
              const SizedBox(width: 10),
              _buildDataTile("Y POS", odom?.y.toStringAsFixed(2)),
              const SizedBox(width: 10),
              _buildDataTile(
                  "HEADING",
                  odom != null
                      ? "${(odom.yaw * 180 / math.pi).toStringAsFixed(0)}°"
                      : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTile(String label, String? value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value ?? "--",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
