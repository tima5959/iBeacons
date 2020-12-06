//
//  BeaconDetailVC.swift
//  iBeacons
//
//  Created by Tim on 06.12.2020.
//

import UIKit
import CoreLocation

class BeaconDetailVC: UIViewController {

    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    
    var beacon: CLBeacon?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uuidLabel.text = beacon?.uuid.uuidString
        majorLabel.text = beacon?.major.stringValue
        minorLabel.text = beacon?.minor.stringValue
        rssiLabel.text = String(beacon?.rssi ?? 0)
        accuracyLabel.text = String(beacon?.accuracy ?? 0) + "" + "метров"
    }
}
