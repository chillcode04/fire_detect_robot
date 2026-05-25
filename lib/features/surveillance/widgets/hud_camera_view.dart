import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:provider/provider.dart';

import '../../../providers/connection_provider.dart';
import '../../../providers/surveillance_provider.dart';

class HudCameraView extends StatelessWidget {
  const HudCameraView({super.key});

  final Color primaryRed = const Color.fromARGB(255, 250, 115, 117);

  @override
  Widget build(BuildContext context) {
    final connProvider = context.watch<ConnectionProvider>();
    final survProvider = context.watch<SurveillanceProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: connProvider.isConnected && connProvider.ipAddress.isNotEmpty
                ? Mjpeg(
                    stream: survProvider.getCameraStreamUrl(),
                    isLive: true,
                    fit: BoxFit.contain,
                    error: (context, error, stack) => const Center(
                      child: Text("MẤT TÍN HIỆU CAMERA",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    loading: (context) => Center(
                        child: CircularProgressIndicator(color: primaryRed)),
                  )
                : const Center(
                    child: Icon(Icons.videocam_off,
                        color: Colors.white24, size: 50)),
          ),
          Center(
            child:
                Icon(Icons.add, color: primaryRed.withOpacity(0.5), size: 40),
          ),
          if (survProvider.isAlarmActive)
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: survProvider.alarmType == 'SMOKE'
                          ? Colors.orangeAccent
                          : Colors.redAccent,
                      width: 3),
                  color: (survProvider.alarmType == 'SMOKE'
                          ? Colors.orangeAccent
                          : Colors.redAccent)
                      .withOpacity(0.1)),
              child: Center(
                child: Text(
                    survProvider.alarmType == 'SMOKE'
                        ? "💨 SMOKE DETECTED 💨"
                        : "🔥 FIRE DETECTED 🔥",
                    style: TextStyle(
                        color: survProvider.alarmType == 'SMOKE'
                            ? Colors.orangeAccent
                            : Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
              ),
            )
        ],
      ),
    );
  }
}
