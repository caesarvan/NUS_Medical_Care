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
    private var refreshTimes:Int = 0
    private var updateTimes:Int = 0
    
    private var buffer0 = RingBuffer<UInt16>(count: 200)
    private var buffer1 = RingBuffer<UInt16>(count: 200)
    private var buffer2 = RingBuffer<UInt16>(count: 200)
    private var buffer3 = RingBuffer<UInt16>(count: 200)
    private var buffer4 = RingBuffer<UInt16>(count: 200)
    private var buffer5 = RingBuffer<UInt16>(count: 200)
    private var buffer6 = RingBuffer<UInt16>(count: 200)
    private var buffer7 = RingBuffer<UInt16>(count: 200)
    
    
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
                    .chartType(.line)//图表类型
                    .title("Signal Plot")//图表主标题
//                    .subtitle("2020年09月18日")//图表副标题
                    .inverted(false)//是否翻转图形
//                    .yAxisTitle("摄氏度")// Y 轴标题
//                    .legendEnabled(true)//是否启用图表的图例(图表底部的可点击的小圆点)
//                    .tooltipValueSuffix("摄氏度")//浮动提示框单位后缀
//                    .categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun",
//                                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
                    .colorsTheme(["#fe117c","#ffc069","#06caf4","#7dffc0"])//主题颜色数组
                    .series([
                        AASeriesElement()
                            .name("Ch0")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch1")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch2")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch3")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch4")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch5")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch6")
                            .data([UInt16](repeating: 0, count: 200)),
                        AASeriesElement()
                            .name("Ch7")
                            .data([UInt16](repeating: 0, count: 200)),
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
        addToBuffer(array: uint16Array)
//        print(updateTimes)
        if(updateTimes>200){
            if(updateTimes%100==0){
                onlyRefreshTheChartData()
            }
        }
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
    
    // MARK: - AAChart
    
    @objc func onlyRefreshTheChartData() {
        aaChartView?.aa_onlyRefreshTheChartDataWithChartOptionsSeries(configureSeriesDataArray())
        refreshTimes += 1
        print("⏲定时器正在刷新, 刷新次数为: \(refreshTimes) ")
    }
    
    private func configureSeriesDataArray() -> [AASeriesElement] {
            
        self.updateTimes += 1
        print(updateTimes)
            let chartSeriesArr = [
                AASeriesElement()
                    .name("Ch0")
                    .data(buffer0.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch1")
                    .data(buffer1.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch2")
                    .data(buffer2.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch3")
                    .data(buffer3.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch4")
                    .data(buffer4.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch5")
                    .data(buffer5.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch6")
                    .data(buffer6.arrayList as [Any]),
                AASeriesElement()
                    .name("Ch7")
                    .data(buffer7.arrayList as [Any])
            ]
                
            return chartSeriesArr
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
//        print(object)
        database.child("patient1/data/\(getDateString())").updateChildValues(object)
    }
    
    func addToBuffer(array: [UInt16]){
        updateTimes+=1
        self.buffer0.write(array[0])
        self.buffer1.write(array[1])
        self.buffer2.write(array[2])
        self.buffer3.write(array[3])
        self.buffer4.write(array[4])
        self.buffer5.write(array[5])
        self.buffer6.write(array[6])
        self.buffer7.write(array[7])
//        print(buffer0.arrayList)
    }
    
    public struct RingBuffer<T> {
      fileprivate var array: [T?]
      fileprivate var writeIndex = 0
        public init(count: Int) {
          array = [T?](repeating: nil, count: count)
      }

      public mutating func write(_ element: T){
        
          array[writeIndex % array.count] = element
          writeIndex += 1
        
      }
    //    返回顺序buffer
        public var arrayList: [T?]{
            if writeIndex%array.count>0{
                return Array(array[(writeIndex%array.count)...array.count-1]+array[0...(writeIndex%array.count-1)])
            }else{
                return Array(array[0...array.count-1])
            }
        }
    }
    
  
}
