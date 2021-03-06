/**
 * @file ArduinoBLE.ino
 * @author fangaoyige@live.com
 * @brief Use BLE to communicate with Arduino, send data from Arduino ADC to BLE
 * @version 0.1
 * @date 2022-01-01
 * 
 * @copyright Copyright (c) 2022
 * 
 */

// import the BLE library
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

#include <Arduino.h>

// Create the BLE Device
BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create the BLE Server
BLEService *pService = NULL;
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create a BLE Descriptor
const uint8_t value[] = {0x11, 0x22, 0x33};
BLE2902 *p2902 = NULL;

// Create the BLE Characteristic
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create a BLE Descriptor
const uint8_t value[] = {0x11, 0x22, 0x33};
BLE2902 *p2902 = NULL;

// Create the BLE Characteristic
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create a BLE Descriptor
const uint8_t value[] = {0x11, 0x22, 0x33};
BLE2902 *p2902 = NULL;

// Create the BLE Characteristic
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create a BLE Descriptor
const uint8_t value[] = {0x11, 0x22, 0x33};
BLE2902 *p2902 = NULL;

// Create the BLE Characteristic
BLECharacteristic *pCharacteristic = NULL;
BLECharacteristic *pCharacteristic2 = NULL;
BLECharacteristic *pCharacteristic3 = NULL;

// Create a BLE Descriptor
const uint8

