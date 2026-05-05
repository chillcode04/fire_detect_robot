class AppConfig {
  // --- 1. THÔNG SỐ KẾT NỐI MẠNG ---
  static const String defaultWsPort = '9090';

  // --- 2. NHÓM ĐIỀU HƯỚNG & BẢN ĐỒ (Nav2) ---
  static const String topicCmdVel = '/cmd_vel';
  static const String topicOdom = '/odom';
  static const String topicGoal = '/goal_pose';
  static const String topicMap = '/map';
  static const String topicEnvSensors = '/env_sensors';

  // --- 3. NHÓM CẢM BIẾN & GIÁM SÁT HỎA HOẠN ---
  static const String topicBattery = '/battery_state';
  static const String topicLidar = '/scan';
  static const String topicCamera = '/camera/image_raw/compressed';
  static const String topicFireAlarm = '/fire_alarm';
  static const String cameraResultTopic = '/camera_result';

  // --- 4. CÁC THÔNG SỐ NGƯỠNG (THRESHOLDS) ---
  static const double distThreshold = 0.1;
  static const double angleThreshold = 0.15;
}
