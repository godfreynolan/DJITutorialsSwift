//
//  DefaultLayoutViewController.swift
//  UXSDKSwiftSample
//
//  Copyright © 2021 RIIS. All rights reserved.
//

import UIKit
import DJIUXSDK

let ProductCommunicationServiceStateDidChange = "ProductCommunicationServiceStateDidChange"

// We subclass the DUXRootViewController to inherit all its behavior and add
// a couple of widgets in the storyboard.
class DefaultLayoutViewController: DUXDefaultLayoutViewController, DJISDKManagerDelegate {
    
    fileprivate let useDebugMode = false
    fileprivate let bridgeIP = "192.168.128.169"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Please enter your App Key in the info.plist file.
        DJISDKManager.registerApp(with: self)
    }
    
    func showAlertViewWith(message: String) {
        let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Start Connecting to Product
    open func connectToProduct() {
        print("Connecting to product...")
        if useDebugMode {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeIP)
        } else {
            let startedResult = DJISDKManager.startConnectionToProduct()
            
            if startedResult {
                print("Connecting to product started successfully!")
            } else {
                print("Connecting to product failed to start!")
            }
        }
    }
    
    //MARK: - DJISDKManagerDelegate
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            self.showAlertViewWith(message:"Error Registering App: \(error.localizedDescription)")
            return
        }
        self.showAlertViewWith(message: "Registration Success")
        self.connectToProduct()
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if product != nil {
            print("Connection to new product succeeded!")
        }
    }

    func productDisconnected() {
        print("Disconnected from product!")
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) { }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
