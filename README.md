# Autonomous Mobile Robot for 2D Mapping and Early Fire Detection in Supermarkets
## System Architecture:
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
Link image:
- Real-time pose estimation with sub-centimeter accuracy through sensor fusion.
- Intelligent path planning and obstacle avoidance using the ROS2 Navigation stack.
## Mobile Control App
- Remote Controll: Real-time manual control and robot monitoring.
- Mission Planning: Set autonomous paths and custom waypoints.
- Instant Alerts: Real-time status updates and fire notifications.
## Vision Result 
## Research
[📄 See here (PDF)](Doc/article1.pdf)
