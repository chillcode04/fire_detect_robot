/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
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
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "motor.h"
#include "pid.h"
#include "AdaptiveFuzzyPID.h"
#include "mpu.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */



/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
I2C_HandleTypeDef hi2c1;

TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim2;
TIM_HandleTypeDef htim3;
TIM_HandleTypeDef htim4;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

uint8_t rx_data;          // Luu 1 byte nh?n du?c
char rx_buffer[20];       // B? d?m luu chu?i s? (v� d? "10")
int rx_index = 0;
int set_speed = 0;


float Ax,Ay,Az,Gx,Gy,Gz;
float pitch  ;
float roll ;
float yaw ;





/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM2_Init(void);
static void MX_TIM3_Init(void);
static void MX_TIM4_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM1_Init(void);
static void MX_I2C1_Init(void);
/* USER CODE BEGIN PFP */


/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
Motor Left_motor;
Motor *pLeft = &Left_motor;
Motor Right_motor;
Motor *pRight = &Right_motor;
PID_TypeDef RPID;
PID_TypeDef LPID;

//FuzzyTuner LeftTuner;
//FuzzyTuner RightTuner;


const int8_t Kp_Table[49] = {
// de: NL(-3), NM(-2), NS(-1), ZE(0), PS(1), PM(2), PL(3)  | e:
    -3, -3, -2, -2, -1,  0,  0,  // NL (Dòng 0)
    -3, -2, -2, -1, -1,  0,  1,  // NM
    -2, -2, -1, -1,  0,  1,  1,  // NS
    -2, -1, -1,  0,  1,  1,  2,  // ZE (Dòng 3)
    -1, -1,  0,  1,  1,  2,  2,  // PS
    -1,  0,  1,  1,  2,  2,  3,  // PM
     0,  0,  1,  2,  2,  3,  3   // PL (Dòng 6)
};



const int8_t Ki_Table[49] = {
// de: NL,  NM,  NS,  ZE,  PS,  PM,  PL   |  e:
    -3,  -3,  -2,  -2,  -1,   0,   0,  // NL
    -3,  -2,  -2,  -1,  -1,   0,   0,  // NM
    -2,  -2,  -1,   0,   0,   1,   1,  // NS
    -2,  -1,   0,   0,   0,   1,   2,  // ZE (Vùng nhạy cảm nhất)
    -1,  -1,   0,   0,   1,   2,   2,  // PS
     0,   0,   1,   1,   2,   2,   3,  // PM
     0,   0,   1,   2,   2,   3,   3   // PL
};




const int8_t Kd_Table[49] = {
// de: NL,  NM,  NS,  ZE,  PS,  PM,  PL   |  e:
     3,   2,   1,   0,   0,  -1,  -2,  // NL
     3,   2,   1,   1,   0,  -1,  -2,  // NM
     2,   2,   1,   1,   0,  -1,  -1,  // NS
     2,   1,   1,   0,   1,   1,   2,  // ZE
    -1,  -1,   0,   1,   1,   2,   2,  // PS
    -2,  -1,   0,   1,   1,   2,   3,  // PM
    -2,  -1,   0,   0,   1,   2,   3   // PL
};




void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
    if (huart->Instance == USART2) {
        if (rx_data == '\n' || rx_data == '\r') {
            rx_buffer[rx_index] = '\0';
            
            // Tìm vị trí của dấu phẩy để tách 2 giá trị
            char *comma_ptr = strchr(rx_buffer, ',');
            if (comma_ptr != NULL) {
                *comma_ptr = '\0'; // Tạm thời chia chuỗi làm 2 phần
                
                // Giả sử App gửi định dạng "100,200"
                float speed_L = atof(rx_buffer);        // Lấy phần trước dấu phẩy
                float speed_R = atof(comma_ptr + 1);    // Lấy phần sau dấu phẩy
                
                Motor_SetTarget(&Left_motor, speed_L);
                Motor_SetTarget(&Right_motor, speed_R);
            } else {
                // Nếu không có dấu phẩy, áp dụng 1 tốc độ cho cả 2 (như cũ)
                int set_speed = atoi(rx_buffer);
                Motor_SetTarget(&Left_motor, (float)set_speed);
                Motor_SetTarget(&Right_motor, (float)set_speed);
            }

            rx_index = 0;
            HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13); 
        } else {
            if (rx_index < 19) {
                rx_buffer[rx_index++] = rx_data;
            }
        }
        HAL_UART_Receive_IT(&huart2, &rx_data, 1);
    }
}



/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_TIM2_Init();
  MX_TIM3_Init();
  MX_TIM4_Init();
  MX_USART2_UART_Init();
  MX_TIM1_Init();
  MX_I2C1_Init();
  /* USER CODE BEGIN 2 */
	HAL_UART_Receive_IT(&huart2, &rx_data, 1);
	HAL_TIM_Base_Start_IT(&htim1);
	HAL_TIM_Encoder_Start_IT(&htim2, TIM_CHANNEL_ALL); //LEFT
	HAL_TIM_Encoder_Start_IT(&htim4, TIM_CHANNEL_ALL); //RIGHT
	
	// --- PWM start ---
  HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
  HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
	HAL_NVIC_SetPriority(TIM1_UP_TIM10_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(TIM1_UP_TIM10_IRQn);
	// Khoi tao Fuzzy-PID
	 //Fuzzy_Init(&LeftTuner, 300.0f, 60.0f, 0.5f, 3.0f, 0.01f, Kp_Table, Ki_Table, Kd_Table);
   //Fuzzy_Init(&RightTuner, 300.0f, 60.0f, 0.5f, 3.0f, 0.01f, Kp_Table, Ki_Table, Kd_Table);
	// Khoi tao 2 banh xe0
 //  Motor_Init(&Left_motor, LEFT,GPIOB, GPIO_PIN_12, GPIOB, GPIO_PIN_13,&htim3, TIM_CHANNEL_1, &htim2, 23.4, 1170, 0.117);
	 Motor_Init(&Left_motor, LEFT,GPIOB, GPIO_PIN_12, GPIOB, GPIO_PIN_13,&htim3, TIM_CHANNEL_1, &htim2, 9.6, 960, 0.024);
   Motor_Init(&Right_motor,RIGHT,GPIOB, GPIO_PIN_14, GPIOB, GPIO_PIN_15,&htim3, TIM_CHANNEL_2, &htim4	, 17.7 , 1770, 0.04425);
  // Khoi tao PID
	 PID(&LPID, &(pLeft->cur_speed),&(pLeft->Pid_output),&(pLeft->target_speed),pLeft->kp, pLeft->ki, pLeft->kd,_PID_P_ON_E, _PID_CD_DIRECT);
   PID_SetMode(&LPID, _PID_MODE_AUTOMATIC);
   PID_SetSampleTime(&LPID, 10);
   PID_SetOutputLimits(&LPID, -499, 499);
	 
	 PID(&RPID,&(pRight->cur_speed),&(pRight->Pid_output), &(pRight->target_speed),pRight->kp, pRight->ki, pRight->kd,_PID_P_ON_E, _PID_CD_DIRECT);
   PID_SetMode(&RPID, _PID_MODE_AUTOMATIC);
   PID_SetSampleTime(&RPID, 10);
   PID_SetOutputLimits(&RPID, -499, 499);
	 
	 // Khoi tao MPU
	   MPU6050_init();
	 
	 Motor_SetTarget(&Left_motor, 100);
	 Motor_SetTarget(&Right_motor, 100);
	 
	 
   
	 
	 
	 
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
		
		MPU6050_Read_Accel(&Ax,&Ay,&Az);
		MPU6050_Read_Gyro(&Gx,&Gy,&Gz);
		filter(&Ax,&Ay,&Az,&Gx,&Gy,&Gz,&pitch,&roll,&yaw);
		char tx_buf[64];
		double left_speed = (double)Left_motor.cur_speed;
    double right_speed = (double)Right_motor.cur_speed;
   
   
    
int len = sprintf(tx_buf, "SPD:%.2f,%.2f\n", left_speed, right_speed);
    
    HAL_UART_Transmit(&huart2, (uint8_t*)tx_buf, len, 100);

    HAL_Delay(10); 
		
		
		
		
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 100;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_3) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief I2C1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C1_Init(void)
{

  /* USER CODE BEGIN I2C1_Init 0 */

  /* USER CODE END I2C1_Init 0 */

  /* USER CODE BEGIN I2C1_Init 1 */

  /* USER CODE END I2C1_Init 1 */
  hi2c1.Instance = I2C1;
  hi2c1.Init.ClockSpeed = 100000;
  hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c1.Init.OwnAddress1 = 0;
  hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c1.Init.OwnAddress2 = 0;
  hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
  if (HAL_I2C_Init(&hi2c1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C1_Init 2 */

  /* USER CODE END I2C1_Init 2 */

}

/**
  * @brief TIM1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM1_Init(void)
{

  /* USER CODE BEGIN TIM1_Init 0 */

  /* USER CODE END TIM1_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM1_Init 1 */

  /* USER CODE END TIM1_Init 1 */
  htim1.Instance = TIM1;
  htim1.Init.Prescaler = 99;
  htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim1.Init.Period = 9999;
  htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim1.Init.RepetitionCounter = 0;
  htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim1) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim1, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM1_Init 2 */

  /* USER CODE END TIM1_Init 2 */

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_Encoder_InitTypeDef sConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 0;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 4294967295;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  sConfig.EncoderMode = TIM_ENCODERMODE_TI12;
  sConfig.IC1Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC1Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC1Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC1Filter = 0;
  sConfig.IC2Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC2Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC2Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC2Filter = 0;
  if (HAL_TIM_Encoder_Init(&htim2, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */

}

/**
  * @brief TIM3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM3_Init(void)
{

  /* USER CODE BEGIN TIM3_Init 0 */

  /* USER CODE END TIM3_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};

  /* USER CODE BEGIN TIM3_Init 1 */

  /* USER CODE END TIM3_Init 1 */
  htim3.Instance = TIM3;
  htim3.Init.Prescaler = 9;
  htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim3.Init.Period = 499;
  htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim3) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim3, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_TIM_PWM_Init(&htim3) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM3_Init 2 */

  /* USER CODE END TIM3_Init 2 */
  HAL_TIM_MspPostInit(&htim3);

}

/**
  * @brief TIM4 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM4_Init(void)
{

  /* USER CODE BEGIN TIM4_Init 0 */

  /* USER CODE END TIM4_Init 0 */

  TIM_Encoder_InitTypeDef sConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM4_Init 1 */

  /* USER CODE END TIM4_Init 1 */
  htim4.Instance = TIM4;
  htim4.Init.Prescaler = 0;
  htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim4.Init.Period = 65535;
  htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  sConfig.EncoderMode = TIM_ENCODERMODE_TI12;
  sConfig.IC1Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC1Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC1Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC1Filter = 0;
  sConfig.IC2Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC2Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC2Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC2Filter = 0;
  if (HAL_TIM_Encoder_Init(&htim4, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM4_Init 2 */

  /* USER CODE END TIM4_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_RESET);

  /*Configure GPIO pins : PB12 PB13 PB14 PB15 */
  GPIO_InitStruct.Pin = GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */
 void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
   if(htim->Instance == TIM1) {
      /*
   		 Motor_GetSpeed(&Left_motor);
		   Motor_GetSpeed(&Right_motor);
		   // ----Banh trai--------------
		
		    float dt = 0.01f;
		    float errL = Left_motor.target_speed - Left_motor.cur_speed;
        float dErrL = (errL - global_lastErrL) / dt;
        global_lastErrL = errL;
		   
		    Fuzzy_Compute(&LeftTuner, errL, dErrL);
		    current_Kp_L = 21.6f + LeftTuner.deltaKp;
        current_Ki_L = 786.0f + LeftTuner.deltaKi;
        current_Kd_L = 0.1485f + LeftTuner.deltaKd;
        PID_SetTunings(&LPID, current_Kp_L, current_Ki_L, current_Kd_L);
		    
		   
		   //------Banh phai-------------
	   	  float errR = Right_motor.target_speed - Right_motor.cur_speed;
        float dErrR = (errR - global_lastErrR) / dt;
        global_lastErrR = errR;
		     
		    Fuzzy_Compute(&RightTuner, errR, dErrR);
				current_Kp_R = 21.6f + RightTuner.deltaKp;
        current_Ki_R = 786.0f + RightTuner.deltaKi;
        current_Kd_R = 0.1485f + RightTuner.deltaKd;
				PID_SetTunings(&RPID, current_Kp_R, current_Ki_R, current_Kd_R);
				
		   
		    
		   PID_Compute(&LPID);
		   PID_Compute(&RPID);
		   Motor_SetPwm(&Left_motor);
		   Motor_SetPwm(&Right_motor);
			 */
			 Motor_GetSpeed(&Left_motor);
       Motor_GetSpeed(&Right_motor);
		   PID_Compute(&LPID);
       PID_Compute(&RPID);
		   Motor_SetPwm(&Left_motor);
       Motor_SetPwm(&Right_motor);
		   
    }
}



		 

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
