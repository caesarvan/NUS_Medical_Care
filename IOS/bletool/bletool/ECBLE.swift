//
//  ECBLE.swift
//
//  Created by 莫凡 on 2021/3/1.
//  Copyright © 2021 莫凡. All rights reserved.
//

import CoreBluetooth
import Foundation

extension String {
    func hexadecimal() -> Data? {
        var data = Data(capacity: self.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
//        print(data.count)
        guard data.count > 0 else { return nil }
        return data
    }
}

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
//    var characteristicChangeCallback: (String, String) -> Void = { _, _ in }
    var characteristicChangeCallback: (String, String, [UInt16]) -> Void = { _, _, _ in }

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
    //获取蓝牙适配器状态
    func getBluetoothAdapterState() -> Bool {
        return bleAdapterState
    }
    //开始搜索蓝牙
    func startBluetoothDevicesDiscovery(cb: @escaping (String, Int) -> Void) {
        ecPeripheralList.removeAll()
        scanCallback = cb
        ecCBCentralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    //停止搜索蓝牙
    func stopBluetoothDevicesDiscovery() {
        ecCBCentralManager.stopScan()
    }
    //中心管理器
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
    //创建BLE连接
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
    //关闭BLE连接
    func closeBLEConnection() {
        ecCBCentralManager.cancelPeripheralConnection(ecPeripheral)
    }
    //连接上
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        ecPeripheral = peripheral
        ecPeripheral.delegate = self
        connectCallback(true, "")
    }
    //未连接上
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectCallback(false, error.debugDescription)
    }
    //BLE连接状态改变
    func onBLEConnectionStateChange(cb: @escaping (String) -> Void) {
        disconnectCallback = cb
    }
    //与边缘设备断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        disconnectCallback(error.debugDescription)
    }
    //获取BLE设备服务
    func getBLEDeviceServices(cb: @escaping ([String]) -> Void) {
        discoverServicesCallback = cb
        ecPeripheral.discoverServices(nil)
    }
    //外围
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        ecPeripheralServices = peripheral.services ?? []
        var servicesUUID: [String] = []
        for item in ecPeripheralServices {
            // NSLog(item.uuid.uuidString)
            servicesUUID.append(item.uuid.uuidString)
        }
        discoverServicesCallback(servicesUUID)
    }
    //获取BLE设备表征
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
    //外围
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        ecPeripheralCharacteristics = service.characteristics ?? []
        var characteristicsUUID: [String] = []
        for item in ecPeripheralCharacteristics {
//            NSLog(item.uuid.uuidString)
            characteristicsUUID.append(item.uuid.uuidString)
        }
        discoverCharacteristicsCallback(characteristicsUUID)
    }
    //提醒BLE表征值发生改变
    func notifyBLECharacteristicValueChange(uuid: String) {
        for item in ecPeripheralCharacteristics {
            if item.uuid.uuidString == uuid {
                ecPeripheral.setNotifyValue(true, for: item)
                return
            }
        }
    }
    //简单连接
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
    
    func onBLECharacteristicValueChange(cb: @escaping (String, String, [UInt16]) -> Void) {
        characteristicChangeCallback = cb
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.value == nil { return }
//        let str = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? ""
        let hexStr = dataToHexString(data: characteristic.value!)
        let uint16Array = hexStrToUint16Array(hexStr: hexStr)
        let str = arrayToString(array: uint16Array)
        characteristicChangeCallback(str, hexStr, uint16Array)
    }
    //写入BLE表征值
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
    //简易发送数据
    func easySendData(data: String, isHex: Bool) {
        var tempData: Data?
        if isHex {
            tempData = hexStrToData(hexStr: data)
        } else {
            tempData = data.data(using: .ascii)
        }
        if tempData == nil { return }
        writeBLECharacteristicValue(uuid: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E", data: tempData!)
    }
    //数据转16进制字符串
    func dataToHexString(data: Data) -> String {
        var hexStr = ""
        for byte in [UInt8](data) {
            hexStr += String(format: "%02X", byte)
        }
        return hexStr
    }
    //字符串转字节码
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
    //16进制字符串转数据
    func hexStrToData(hexStr: String) -> Data {
        let bytes = strTobytes(hexStr: hexStr)
        return Data(bytes: bytes, count: bytes.count)
    }
    
    func hexStrToUint16Array(hexStr: String) -> [UInt16]{
        var uint16Array = [UInt16]()
        
        let datas =  hexStr.hexadecimal()
        let bytes = [UInt8](datas!)

        for i in (0..<8){
            uint16Array.append((UInt16(bytes[2*i])<<8) + UInt16(bytes[2*i+1]))
        }
        return uint16Array
    }
    
    func arrayToString(array: [UInt16]) -> String{
        var str = String()
        for num in array{
            str += String(num)+","
        }
        return str
    }
    
}
