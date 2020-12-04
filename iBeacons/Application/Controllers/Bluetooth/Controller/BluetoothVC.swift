//
//  BluetoothVC.swift
//  iBeacons
//
//  Created by Tim on 03.12.2020.
//

import UIKit
import CoreBluetooth

class BluetoothVC: UIViewController {
    
    private let reuseIdentifire = "BluetoothTableViewCell"
    
    var manager: CBCentralManager?
    var bluetоothPeripherals = [BluetoothModel]()
    
    var blePeripherals = [String: String]()
    var blePeripheralsNamed: [String] {
        get {
            Array(blePeripherals.keys)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        manager = CBCentralManager(delegate: self,
                                   queue: nil,
                                   options: nil)
        
        // Когда наш менеджер работает должным образом, мы можем смотреть, что же находится вокруг нас (после получения состояния .PoweredOn — вызываем функцию scanForPeripheralsWithServices:)
        manager?.scanForPeripherals(withServices: nil, options: nil)
        
        tableView.reloadData()
    }
    
}


extension BluetoothVC: CBCentralManagerDelegate {
    
    // У нас есть периферал — так называются устройства, работающие по протоколу Bluetooth. У каждого периферала есть сервисы, их может быть сколь угодно много, и каждый из них имеет характеристики.
    // Насчет сервисов — это массив CBUUID (класс, представляющий собой 128-битные универсальные уникальные идентификаторы атрибутов, используемых Bluetooth Low Energy прим. пер.), который мы используем в качестве фильтра, чтобы найти устройства только с этим набором UID, это обычная практика в CoreBluetooth.
    // Если передать в качестве аргумента nil — мы сможем увидеть все устройства вокруг. Для производительности, конечно, лучше указать массив нужных нам параметров, но в случае, когда вы их не знаете — не случится ничего страшного, если передать nil, никто не умрет.
    
    
    // Мы получим ответ от аппаратной части — включен у пользователя bluetоoth или нет. Менеджер бесполезен до тех пор, пока мы не получим ответ, что bluetоoth включен, его состояние — .PoweredOn. Остальные состояния можно использовать разве что для того, чтобы попросить пользователя включить bluetooth.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil,
                                       options: nil)
        default:
            presentAlertController("Please activate bluetooth")
        }
    }
    
    // Каждый раз при обнаружении нового устройства у делегата менеджера будет вызвана функция didDiscoverPeripheral на той очереди, которую мы указали при его инициализации. Функция передает нам найденное устройство (peripheral), информацию о нем (advertisementData — что-то, что разработчики чипа решили показывать каждый раз) и относительный уровень сигнала RSSI в децибелах.
    // Всегда держите сильную ссылку на обнаруженный нужный периферал. Если этого не сделать, система решит, что найденное устройство нам не нужно, и отбросит его. Она будет помнить о нем, но у нас к нему уже не будет доступа.
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        guard let name = peripheral.name else { return }
//        let uuid = peripheral.services?.first?.uuid.uuidString
        
        
        
        DispatchQueue.main.async {
            self.blePeripherals[name] = RSSI.stringValue
            self.tableView.reloadData()
        }
        
    }
}

extension BluetoothVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blePeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifire) as? BluetoothTableViewCell else { return UITableViewCell() }
        
        let bleDeviceName = blePeripheralsNamed[indexPath.row]
        let bleDeviceRSSI = blePeripherals[bleDeviceName]
        
        cell.nameLabel.text = bleDeviceName
        cell.rssiLabel.text = bleDeviceRSSI
        
        return cell
    }
    
    
    
    
}
