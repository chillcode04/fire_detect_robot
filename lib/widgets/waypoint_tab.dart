import 'package:flutter/material.dart';
import '../providers/robot_provider.dart';

class WaypointTab extends StatelessWidget {
  final RobotProvider provider;

  const WaypointTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                  child: _buildActionBtn(
                      "ADD POINT",
                      Icons.add_location_alt,
                      provider.odom != null
                          ? provider.addGoalFromCurrentPose
                          : null)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionBtn(
                      "START AUTO",
                      Icons.play_arrow,
                      (provider.goals.isNotEmpty &&
                              provider.currentGoalIndex == -1)
                          ? () => provider.startAuto(0, singleMode: false)
                          : null,
                      isPrimary: true)),
              const SizedBox(width: 12),
              _buildIconButton(Icons.stop, Colors.red, provider.stop),
            ],
          ),
        ),

        // List
        Expanded(
          child: provider.goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map,
                          size: 64, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text("NO WAYPOINTS DEFINED",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              letterSpacing: 1)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.goals.length,
                  itemBuilder: (context, index) {
                    final goal = provider.goals[index];
                    final isRunning = index == provider.currentGoalIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? const Color(0xFF00E5FF).withOpacity(0.1)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRunning
                              ? const Color(0xFF00E5FF)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? const Color(0xFF00E5FF)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("${index + 1}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isRunning ? Colors.black : Colors.white)),
                        ),
                        title: Text(goal.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "X: ${goal.x.toStringAsFixed(2)}  Y: ${goal.y.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: Icon(Icons.directions_run,
                                    color: isRunning
                                        ? const Color(0xFF00E5FF)
                                        : Colors.grey),
                                onPressed: () => provider.startAuto(index,
                                    singleMode: true)),
                            IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.grey.withOpacity(0.5)),
                                onPressed: () => provider.deleteGoal(index)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback? onTap,
      {bool isPrimary = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? const Color(0xFF00E5FF) : const Color(0xFF2C2C2C),
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        disabledBackgroundColor: Colors.white.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isPrimary && onTap != null ? 10 : 0,
        shadowColor: const Color(0xFF00E5FF).withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
