//
//  BeaconsVC.swift
//  iBeacons
//
//  Created by Tim on 03.12.2020.
//

import UIKit
import CoreLocation

class BeaconsVC: UIViewController {
    
    private let reuseIdentifier = "BeaconsTableViewCell"
    private let segueIdentifier = "BeaconDetailVCSegue"
    
    let defaultUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
    private let locationManager = CLLocationManager()
    private var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    private var beacons = [CLProximity: [CLBeacon]]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        locationManager.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop monitoring when the view disappears.
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Stop ranging when the view disappears.
        for constraint in beaconConstraints.keys {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
    }
    
    @IBAction func addBeacon(_ sender: Any) {
        findBeacon()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            if let indexPath = tableView.indexPathForSelectedRow {
                let detailVC = segue.destination as! BeaconDetailVC
                let keys = Array(beacons.keys)[indexPath.section]
                let beacon = beacons[keys]?[indexPath.row]
                
                detailVC.beacon = beacon
            }
        }
    }
    
}

extension BeaconsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let sectionKeys = Array(beacons.keys)
        let sectionKey = sectionKeys[section]
        
        switch sectionKey {
        case .immediate:
            title = "Маяк находится в непосредственной близости "
        case .near:
            title = "Маяк находится относительно близко"
        case .far:
            title = "Маяк далеко"
        default:
            title = "Расположение маяка неизвестно"
        }
        return title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return beacons.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(beacons.values)[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! BeaconsTableViewCell
        
        let key = Array(beacons.keys)[indexPath.section]
        let value = beacons[key]
        
        guard let beacon = value?[indexPath.row] else { return cell }
        
        cell.uuidLabel.text = beacon.uuid.uuidString
        cell.majorLabel.text = beacon.major.stringValue
        cell.minorLabel.text = beacon.minor.stringValue
        cell.rssiLabel.text = String(beacon.rssi)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
}

extension BeaconsVC: CLLocationManagerDelegate {
    // Когда устройство входит в зону действия бикона срабатывает данный метод
    // Он получает состояние региона и начинает отслеживать бикон
    //    MARK: DidDeterminateState
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let beaconRegion = region as? CLBeaconRegion
        if state == .inside {
            manager.startRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        } else {
            manager.stopRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        }
    }
    //    MARK: DidRange
    // Когда биконов много срабатывает данный метод
    // Он получает характеристики биконов
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        // Биконы классифицируются по близости расположения (proximity)
        // Бикон может соответствовать нескольким ограничениям (constraints) и соответственно показываться несколько раз
        // Добавляю биконы в словарь где ключ - ограничения (constraints)
        beaconConstraints[beaconConstraint] = beacons
        // Удаляю из массива все биконы чтобы затем добавить биконы отфильтрованные по близости
        self.beacons.removeAll()
        
        var allBeacons = [CLBeacon]()
        
        for regionResult in beaconConstraints.values {
            allBeacons.append(contentsOf: regionResult)
        }
        
        for range in [CLProximity.unknown, .immediate, .near, .far] {
            let proximityBeacons = allBeacons.filter {
                $0.proximity == range
            }
            if !proximityBeacons.isEmpty {
                self.beacons[range] = proximityBeacons
                print(self.beacons)
            }
        }
        tableView.reloadData()
    }
}

extension BeaconsVC {
    func findBeacon() {
        let alert = UIAlertController(title: "Find iBeacons",
                                      message: "Please enter beacon UUID",
                                      preferredStyle: .alert)
        
        var textField: UITextField!
        
        alert.addTextField { (txtField) in
            // TODO: Add mask for iBeacon
            txtField.placeholder = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
            txtField.text = self.defaultUUID
            textField = txtField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        let addAction = UIAlertAction(title: "Add",
                                      style: .default) { alert in
            if let uuidString = textField.text, let uuid = UUID(uuidString: uuidString) {
                // Запрашиваю разрешение на отслеживание локации
                self.locationManager.requestWhenInUseAuthorization()
                // Передаю и текстфилда ограничение по которому стоит искать биконы (uuid)
                let constraint = CLBeaconIdentityConstraint(uuid: uuid)
                // Добавляю в словарь данное ограничение
                self.beaconConstraints[constraint] = []
                // Регион используется для обнаружения бикона
                let beaconRegion = CLBeaconRegion(
                    beaconIdentityConstraint: constraint,
                    identifier: uuid.uuidString
                )
                // Начал отслеживать биконы по uuid при помощи региона
                self.locationManager.startMonitoring(for: beaconRegion)
            } else {
                let invalidAlert = UIAlertController(title: "Неправильный UUID",
                                                     message: "Пожалуйста введите верный UUID",
                                                     preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                invalidAlert.addAction(okAction)
                self.present(invalidAlert, animated: true)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        present(alert, animated: true)
    }
}
