################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mylib/BME280.c \
../mylib/Motor.c \
../mylib/mpu6050.c \
../mylib/pid.c \
../mylib/publish.c 

OBJS += \
./mylib/BME280.o \
./mylib/Motor.o \
./mylib/mpu6050.o \
./mylib/pid.o \
./mylib/publish.o 

C_DEPS += \
./mylib/BME280.d \
./mylib/Motor.d \
./mylib/mpu6050.d \
./mylib/pid.d \
./mylib/publish.d 


# Each subdirectory must supply rules for building sources it contributes
mylib/%.o mylib/%.su mylib/%.cyclo: ../mylib/%.c mylib/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F411xE -c -I../Core/Inc -I../micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"/home/long/STM32CubeIDE/my_micro_ros/micro_ros2/mylib" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-mylib

clean-mylib:
	-$(RM) ./mylib/BME280.cyclo ./mylib/BME280.d ./mylib/BME280.o ./mylib/BME280.su ./mylib/Motor.cyclo ./mylib/Motor.d ./mylib/Motor.o ./mylib/Motor.su ./mylib/mpu6050.cyclo ./mylib/mpu6050.d ./mylib/mpu6050.o ./mylib/mpu6050.su ./mylib/pid.cyclo ./mylib/pid.d ./mylib/pid.o ./mylib/pid.su ./mylib/publish.cyclo ./mylib/publish.d ./mylib/publish.o ./mylib/publish.su

.PHONY: clean-mylib

