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
  // Đảm bảo các dịch vụ hệ thống của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 1. TỐI ƯU MOBILE: Ẩn thanh trạng thái (Pin, Giờ) và thanh điều hướng ảo
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 2. TỐI ƯU MOBILE: Khóa hướng màn hình luôn luôn là chiều DỌC
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      // 3. ĐẤU NỐI PROVIDERS: Để dữ liệu chạy xuyên suốt các màn hình
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
      debugShowCheckedModeBanner: false, // Tắt cái nhãn "Debug" ở góc màn hình

      // Thiết lập tông màu tối cho App chuyên dụng
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676), // Màu xanh Neon chủ đạo
          brightness: Brightness.dark,
        ),
      ),

      // Chỉ định HomePage của bạn làm màn hình khởi đầu
      home: const HomePage(),
    );
  }
}
