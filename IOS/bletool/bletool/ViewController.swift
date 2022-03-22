//
//  ViewController.swift
//  bletool
//
//

import UIKit

class DeviceInfo: NSObject {
    var name: String = ""
    var rssi: Int = 0
    init(name: String, rssi: Int) {
        self.name = name
        self.rssi = rssi
        super.init()
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - 变量

    var bleStatus = false
    @IBOutlet var tableView: UITableView!
    var deviceListData: [DeviceInfo] = []
    var refreshControl: UIRefreshControl!
    @IBOutlet var loading: UIActivityIndicatorView!

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        uiInit()
//    初始化
        ecBLE.Init {
            ok, errMsg in
            if ok {
                self.bleStatus = true
                self.startScan()
            } else {
                self.showAlert(title: "Warning", content: "Bluetooth adapter error，errMsg=" + errMsg) {}
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        deviceListData.removeAll()
        tableView.reloadData()
        if bleStatus {
            startScan()
        }
    }

    // MARK: - UI
//ui初始化
    func uiInit() {
        Thread.sleep(forTimeInterval: 3)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = .gray
//        refreshControl.attributedTitle = NSAttributedString(string: "刷新")
        refreshControl.addTarget(self, action: #selector(refreshTabView), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceListData.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        let x = view.viewWithTag(666001) as! UIImageView
        let name = view.viewWithTag(666002) as! UILabel
        let rssiImg = view.viewWithTag(666003) as! UIImageView
        let rssi = view.viewWithTag(666004) as! UILabel
        let nameStr = deviceListData[indexPath.row].name
        let rssiValue = deviceListData[indexPath.row].rssi
        name.text = nameStr
        rssi.text = "\(rssiValue)"
//        if String(nameStr[nameStr.index(nameStr.startIndex, offsetBy: 0)]) == "@", nameStr.count == 11 {
//            logo.image = UIImage(named: "ecble")
//        } else {
//            logo.image = UIImage(named: "ble")
//        }
        if rssiValue >= -41 { rssiImg.image = UIImage(named: "s5") }
        else if rssiValue >= -55 { rssiImg.image = UIImage(named: "s4") }
        else if rssiValue >= -65 { rssiImg.image = UIImage(named: "s3") }
        else if rssiValue >= -75 { rssiImg.image = UIImage(named: "srevData") }
        else if rssiValue < -75 { rssiImg.image = UIImage(named: "s1") }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoading()
        ecBLE.easyConnect(name: deviceListData[indexPath.row].name) {
            ok, errMsg in
            self.hideLoading()
            if ok {
                self.gotoDeviceView()
            } else {
                self.showAlert(title: "Warning", content: "Connection fail，errMsg = " + errMsg) {}
            }
        }
    }

    @objc func refreshTabView() {
        stopScan()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(1)) {
            self.refreshControl.endRefreshing()
            self.deviceListData.removeAll()
            self.reloadTableView()
            self.startScan()
        }
    }

    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func showLoading() {
        view.isUserInteractionEnabled = false
        loading.center = view.center
        loading.startAnimating()
    }

    func hideLoading() {
        loading.stopAnimating()
        view.isUserInteractionEnabled = true
    }

    func showAlert(title: String, content: String, cb: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes", style: .default, handler: {
            _ in
            cb()
        })
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func gotoDeviceView() {
        performSegue(withIdentifier: "gotoDeviceView", sender: self)
    }

    // MARK: - 状态栏

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - ble

    func startScan() {
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

    // MARK: - 工具

    func getStringFirst(str: String) -> String {
        return String(str[str.index(str.startIndex, offsetBy: 1)])
    }
}
