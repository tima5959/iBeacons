//
//  UIViewController + Ext.swift
//  iBeacons
//
//  Created by Tim on 03.12.2020.
//

import UIKit

extension UIViewController {
    func presentAlertController(_ title: String, _ message: String? = "") {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default,
                                     handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
