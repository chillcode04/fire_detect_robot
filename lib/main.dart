import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROS2 Controller Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          onPrimary: Colors.black,
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF121212),
          error: Color(0xFFFF1744),
        ),

        // Style cho Card
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 8,
          shadowColor: const Color.fromARGB(255, 72, 0, 255).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),

        // Style cho Slider
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF00E5FF),
          inactiveTrackColor: Colors.white.withOpacity(0.1),
          thumbColor: Colors.white,
          overlayColor: const Color(0xFF00E5FF).withOpacity(0.2),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
      ),
      home: const HomePage(),
    );
  }
}
