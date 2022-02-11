//
//  DeviceViewController.swift
//  bletool
//
//  Created by 莫凡 on 2021/3/7.
//

import UIKit
import FirebaseDatabase

class DeviceViewController: UIViewController, UITextFieldDelegate {
    
    private let database = Database.database().reference()

    @IBOutlet var textViewRev: UITextView!
    @IBOutlet var textViewSend: UITextView!
    @IBOutlet var switchScroll: UISwitch!
    @IBOutlet var switchRevHex: UISwitch!
    @IBOutlet var switchSendHex: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        textViewRev.textContainer.lineBreakMode = .byCharWrapping

        ecBLE.onBLEConnectionStateChange { _ in
            self.showAlert(title: "提示", content: "设备断开链接") {}
        }
        ecBLE.onBLECharacteristicValueChange {
            str, hexStr, uint16Array in
            self.revData(str: str, hexStr: hexStr, uint16Array: uint16Array )
        }
    }

    @IBAction func btBack(_ sender: Any) {
        ecBLE.onBLEConnectionStateChange { _ in }
        ecBLE.closeBLEConnection()
        goback()
    }

    func goback() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func textSendDidEndOnExit(_ sender: Any) {
        textViewSend.resignFirstResponder()
    }

    @IBAction func backgroundTouch(_ sender: Any) {
        textViewSend.resignFirstResponder()
    }

    func showAlert(title: String, content: String, cb: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default, handler: {
            _ in
            cb()
        })
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func btClear(_ sender: Any) {
        DispatchQueue.main.async {
            self.textViewRev.text = ""
        }
    }
    @IBAction func btSend(_ sender: Any) {
        if textViewSend == nil { return }
        let sendData = textViewSend.text ?? ""
        if sendData.count == 0 { return }
        if switchSendHex.isOn {
            if sendData.count % 2 != 0 {
                showAlert(title: "提示", content: "数据长度错误，长度必须是双数") {}
                return
            }
            if !isHexString(data: sendData) {
                showAlert(title: "提示", content: "数据格式错误，0-9,a-f,A-F") {}
                return
            }
            ecBLE.easySendData(data: sendData, isHex: true)
        } else {
            ecBLE.easySendData(data: sendData.replacingOccurrences(of: "\n", with: "\r\n"), isHex: false)
        }
    }

    // MARK: - 状态栏

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - ble

    func revData(str: String, hexStr: String, uint16Array:[UInt16]) {
        addToDatabase(array: uint16Array)
        
        DispatchQueue.main.async {
            if( self.textViewRev.text.count > 10000){
                self.textViewRev.text=""
            }
            
            if self.switchRevHex.isOn {
                self.textViewRev.text = self.textViewRev.text + "[" + self.getTimeString() + "]" + hexStr + "\r"
            } else {
                self.textViewRev.text = self.textViewRev.text + "[" + self.getTimeString() + "]" + str + "\r"
            }
            if self.switchScroll.isOn {
                self.textViewRev.layoutManager.allowsNonContiguousLayout = false
                self.textViewRev.scrollRangeToVisible(NSMakeRange(self.textViewRev.text.count, 1))
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
    
    func getDateString() -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYY-MM-dd"// 自定义时间格式
        return dateformatter.string(from: Date())
    }
    func addToDatabase(array: [UInt16]){
        let object: [String: Any] = [
            self.getTimeString(): array
        ]
        print(object)
        database.child("patient1/data/\(getDateString())").updateChildValues(object)
    }
}
