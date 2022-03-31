//
//  RootViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/3/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import DJISDK

let kUseBridge = false
let kBridgeIP = "192.168.128.169"

class RootViewController : UIViewController, DJISDKManagerDelegate {
    var product : DJIBaseProduct?
    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //Please enter the App Key in info.plist file to register the app.
        DJISDKManager.registerApp(with: self)
        if let product = self.product {
            self.updateStatusFor(product)
        }
    }

    override func viewDidLoad() {
        self.initUI()
        super.viewDidLoad()
    }

    func initUI() {
        self.title = "DJI GEO Demo"
        self.modelNameLabel.isHidden = true
        //Disable the connect button by default
        self.connectButton.isEnabled = false
    }
    
    func updateStatusFor(_ product:DJIBaseProduct?) {
        if let product = product {
            self.connectStatusLabel.text = "Status: Product Connected"
            self.modelNameLabel.text = "Model: \(product.model ?? "Unknown")"
            self.modelNameLabel.isHidden = false
        } else {
            self.connectStatusLabel.text = "Status: Product Not Connected"
            self.modelNameLabel.text = "Model: Unknown"
        }
    }

//MARK: - DJISDKManager Delegate Methods
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            showAlertWith(result: "Registration Error: \(error)")
            self.connectButton.isEnabled = false
            return
        }
        if kUseBridge {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: kBridgeIP)
        } else {
            DJISDKManager.startConnectionToProduct()
        }
    }

//MARK: DJIBaseProductDelegate Method
    func productConnected(_ product: DJIBaseProduct?) {
        if let product = product {
            self.product = product
            self.connectButton.isEnabled = true
        } else {
            self.productDisconnected()
        }
        self.updateStatusFor(product)
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state:DJIUserAccountState, error:Error?) in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            }
        }
    }
    
    func productDisconnected() {
        let message = "Connection lost. Back to root."
        let cancelAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
        let backAction = UIAlertAction(title: "Back", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            if let topVC = self.navigationController?.topViewController {
                if !(topVC is RootViewController) {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        showAlertWith(title: nil, message: message, cancelAction: cancelAction, defaultAction: backAction, presentingViewController: self)
        self.connectButton.isEnabled = false
        self.product = nil
        
        self.updateStatusFor(nil)
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {}
}
