//
//  MainViewController.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import DJIUXSDK

class MainViewController: UIViewController, DJISDKManagerDelegate {
    
    fileprivate let connectViaBridge = false
    fileprivate let bridgeAppIP = "192.168.128.169"
    
    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    var product : DJIBaseProduct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DJISDKManager.registerApp(with: self)
        self.initUI()
        if let product = self.product {
            self.updateStatusBasedOn(product:product);
        }
    }
    
    func initUI() {
        self.modelNameLabel.isHidden = true
        //Disable the connect button by default
        self.connectButton.isEnabled = false
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if let product = product {
            self.product = product
            self.connectButton.isEnabled = true
        }
        self.updateStatusBasedOn(product: product)
        
        ///If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) {(state: DJIUserAccountState, error: Error?) in
            if let error = error {
                showAlertWith("Login failed:\(error.localizedDescription)")
            }
        }
    }
    
    func productDisconnected() {
        let message = "Connection lost. Back to root. "
        let cancelAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
        let backAction = UIAlertAction.init(title: "Back", style: UIAlertAction.Style.default) { (action: UIAlertAction) in
            self.navigationController?.popToRootViewController(animated: true)
        }
        let alertViewController = UIAlertController.init(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(backAction)
        let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        navController.present(alertViewController, animated: true, completion: nil)
        
        self.connectButton.isEnabled = false
        self.product = nil
        self.updateStatusBasedOn(product: self.product)
    }
    
    func updateStatusBasedOn(product:DJIBaseProduct?) {
        self.connectStatusLabel.text = NSLocalizedString("Status: Product Connected", comment: "")
        if let model = product?.model {
            self.modelNameLabel.text = "Model: \(model)"
            self.modelNameLabel.isHidden = false
        } else {
            self.connectStatusLabel.text = "Status: Product Not Connected"
            self.modelNameLabel.text = "Model Unknown"
        }
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            showAlertWith("Registration Error \(error.localizedDescription)")
        } else {
            showAlertWith("Registration Success")
            if connectViaBridge {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
            
        }
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("Never called...")
    }
}
