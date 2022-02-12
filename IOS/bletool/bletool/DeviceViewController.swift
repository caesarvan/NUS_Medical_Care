//
//  DeviceViewController.swift
//  bletool
//
//  Created by 莫凡 on 2021/3/7.
//

import UIKit
import FirebaseDatabase
import AAInfographics

class DeviceViewController: UIViewController, UITextFieldDelegate, AAChartViewDelegate {
    
    private let database = Database.database().reference()
    
    public var chartType: AAChartType!
    public var step: Bool?
    private var aaChartModel: AAChartModel!
    private var aaChartView: AAChartView!

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
        
        setUpAAChartView()
                
    }

    @IBAction func btBack(_ sender: Any) {
        ecBLE.onBLEConnectionStateChange { _ in }
        ecBLE.closeBLEConnection()
        goback()
    }
    
    func setUpAAChartView(){
        aaChartView = AAChartView()
                let chartViewWidth = view.frame.size.width
                let chartViewHeight = view.frame.size.height - 500
                aaChartView = AAChartView()
                aaChartView!.frame = CGRect(x: 0,
                                            y: 500,
                                            width: chartViewWidth,
                                            height: chartViewHeight)
                view.addSubview(aaChartView!)
        
        let chartModel = AAChartModel()
                    .chartType(.area)//图表类型
                    .title("Signal ")//图表主标题
                    .subtitle("2020年09月18日")//图表副标题
                    .inverted(false)//是否翻转图形
                    .yAxisTitle("摄氏度")// Y 轴标题
                    .legendEnabled(true)//是否启用图表的图例(图表底部的可点击的小圆点)
                    .tooltipValueSuffix("摄氏度")//浮动提示框单位后缀
                    .categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
                    .colorsTheme(["#fe117c","#ffc069","#06caf4","#7dffc0"])//主题颜色数组
                    .series([
                        AASeriesElement()
                            .name("东京")
                            .data([7.0, 6.9, 9.5, 14.5, 18.2, 21.5, 25.2, 26.5, 23.3, 18.3, 13.9, 9.6]),
                        AASeriesElement()
                            .name("纽约")
                            .data([0.2, 0.8, 5.7, 11.3, 17.0, 22.0, 24.8, 24.1, 20.1, 14.1, 8.6, 2.5]),
                        AASeriesElement()
                            .name("柏林")
                            .data([0.9, 0.6, 3.5, 8.4, 13.5, 17.0, 18.6, 17.9, 14.3, 9.0, 3.9, 1.0]),
                        AASeriesElement()
                            .name("伦敦")
                            .data([3.9, 4.2, 5.7, 8.5, 11.9, 15.2, 17.0, 16.6, 14.2, 10.3, 6.6, 4.8]),
                            ])
        
        aaChartView?.aa_drawChartWithChartModel(chartModel)
                
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
