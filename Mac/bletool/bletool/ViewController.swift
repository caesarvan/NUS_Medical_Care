//
//  ViewController.swift
//  bletool
//
//  Created by 莫凡 on 2021/3/3.
//

import Cocoa
import FirebaseDatabase

class DeviceInfo: NSObject {
    var name: String = ""
    var rssi: Int = 0
    init(name: String, rssi: Int) {
        self.name = name
        self.rssi = rssi
        super.init()
    }
}

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - 变量
    private let database = Database.database().reference()
    
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var btStartSearch: NSButton!
    @IBOutlet var btStopSearch: NSButton!
    @IBOutlet var btConnect: NSButton!
    @IBOutlet var btDisconnect: NSButton!
    @IBOutlet var checkScroll: NSButton!
    @IBOutlet var checkRevHex: NSButton!
    @IBOutlet var checkSendHex: NSButton!
    @IBOutlet var scrollViewRev: NSScrollView!
    @IBOutlet var textViewRev: NSTextView!
    @IBOutlet var textFieldSend: NSTextField!
    @IBOutlet var btSend: NSButton!

    var deviceListData: [DeviceInfo] = []

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        sendAndRevDisable()

        ecBLE.Init {
            ok, errMsg in
            if ok {
                self.startScan()
            } else {
                self.showAlert(title: "提示", content: "蓝牙适配器错误，errMsg="+errMsg)
            }
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // MARK: - UI

    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        deviceListData.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn == tableView.tableColumns[0] {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NameCellID"), owner: nil) as? NSTableCellView
            {
                cell.textField?.stringValue = deviceListData[row].name
                return cell
            }
        }
        if tableColumn == tableView.tableColumns[1] {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RSSICellID"), owner: nil) as? NSTableCellView
            {
                cell.textField?.stringValue = deviceListData[row].rssi.description
                return cell
            }
        }
        return nil
    }

    func sendAndRevEnable() {
        checkScroll.isEnabled = true
        checkRevHex.isEnabled = true
        checkSendHex.isEnabled = true
//        textFieldRev.isEnabled = true
//        textFieldSend.isEnabled = true
        btSend.isEnabled = true
    }

    func sendAndRevDisable() {
        checkScroll.isEnabled = false
        checkRevHex.isEnabled = false
        checkSendHex.isEnabled = false
//        textFieldRev.isEnabled = false
//        textFieldSend.isEnabled = false
        btSend.isEnabled = false
    }

    func showAlert(title: String, content: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = content
            alert.runModal()
        }
    }

    @IBAction func btStartSearch(_ sender: Any) {
        startScan()
        btStopSearch.isEnabled = true
        btStartSearch.isEnabled = false
    }

    @IBAction func btStopSearch(_ sender: Any) {
        stopScan()
        btStopSearch.isEnabled = false
        btStartSearch.isEnabled = true
    }

    @IBAction func btConnect(_ sender: Any) {
        if tableView.selectedRow < 0 {
            showAlert(title: "提示", content: "请先选择设备")
            return
        }
        ecBLE.onBLEConnectionStateChange { _ in
            self.btConnect.isEnabled = true
            self.btDisconnect.isEnabled = false
            self.sendAndRevDisable()
            self.showAlert(title: "提示", content: "设备断开链接")
        }
        btConnect.isEnabled = false
        ecBLE.easyConnect(name: deviceListData[tableView.selectedRow].name) {
            ok, errMsg in
            if ok {
                self.showAlert(title: "提示", content: "连接成功")
                self.btDisconnect.isEnabled = true
                self.sendAndRevEnable()
                ecBLE.onBLECharacteristicValueChange {
                    str, hexStr, uint16Array in
                    self.revData(str: str, hexStr: hexStr, uint16Array: uint16Array )
                }
            } else {
                self.showAlert(title: "提示", content: "连接失败，errMsg = "+errMsg)
                self.btConnect.isEnabled = true
                self.sendAndRevDisable()
            }
        }
    }

    @IBAction func btDisconnect(_ sender: Any) {
        btDisconnect.isEnabled = false
        ecBLE.closeBLEConnection()
    }

    @IBAction func btSend(_ sender: Any) {
        if checkSendHex.state == .on {
            if textFieldSend.stringValue.count % 2 != 0 {
                showAlert(title: "提示", content: "数据长度错误，长度必须是双数")
                return
            }
            if !isHexString(data: textFieldSend.stringValue) {
                showAlert(title: "提示", content: "数据格式错误，0-9,a-f,A-F")
                return
            }
            ecBLE.easySendData(data: textFieldSend.stringValue, isHex: true)
        } else {
            ecBLE.easySendData(data: textFieldSend.stringValue, isHex: false)
        }
    }

    // MARK: - ble

    func startScan() {
        deviceListData.removeAll()
        reloadTableView()
        ecBLE.startBluetoothDevicesDiscovery {
            name, rssi in
            for item in self.deviceListData {
                if item.name == name {
                    item.rssi = rssi
                    self.reloadTableView()
                    return
                }
            }
            self.deviceListData.append(DeviceInfo(name: name, rssi: rssi))
            self.reloadTableView()
        }
    }

    func stopScan() {
        ecBLE.stopBluetoothDevicesDiscovery()
    }
    
    func revData(str:String,hexStr:String,uint16Array:[UInt16]){
        addToDatabase(array: uint16Array)
//        print("str:", str)
//        print("hexStr:", hexStr)
//        print("array:",uint16Array)
        DispatchQueue.main.async {
            if self.checkRevHex.state == .on {
                self.textViewRev.string += (self.getTimeString() + " : " + hexStr + "\r")
            }else{
                self.textViewRev.string += (self.getTimeString() + " : " + str + "\r")
            }
            if self.checkScroll.state == .on {
                let maxHeight = max(self.scrollViewRev.bounds.height, self.scrollViewRev.documentView?.bounds.height ?? 0)
                self.scrollViewRev.documentView?.scroll(NSPoint(x: 0, y: maxHeight))
            }
        }
    }

    // MARK: - tool

    func isHexString(data: String) -> Bool {
        let regular = "^[0-9a-fA-F]*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regular)
        return predicate.evaluate(with: data)
    }
    func getTimeString() -> String{
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "HH:mm:ss:SSS"// 自定义时间格式
        return dateformatter.string(from: Date())
    }
    
    
    func addToDatabase(array: [UInt16]){
        let object: [String: Any] = [
            self.getTimeString(): array
        ]
        print(object)
        database.child("patient1/data/2020-04-01").updateChildValues(object)
    }

}

