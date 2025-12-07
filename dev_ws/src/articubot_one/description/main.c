/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
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
#include "main.h"
#include "adc.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
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

/* USER CODE BEGIN PV */
static GPIO_TypeDef* wire_Port;
static uint16_t wire_Pin;
GPIO_InitTypeDef GPIO_InitStruct;
uint8_t Hum_byte1, Hum_byte2, Temp_byte1, Temp_byte2, err;
uint16_t Sum;
uint16_t Temp, uint16_t Hum;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
extern TIM_HandleTypeDef h;


static void TIM_Config(void)
{
	RCC_ClkInitTypeDef myCLKtypeDef;
	uint32_t clockSpeed;
	uint32_t flashLatencyVar;
	HAL_RCC_GetClockConfig(&myCLKtypeDef, &flashLatencyVar);
	if(myCLKtypeDef.APB1CLKDivider == RCC_HCLK_DIV1)
	{
		clockSpeed = HAL_RCC_GetPCLK1Freq();
	}
	else
	{
		clockSpeed = HAL_RCC_GetPCLK1Freq()*2;
	}
	clockSpeed *= 0.000001;
	RCC->APB1ENR |= RCC_APB1ENR_TIM3EN;  // 0x1
	TIM3->CR1 &= ~(0x0010);
	TIM3->CR1 &= ~(0x0001);
	TIM3->CR1 &= ~(1UL << 2);
	TIM3->CR1 |= (1UL << 3);
	TIM3->PSC = clockSpeed-1;
	TIM3->ARR = 10-1;
	TIM3->EGR = 1;
	TIM3->SR &= ~(0x0001);
}
//microsecond delay
static void delay_my(uint32_t uSecDelay)
{
	TIM3->ARR = uSecDelay-1;
	TIM3->SR &= ~(0x0001);
	TIM3->CR1 |= 1UL;
	while((TIM3->SR&0x0001) != 1);
}

void DHT22_Init(GPIO_TypeDef* Port,uint16_t Pin){
	wire_Port = Port;
	wire_Pin = Pin;
	TIM_Config();;
}

void gpio_output(){
	GPIO_InitStruct.Pin = wire_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(wire_Port, &GPIO_InitStruct);
}

void gpio_input(){
	GPIO_InitStruct.Pin = wire_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(wire_Port, &GPIO_InitStruct);
}

void ONE_WIRE_START(){
	gpio_output();
	HAL_GPIO_WritePin(wire_Port, wire_Pin, GPIO_PIN_RESET);
	delay_my(500);
	HAL_GPIO_WritePin(wire_Port, wire_Pin, GPIO_PIN_SET);
	delay_my(30);
	gpio_input();
}
void ONE_WIRE_Responsee(){
	delay_my(40);
	if(!(HAL_GPIO_ReadPin(wire_Port, wire_Pin))) //check if it's low state
	{
		delay_my(80);
		if(HAL_GPIO_ReadPin(wire_Port, wire_Pin)){ //if after 80us is high state response is correct
			err=1;
		}
		while(HAL_GPIO_ReadPin(wire_Port, wire_Pin)); //wait until high state
	}
}
uint8_t ONE_WIRE_Read_Data(){
	uint8_t i,j;
	for(j=0;j<8;j++)
	{
		while(!(HAL_GPIO_ReadPin(wire_Port, wire_Pin))); //wait until pin is low
		delay_my(50);
		if(HAL_GPIO_ReadPin(wire_Port, wire_Pin)==0){ //if after 26-28us is still 0 means bit is 0
			i&= ~(1<<(7-j));
		}
		else{ //otherwise is 1
			i|=(1<<(7-j));
		}
		while(HAL_GPIO_ReadPin(wire_Port, wire_Pin)); //
	}
	return i;
}

uint8_t DHT22_Get_Data(uint16_t *Temp,uint16_t *Hum){
	ONE_WIRE_START();
	ONE_WIRE_Responsee();
	Hum_byte1 = ONE_WIRE_Read_Data();
	Hum_byte2 = ONE_WIRE_Read_Data();
	Temp_byte1 = ONE_WIRE_Read_Data();
	Temp_byte2 = ONE_WIRE_Read_Data();
	Sum = ONE_WIRE_Read_Data();
	*Temp = (Temp_byte1<<8)|Temp_byte2;
	*Hum = (Hum_byte1<<8)|Hum_byte2;
	return err;
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
   DHT22_Init(GPIOA, GPIO_PIN_0);
  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX__Init();
  MX_ADC1_Init();
  MX_USART1_UART_Init();
  /* USER CODE BEGIN 2 */
    HAL_TIM_Base_Start(&h);
    HAL_ADC_Start(&hadc1);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    DHT22_Get_Data(&Temp, &Hum);
    HAL_Delay(100); 

    // MQ135
    HAL_ADC_Start(&hadc1);
    if(HAL_ADC_PollForConversion(&hadc1, 100) == HAL_OK)
    {
        ADC_Val = HAL_ADC_GetValue(&hadc1);
        MQ135_Voltage = (float)ADC_Val * 3.3 / 4095.0;
    }
    HAL_ADC_Stop(&hadc1);
    HAL_Delay(1000); 
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
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
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

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_ADC;
  PeriphClkInit.AdcClockSelection = RCC_ADCPCLK2_DIV2;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

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
				