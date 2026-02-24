# Autonomous Mobile Robot for 2D Mapping and Early Fire Detection in Supermarkets
## System Architecture:
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-37-21.png)
- Controller: Raspberry Pi 4 & STM32/ESP32
- Sensors: RPLiDAR, MPU6050 (IMU), USB Camera, Hall Effect Encoders
- Actuators: DC Geared Motors with L298N/Driver
- Framework: ROS2 (Humble/Foxy), OpenCV, YOLO
## Functions:
- 2D environment mapping
- Path planning for inspection
- Early fire detection (broken wires, smoke, old power outlets, etc.)
- Robot control and monitoring via smartphone

## Branch Structure and Responsibilities

- **main**: Contains the main stable codebase.
- **huy**: Focused on combining sensor data for indoor localization, generating 2D maps, and planning patrol routes.
- **long**: Handles sensor reading, motor control, and designing the mobile app for robot monitoring.
- **hai**: Implements early fire detection, including detecting broken wires, smoke, and aging electrical outlets.
## 2D SLAM & Mapping && Navigation
- High-precision environment reconstruction using LiDAR to generate accurate occupancy grid maps
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-37-59.png)
- Real-time pose estimation with sub-centimeter accuracy through sensor fusion.
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-38-27.png)
- Intelligent path planning and obstacle avoidance using the ROS2 Navigation stack.
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-38-57.png)
## Mobile Control App
- Remote Controll: Real-time manual control and robot monitoring.
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-57-15.png)
- Mission Planning: Set autonomous paths and custom waypoints.
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-57-21.png)
- Instant Alerts: Real-time status updates and fire notifications.
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-57-26.png)
## Vision Result 
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-57-54.png)
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-58-07.png)
![image alt](https://github.com/nqhuy18/fire_detect_robot/blob/9c88bdfb7ecd231aa9ada13e656199b3361bbb53/Screenshot%20from%202026-02-24%2019-57-47.png)
## Research
[📄 See here (PDF)](Doc/article1.pdf)
