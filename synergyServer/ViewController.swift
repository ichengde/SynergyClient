//
//  ViewController.swift
//  synergyServer
//
//  Created by liuchengde on 2018/2/17.
//  Copyright © 2018年 liuchengde. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController {
    var input = ""
    
    private let Service_UUID: String = "CDD1"
    private let Characteristic_UUID: String = "CDD2"
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var condition: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager.init(delegate: self, queue: .main)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
    }

    @IBAction func buttonDown(_ sender: Any) {
        
        if centralManager?.isScanning ?? false {
            condition.string = "it is scanning \n"
        } else {
            condition.string += "clicked successfully to scan \n"
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
        //self.peripheral?.readValue(for: self.characteristic!)
        
    }
    
    @IBAction func toConnectDown(_ sender: Any) {
        condition.string = "to connect iOS"
        self.centralManager?.connect(peripheral!, options: nil)
        
    }
    
    
    
    override func keyDown(with event: NSEvent) {
        let key = event.characters
        if (key != nil) {
            input += key ?? ""
            self.condition.string += input
        }
    }
}


extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // 判断手机蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("未知的")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持")
        case .unauthorized:
            print("未验证")
        case .poweredOff:
            print("未启动")
        case .poweredOn:
            print("可用")
        }
}
    
    
    /** 发现符合要求的外设 */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        condition.string += "discover peripheral \n"
        
        self.peripheral = peripheral
        print(peripheral)
        // 根据外设名称来过滤
        //        if (peripheral.name?.hasPrefix("WH"))! {
        //            central.connect(peripheral, options: nil)
        //        }
        self.centralManager?.stopScan()
        central.connect(peripheral, options: nil)
    }

    
    /** 连接成功 */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        print("连接成功")
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开连接")
        // 重新连接
        central.connect(peripheral, options: nil)
    }
    
    /** 发现服务 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            print("外设中的服务有：\(service)")
        }
        
        
        //本例的外设中只有一个服务
        //let service = peripheral.services?.last
        // 根据UUID寻找服务中的特征
        // peripheral.discoverCharacteristics([CBUUID.init(string: Characteristic_UUID)], for: service!)
    }
    
    
    /** 发现特征 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic: CBCharacteristic in service.characteristics! {
            print("外设中的特征有：\(characteristic)")
        }
        
        self.characteristic = service.characteristics?.last
        // 读取特征里的数据
        peripheral.readValue(for: self.characteristic!)
        // 订阅
        peripheral.setNotifyValue(true, for: self.characteristic!)
    }
    
    /** 订阅状态 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("订阅失败: \(error)")
            return
        }
        if characteristic.isNotifying {
            print("订阅成功")
        } else {
            print("取消订阅")
        }
    }
    
    /** 接收到数据 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        self.condition.string = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
    }
    
    /** 写入数据 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("写入数据")
    }
}
