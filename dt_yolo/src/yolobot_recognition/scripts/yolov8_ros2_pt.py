#!/usr/bin/env python3
import json
from std_msgs.msg import String

from ultralytics import YOLO
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CompressedImage
from sensor_msgs.msg import Image
import numpy as np
import cv2

from cv_bridge import CvBridge

from yolov8_msgs.msg import InferenceResult
from yolov8_msgs.msg import Yolov8Inference

bridge = CvBridge()

class Camera_subscriber(Node):

    def __init__(self):
        super().__init__('camera_subscriber')

        self.model = YOLO('/home/nqh/dt_yolo/src/yolobot_recognition/scripts/fire_robot.pt')

        self.yolov8_inference = Yolov8Inference()

        self.subscription = self.create_subscription(
            Image,
            '/image_raw',
            self.camera_callback,
            10)

        self.yolov8_pub = self.create_publisher(Yolov8Inference, "/Yolov8_Inference", 1)
        self.img_pub = self.create_publisher(Image, "/inference_result", 1)
        self.app_result_pub = self.create_publisher(String, '/camera_result', 10)

    def camera_callback(self, data):

        np_arr = np.frombuffer(data.data, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        results = self.model(img, conf=0.1)

        self.yolov8_inference.header.frame_id = "inference"
        self.yolov8_inference.header.stamp = camera_subscriber.get_clock().now().to_msg()
        app_detected_objects = []
        
        for r in results:
            boxes = r.boxes
            for box in boxes:
                self.inference_result = InferenceResult()
                b = box.xyxy[0].to('cpu').detach().numpy().copy()  # get box coordinates in (top, left, bottom, right) format
                c = box.cls
                self.inference_result.class_name = self.model.names[int(c)]
                self.inference_result.top = int(b[0])
                self.inference_result.left = int(b[1])
                self.inference_result.bottom = int(b[2])
                self.inference_result.right = int(b[3])
                self.yolov8_inference.yolov8_inference.append(self.inference_result)

                obj_info = {
                    "class": self.inference_result.class_name,
                    "score": float(box.conf),
                    "box": [int(b[0]), int(b[1]), int(b[2]), int(b[3])] # [top, left, bottom, right]
                }
                app_detected_objects.append(obj_info)

        if len(app_detected_objects) > 0:
            json_msg = String()
            data_to_send = {
                "status": "detected",
                "count": len(app_detected_objects),
                "objects": app_detected_objects
            }
            json_msg.data = json.dumps(data_to_send)
            self.app_result_pub.publish(json_msg)
        else:
            pass

        annotated_frame = results[0].plot()
        img_msg = bridge.cv2_to_imgmsg(annotated_frame)  

        self.img_pub.publish(img_msg)
        self.yolov8_pub.publish(self.yolov8_inference)
        self.yolov8_inference.yolov8_inference.clear()

if __name__ == '__main__':
    rclpy.init(args=None)
    camera_subscriber = Camera_subscriber()
    rclpy.spin(camera_subscriber)
    rclpy.shutdown()
