import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thư viện để can thiệp vào hệ thống điện thoại
import 'package:provider/provider.dart';

// Import các "não bộ" quản lý trạng thái
import 'providers/connection_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/surveillance_provider.dart';

// Import màn hình HUD Cyberpunk của bạn
import 'features/dashboard/screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 2. TỐI ƯU MOBILE: Khóa hướng màn hình luôn luôn là chiều DỌC
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => SurveillanceProvider()),
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROS 2 HUD Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 238, 237, 237),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 228, 109, 111),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
