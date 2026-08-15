# 超声波测距模块 (Ultrasonic Distance Measurement)

基于 FPGA 的超声波测距系统，使用 VHDL 实现，支持数码管动态显示测量距离。

## 项目概述

本项目使用 **Altera Cyclone IV E** 系列 FPGA（型号 `EP4CE6F17C8`），配合超声波传感器（如 HC-SR04）实现距离测量，并通过 3 位共阴数码管实时显示测量结果。

## 功能特性

- **超声波测距**：发射 45μs 触发脉冲，每 0.01s 测量一次
- **距离计算**：基于声速 340m/s，通过回波时间计算距离（单位：cm）
- **数码管显示**：3 位数码管动态扫描显示距离值（最大显示 999cm）
- **复位功能**：支持外部复位信号

## 文件结构

| 文件 | 说明 |
|------|------|
| `measure_distance.vhd` | 核心 VHDL 源码文件 |
| `measure_distance.qpf` | Quartus Prime 工程文件 |
| `measure_distance.qsf` | 引脚分配及工程配置文件 |
| `measure_distance.cdf` | 下载链配置文件 |

## 接口定义

| 信号名 | 方向 | 类型 | 说明 |
|--------|------|------|------|
| `clk` | Input | std_logic | 系统时钟（50MHz） |
| `reset` | Input | std_logic | 复位信号（低电平有效） |
| `echo` | Input | std_logic | 超声波回波信号 |
| `trig` | Output | std_logic | 超声波触发信号 |
| `dig[2:0]` | Output | std_logic_vector | 数码管位选信号（低电平有效） |
| `f[6:0]` | Output | std_logic_vector | 数码管段选信号（共阴极，高电平点亮） |

## 引脚分配

| 信号 | FPGA 引脚 | 连接设备 |
|------|-----------|----------|
| `clk` | PIN_E1 | 50MHz 晶振 |
| `reset` | PIN_R16 | 复位按键 |
| `echo` | PIN_C16 | 超声波模块 Echo |
| `trig` | PIN_C15 | 超声波模块 Trig |
| `f[0]` | PIN_D9 | 数码管段 a |
| `f[1]` | PIN_E10 | 数码管段 b |
| `f[2]` | PIN_E8 | 数码管段 c |
| `f[3]` | PIN_D11 | 数码管段 d |
| `f[4]` | PIN_C8 | 数码管段 e |
| `f[5]` | PIN_D8 | 数码管段 f |
| `f[6]` | PIN_E9 | 数码管段 g |
| `dig[0]` | PIN_F11 | 个位数码管 |
| `dig[1]` | PIN_C11 | 十位数码管 |
| `dig[2]` | PIN_D12 | 百位数码管 |

## 工作原理

1. **触发信号生成**：每 0.01 秒产生一个 45μs 的高电平触发脉冲，驱动超声波模块发射声波
2. **回波检测与距离计算**：检测回波信号的高电平持续时间，根据公式 `距离 = 回波时间 × 声速 / 2` 计算距离
3. **数码管动态刷新**：将 50MHz 主时钟分频为 50Hz 扫描时钟，循环点亮 3 位数码管显示距离值

## 开发环境

- **开发工具**：Quartus Prime 18.1.0 Lite Edition
- **目标器件**：Cyclone IV E EP4CE6F17C8
- **编程语言**：VHDL

## 使用说明

1. 使用 Quartus Prime 打开 `measure_distance.qpf` 工程文件
2. 编译工程并下载到 FPGA 开发板
3. 连接超声波模块和数码管
4. 上电后即可实时显示测量距离

## 注意事项

- 系统时钟频率固定为 **50MHz**，如需修改请同步调整 `clk_freq` 常量
- 数码管为**共阴极**接法，段选信号高电平点亮
- 测量范围取决于超声波模块性能，一般有效范围为 2cm ~ 400cm