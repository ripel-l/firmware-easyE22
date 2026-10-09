#ifndef _VARIANT_E22_S2_OLED_
#define _VARIANT_E22_S2_OLED_

// --- Фікс калібрування АЦП для ESP32-S2 ---
//#include <sdkconfig.h>
//#undef CONFIG_ADC_CALI_EFUSE_TP_ENABLE
//#define CONFIG_ADC_CALI_EFUSE_TP_ENABLE 1
//#undef CONFIG_ADC_CALI_EFUSE_VREF_ENABLE
//#define CONFIG_ADC_CALI_EFUSE_VREF_ENABLE 1

/*
| Pin   | Function    |     | Pin      | Function     |
| ----- | ----------- | --- | -------- | ------------ |
| Gnd   |             |     | vbat     |              |
| P0.06 | BUTTON_PIN  |     | vbat     |              |
| P0.08 | PIN_BUZZER  |     | Gnd      |              |
| Gnd   |             |     | reset    |              |
| Gnd   |             |     | ext_vcc  | *see 0.13    |
| P0.17 | Serial2 TX  |     | P0.31    | BATTERY_PIN  |
| P0.20 | Rotary B    |     | P0.29    | DIO1         |
| P0.22 | Rotary A    |     | P0.02    | BUSY         |
| P0.24 | Rotary press|     | P1.15    | NRST         |
| P1.00 | TXEN        |     | P1.13    | MISO         |
| P0.11 | RXEN        |     | P1.11    | MOSI         |
| P1.04 | SDA         |     | P0.10    | SCK          |
| P1.06 | SCL         |     | P0.09    | CS           |
|       |             |     |          |              |
|       | Mid board   |     |          | Internal     |
| P1.01 | Serial2 RX  |     | 0.15     | LED          |
| P1.02 | TX to GPS   |     | 0.13     | 3V3_EN       |
| P1.07 | RX from GPS |     |          |              |
*/

// --- Вбудований світлодіод Lolin S2 Mini ---
#define LED_PIN 15

// I2C
#define I2C_SDA 11 // I2C pins for this board
#define I2C_SCL 12

// OLED
#define USE_SSD1306

// encoder
//

// --- Замір напруги АКБ (ADC1) ---
#define BATTERY_PIN 1
#define ADC_CHANNEL ADC_CHANNEL_0   // Використовуємо елемент enum замість int
//#define ADC_MULTIPLIER 1.47f
#define ADC_MULTIPLIER 1.47 // (R1 = 470k, R2 = 1M)
#define EXT_PWR_DETECT 9    // Pin to detect connected external power source for LILYGO® TTGO T-Energy T18 and other DIY boards


// E22-400M22S
#define USE_SX1268
//#define USE_SX1262
#define PIN_SPI_MISO 8
#define PIN_SPI_MOSI 10
#define PIN_SPI_SCK 13 

#define LORA_MISO PIN_SPI_MISO
#define LORA_MOSI PIN_SPI_MOSI
#define LORA_SCK PIN_SPI_SCK
#define LORA_CS 14      // NSS
#define LORA_DIO0 4    // BUSY
#define LORA_DIO1 2   // IRQ
#define LORA_RESET 6 // NRST

#define SX126X_CS LORA_CS
#define SX126X_DIO1 LORA_DIO1
#define SX126X_BUSY LORA_DIO0
#define SX126X_RESET LORA_RESET
#define SX126X_RXEN 16
#define SX126X_TXEN 18
//#define SX126X_MAX_POWER 8   // Default to prevent damage to E22_900M33S; Comment out for others
#undef TX_GAIN_LORA
#define TX_GAIN_LORA 0  
                        // 8 for E22 900M30S, 25 for 900M33S, 22 for 3.7V battery powered 900M33S,  0 for 900M22S

#define SX126X_DIO3_TCXO_VOLTAGE 1.8
#define TCXO_OPTIONAL // make it so that the firmware can try both TCXO and XTAL





#endif
