/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * File Name          : freertos.c
  * Description        : Code for freertos applications
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "publish.h"
#include "usart.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
extern double bme_temp;
extern double bme_humi;
extern int cnt_bme;
extern BME280_Data_t BME280;
/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
osMutexId_t i2c3_mutex;
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */

/* USER CODE END Variables */
/* Definitions for myTask1 */
osThreadId_t myTask1Handle;
const osThreadAttr_t myTask1_attributes = {
  .name = "myTask1",
  .stack_size = 3000 * 4,
  .priority = (osPriority_t) osPriorityAboveNormal,
};
/* Definitions for myTask02 */
osThreadId_t myTask02Handle;
const osThreadAttr_t myTask02_attributes = {
  .name = "myTask02",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal2,
};
/* Definitions for myTask03 */
osThreadId_t myTask03Handle;
const osThreadAttr_t myTask03_attributes = {
  .name = "myTask03",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal2,
};
osThreadId_t Task_BMEHandle;
const osThreadAttr_t Task_BME_attributes = {
  .name = "Task_BME",
  .stack_size = 256 * 4,    // Tăng lên 256 để xử lý toán số thực an toàn
  .priority = (osPriority_t) osPriorityNormal,
};

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

/* USER CODE END FunctionPrototypes */

void Task_pub_sub(void *argument);
void Task_IMU(void *argument);
void Task_control(void *argument);
void Task_BME(void *argument);
void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */
extern PID_TypeDef YPID;
/**
  * @brief  FreeRTOS initialization
  * @param  None
  * @retval None
  */
void MX_FREERTOS_Init(void) {
  /* USER CODE BEGIN Init */
	i2c3_mutex = osMutexNew(NULL);
  /* USER CODE END Init */

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of myTask1 */
  myTask1Handle = osThreadNew(Task_pub_sub, NULL, &myTask1_attributes);

  /* creation of myTask02 */
//  myTask02Handle = osThreadNew(Task_IMU, NULL, &myTask02_attributes);

  /* creation of myTask03 */
  myTask03Handle = osThreadNew(Task_control, NULL, &myTask03_attributes);

  Task_BMEHandle = osThreadNew(Task_BME, NULL, &Task_BME_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

}

/* USER CODE BEGIN Header_Task_pub_sub */
/**
  * @brief  Function implementing the myTask1 thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_Task_pub_sub */
void Task_pub_sub(void *argument)
{
  /* USER CODE BEGIN 5 */

	  // micro-ROS configuration

	  rmw_uros_set_custom_transport(
	    true,
	    (void *) &huart2,
	    cubemx_transport_open,
	    cubemx_transport_close,
	    cubemx_transport_write,
	    cubemx_transport_read);

	  rcl_allocator_t freeRTOS_allocator = rcutils_get_zero_initialized_allocator();
	  freeRTOS_allocator.allocate = microros_allocate;
	  freeRTOS_allocator.deallocate = microros_deallocate;
	  freeRTOS_allocator.reallocate = microros_reallocate;
	  freeRTOS_allocator.zero_allocate =  microros_zero_allocate;

	  if (!rcutils_set_default_allocator(&freeRTOS_allocator)) {
	      printf("Error on default allocators (line %d)\n", __LINE__);
	  }

	 // Initialize micro-ROS allocator
	 allocator = rcl_get_default_allocator();

	 // create init_options
	 rclc_support_init(&support, 0, NULL, &allocator);


	 //create node_sub
	 rclc_node_init_default(&node, "stm32_node","", &support);

	  // create publisher
	 rclc_publisher_init_default(
	    &odom_pub,
	    &node,
		ROSIDL_GET_MSG_TYPE_SUPPORT(nav_msgs, msg, Odometry),
	    "/odom_data");

	 rclc_publisher_init_default(
	 	    &temp_pub,
	 	    &node,
	 	    ROSIDL_GET_MSG_TYPE_SUPPORT(sensor_msgs, msg, Temperature),
	 	    "/bme280/temperature");

	 	rclc_publisher_init_default(
	 	    &humi_pub,
	 	    &node,
	 	    ROSIDL_GET_MSG_TYPE_SUPPORT(sensor_msgs, msg, RelativeHumidity),
	 	    "/bme280/humidity");



	//create subscriber
	rclc_subscription_init_default(
		&subscriber,
		&node,
		ROSIDL_GET_MSG_TYPE_SUPPORT(geometry_msgs, msg, Twist),
		"/cmd_vel");

	rclc_publisher_init_default(
	    &tf_pub,
	    &node,
	    ROSIDL_GET_MSG_TYPE_SUPPORT(tf2_msgs, msg, TFMessage),
	    "/tf");
	// create timer
	rcl_timer_t timer;
	const unsigned int timer_timeout = 50;
	RCCHECK(rclc_timer_init_default(
		&timer,
		&support,
		RCL_MS_TO_NS(timer_timeout),
		timer_callback));

	// create executor
	rclc_executor_t executor = rclc_executor_get_zero_initialized_executor();
	rclc_executor_init(&executor, &support.context, 4, &allocator);


	// add subscriber callback to the executor
	rclc_executor_add_subscription(&executor, &subscriber, &msg_cmd_vel, &cmd_vel_callback, ON_NEW_DATA);
	// add time for executor
	rclc_executor_add_timer(&executor, &timer);

    if (rmw_uros_sync_session(1) != RMW_RET_OK) {
        printf("Time sync failed\n");
    }
    // init data odom
    odom_msg.header.frame_id.data = "odom";
    odom_msg.child_frame_id.data  = "base_link";

    tf.header.frame_id.data = "odom";
    tf.child_frame_id.data = "base_link";
    int counter = 0;
	while(1) {
		cnt_pub++;
		rclc_executor_spin_some(&executor, RCL_MS_TO_NS(10));
		if (++counter % 100 == 0) {
		    rmw_uros_sync_session(100);
		}
		rclc_executor_spin_some(&executor, RCL_MS_TO_NS(10));
		vTaskDelay(pdMS_TO_TICKS(1));
	}
  /* USER CODE END 5 */
}

/* USER CODE BEGIN Header_Task_IMU */
/**
* @brief Function implementing the myTask02 thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_Task_IMU */
void Task_IMU(void *argument)
{
  /* USER CODE BEGIN Task_IMU */
  /* Infinite loop */
  while(1) {
	  MPU6050_Read_All(&MPU6050);
	  cnt_imu++;
	  vTaskDelay(pdMS_TO_TICKS(1));
  }
  /* USER CODE END Task_IMU */
}
/* USER CODE BEGIN Header_Task_control */
/**
* @brief Function implementing the myTask03 thread.
* @param argument: Not used
* @retval None
*/

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  if (htim->Instance == TIM1) {
      Motor_GetSpeed(&Left_motor);
      vl_cur = Left_motor.cur_speed;
	  PID_Compute(&LPID);
	  Motor_GetSpeed(&Right_motor);
	  vr_cur = Right_motor.cur_speed;
	  PID_Compute(&RPID);
      Motor_SetPwm(&Left_motor);
      Motor_SetPwm(&Right_motor);
   }
}
/* USER CODE END Task_control */
void Task_control(void *argument)
{

    while (1)
    {
    	cnt_control++;
        vl_cur_mps = vl_cur * ((2.0f * 3.1415926f * WHEEL_RADIUS_M)) / 60;   // rpm -> mps
        vr_cur_mps = vr_cur * ((2.0f * 3.1415926f * WHEEL_RADIUS_M)) / 60;   // rpm -> mps
        Drive_VW(&Left_motor, &Right_motor, v_mps, omega);
        vTaskDelay(pdMS_TO_TICKS(1));
    }
}


/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */
void Task_BME(void *argument) {
    for (;;) {
        osMutexAcquire(i2c3_mutex, osWaitForever);
        BME280Calculation(&BME280);

        if (BME280.Humidity == 0.0f || BME280.Temperature == 0.0f) {
            HAL_I2C_DeInit(&hi2c3);
            osMutexRelease(i2c3_mutex);
            osDelay(10);
            osMutexAcquire(i2c3_mutex, osWaitForever);
            MX_I2C3_Init();
            Calibdata_BME280();
        }

        osMutexRelease(i2c3_mutex);

        bme_temp = (double)BME280.Temperature;
        bme_humi = (double)BME280.Humidity;
        cnt_bme++;

        osDelay(1000);
    }
}

/* USER CODE END Application */
