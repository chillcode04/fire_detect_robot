class AppConfig {
  static const String defaultWsPort = '9090';

  static const String topicCmdVel = '/cmd_vel';
  static const String topicOdom = '/amcl_pose';
  static const String topicGoal = '/goal_pose';
  static const String topicMap = '/map';
  static const String topicEnvSensors = '/env_sensors';

  static const String topicLidar = '/scan';
  static const String topicCamera = '/image_raw';
  static const String topicFireAlarm = '/fire_alarm';
  static const String cameraResultTopic = '/camera_result';

  static const double distThreshold = 0.1;
  static const double angleThreshold = 0.15;
}
