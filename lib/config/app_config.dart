class AppConfig {
  static const String defaultWsUrl = 'ws://127.0.0.1:9090';
  //static const String defaultWsUrl = 'ws://10.82.185.32:9090';
  // SỬA DÒNG NÀY (Thêm /turtle1):
  //static const String topicOdom = '/amcl_pose';
  static const String topicOdom = '/odom_data';

  static const String topicCmdVel = '/cmd_vel';

  static const String topicGoal = '/goal_pose';
  static const String topicMap = '/map';

  static const double distThreshold = 0.1; // 10cm là coi như đến đích
  static const double angleThreshold = 0.15; // ~8.5 độ

  static const double kP_Linear = 0.8; // Hệ số P vận tốc thẳng
  static const double kP_Angular = 2.5; // Hệ số P vận tốc xoay

  static const double maxLinearSpeed = 0.5;
  static const double maxAngularSpeed = 1.5;
}
