import 'package:flutter/material.dart';
import '../providers/robot_provider.dart';
import 'robot_camera.dart';

class ManualControlTab extends StatelessWidget {
  final RobotProvider provider;

  const ManualControlTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final connected = provider.isConnected;

   
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // --- Speed Sliders ---
            _buildSlider("LINEAR VELOCITY", provider.manualLinearX, 1.0, (v) {
              provider.setManualSpeed(v, provider.manualAngularZ);
            }),
            const SizedBox(height: 8),
            _buildSlider("ANGULAR VELOCITY", provider.manualAngularZ, 2.0, (v) {
              provider.setManualSpeed(provider.manualLinearX, v);
            }),

            const SizedBox(height: 20), 

          
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(
                    177, 27, 1, 1), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(4, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1), 
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
              
                  Positioned(
                    top: 5,
                    child: _buildPadBtn(
                      icon: Icons.keyboard_arrow_up,
                      onTap: connected
                          ? () => provider.moveManual(provider.manualLinearX, 0)
                          : null,
                    ),
                  ),
                  // DOWN
                  Positioned(
                    bottom: 5,
                    child: _buildPadBtn(
                      icon: Icons.keyboard_arrow_down,
                      onTap: connected
                          ? () =>
                              provider.moveManual(-provider.manualLinearX, 0)
                          : null,
                    ),
                  ),
                  // LEFT
                  Positioned(
                    left: 5,
                    child: _buildPadBtn(
                      icon: Icons.keyboard_arrow_left,
                      onTap: connected
                          ? () =>
                              provider.moveManual(0, provider.manualAngularZ)
                          : null,
                    ),
                  ),
                  // RIGHT
                  Positioned(
                    right: 5,
                    child: _buildPadBtn(
                      icon: Icons.keyboard_arrow_right,
                      onTap: connected
                          ? () =>
                              provider.moveManual(0, -provider.manualAngularZ)
                          : null,
                    ),
                  ),

             
                  GestureDetector(
                    onTap: connected ? provider.stop : null,
                    child: Container(
                      width: 50, 
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E1E1E),
                        border: Border.all(
                            color: connected
                                ? Colors.redAccent
                                : Colors.grey.withOpacity(0.2),
                            width: 2),
                        boxShadow: connected
                            ? [
                                BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(Icons.stop,
                            size: 28, 
                            color: connected ? Colors.redAccent : Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Text(
              "SYSTEM READY",
              style: TextStyle(
                color: connected ? const Color(0xFF00E5FF) : Colors.grey,
                letterSpacing: 2,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPadBtn({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, 
        height: 40,
        decoration: BoxDecoration(
          color:
              onTap != null ? const Color(0xFF222222) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    blurRadius: 5,
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: onTap != null ? const Color(0xFF00E5FF) : Colors.grey[800],
          size: 24, 
        ),
      ),
    );
  }


  Widget _buildSlider(
      String label, double value, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey, letterSpacing: 1)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF))), 
          ],
        ),
        SizedBox(
          height: 30,
          child: Slider(
            value: value,
            min: 0.1,
            max: max,
            onChanged: onChanged,
            activeColor: const Color(0xFF00E5FF), 
            inactiveColor: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
