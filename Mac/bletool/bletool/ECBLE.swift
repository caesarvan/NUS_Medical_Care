//
//  ECBLE.swift
//
//  Created by 莫凡 on 2021/3/1.
//  Copyright © 2021 莫凡. All rights reserved.
//

import CoreBluetooth
import Foundation

var ecBLE = ECBLE()

class ECBLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var ecCBCentralManager: CBCentralManager!
    var bleAdapterState: Bool = false
    var initCallback: (Bool, String) -> Void = { _, _ in }
    var ecPeripheralList: [CBPeripheral] = []
    var scanCallback: (String, Int) -> Void = { _, _ in }
    var connectCallback: (Bool, String) -> Void = { _, _ in }
    var disconnectCallback: (String) -> Void = { _ in }
    var ecPeripheral: CBPeripheral!
    var ecPeripheralServices: [CBService] = []
    var discoverServicesCallback: ([String]) -> Void = { _ in }
    var ecPeripheralCharacteristics: [CBCharacteristic] = []
    var discoverCharacteristicsCallback: ([String]) -> Void = { _ in }
    var characteristicChangeCallback: (String, String) -> Void = { _, _ in }
    func Init(cb: @escaping (Bool, String) -> Void) {
        initCallback = cb
        ecCBCentralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bleAdapterState = true
            initCallback(true, "")
        case .unknown:
            bleAdapterState = false
            initCallback(false, "unknown")
        case .resetting:
            bleAdapterState = false
            initCallback(false, "resetting")
        case .unsupported:
            bleAdapterState = false
            initCallback(false, "unsupported")
        case .unauthorized:
            bleAdapterState = false
            initCallback(false, "unauthorized")
        case .poweredOff:
            bleAdapterState = false
            initCallback(false, "poweredOff")
        @unknown default:
            bleAdapterState = false
            initCallback(false, "unknown default")
        }
    }

    func getBluetoothAdapterState() -> Bool {
        return bleAdapterState
    }

    func startBluetoothDevicesDiscovery(cb: @escaping (String, Int) -> Void) {
        ecPeripheralList.removeAll()
        scanCallback = cb
        ecCBCentralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopBluetoothDevicesDiscovery() {
        ecCBCentralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == nil { return }
        var isExist = false
        for item in ecPeripheralList {
            if item.name == peripheral.name {
                isExist = true
            }
        }
        if !isExist {
            ecPeripheralList.append(peripheral)
        }
        scanCallback(peripheral.name ?? "", RSSI.intValue)
//        NSLog(ecPeripheralList.description)
//        NSLog(ecPeripheralList.count.description)
    }

    func createBLEConnection(name: String, cb: @escaping (Bool, String) -> Void) {
        stopBluetoothDevicesDiscovery()
        connectCallback = cb
        for item in ecPeripheralList {
            if item.name == name {
                ecCBCentralManager.connect(item, options: nil)
                return
            }
        }
        connectCallback(false, "This device does not exist")
    }

    func closeBLEConnection() {
        ecCBCentralManager.cancelPeripheralConnection(ecPeripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        ecPeripheral = peripheral
        ecPeripheral.delegate = self
        connectCallback(true, "")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectCallback(false, error.debugDescription)
    }

    func onBLEConnectionStateChange(cb: @escaping (String) -> Void) {
        disconnectCallback = cb
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        disconnectCallback(error.debugDescription)
    }

    func getBLEDeviceServices(cb: @escaping ([String]) -> Void) {
        discoverServicesCallback = cb
        ecPeripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        ecPeripheralServices = peripheral.services ?? []
        var servicesUUID: [String] = []
        for item in ecPeripheralServices {
            // NSLog(item.uuid.uuidString)
            servicesUUID.append(item.uuid.uuidString)
        }
        discoverServicesCallback(servicesUUID)
    }

    func getBLEDeviceCharacteristics(serviceUUID: String, cb: @escaping ([String]) -> Void) {
        discoverCharacteristicsCallback = cb
        for item in ecPeripheralServices {
            if item.uuid.uuidString == serviceUUID {
                ecPeripheral.discoverCharacteristics(nil, for: item)
                return
            }
        }
        discoverCharacteristicsCallback([])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        ecPeripheralCharacteristics = service.characteristics ?? []
        var characteristicsUUID: [String] = []
        for item in ecPeripheralCharacteristics {
//            NSLog(item.uuid.uuidString)
            characteristicsUUID.append(item.uuid.uuidString)
        }
        discoverCharacteristicsCallback(characteristicsUUID)
    }

    func notifyBLECharacteristicValueChange(uuid: String) {
        for item in ecPeripheralCharacteristics {
            if item.uuid.uuidString == uuid {
                ecPeripheral.setNotifyValue(true, for: item)
                return
            }
        }
    }

    func easyConnect(name: String, cb: @escaping (Bool, String) -> Void) {
        createBLEConnection(name: name) {
            ok, errMsg in
            if !ok {
                cb(false, errMsg.description)
                return
            }
            self.getBLEDeviceServices {
                _ in
                ecBLE.getBLEDeviceCharacteristics(serviceUUID: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
                    _ in
                    ecBLE.notifyBLECharacteristicValueChange(uuid: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
                    cb(true, "")
                }
            }
        }
    }

    func onBLECharacteristicValueChange(cb: @escaping (String, String) -> Void) {
        characteristicChangeCallback = cb
        print(cb)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.value == nil { return }
        let str = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? ""
        let hexStr = dataToHexString(data: characteristic.value!)
        characteristicChangeCallback(str, hexStr)
    }

    func writeBLECharacteristicValue(uuid: String, data: Data) {
        var writeCharacteristic: CBCharacteristic?
        for item in ecPeripheralCharacteristics {
            if item.uuid.uuidString == uuid {
                writeCharacteristic = item
                break
            }
        }
        if writeCharacteristic == nil { return }
        ecPeripheral.writeValue(data, for: writeCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }

    func easySendData(data: String, isHex: Bool) {
        var tempData: Data?
        if isHex {
            tempData = hexStrToData(hexStr: data)
        } else {
            tempData = data.data(using: .ascii)
        }
        if tempData == nil { return }
        writeBLECharacteristicValue(uuid: "FFF2", data: tempData!)
    }

    func dataToHexString(data: Data) -> String {
        var hexStr = ""
        for byte in [UInt8](data) {
            hexStr += String(format: "%02X", byte)
        }
        return hexStr
    }

    func strTobytes(hexStr: String) -> [UInt8] {
        var bytes = [UInt8]()
        var sum = 0
        // 整形的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        for (index, c) in hexStr.utf8CString.enumerated() {
            var intC = Int(c.byteSwapped)
            if intC == 0 {
                break
            } else if intRange.contains(intC) {
                intC -= 48
            } else if lowercaseRange.contains(intC) {
                intC -= 87
            } else if uppercasedRange.contains(intC) {
                intC -= 55
            }
            sum = sum * 16 + intC
            // 每两个十六进制字母代表8位，即一个字节
            if index % 2 != 0 {
                bytes.append(UInt8(sum))
                sum = 0
            }
        }
        return bytes
    }

    func hexStrToData(hexStr: String) -> Data {
        let bytes = strTobytes(hexStr: hexStr)
        return Data(bytes: bytes, count: bytes.count)
    }
}
