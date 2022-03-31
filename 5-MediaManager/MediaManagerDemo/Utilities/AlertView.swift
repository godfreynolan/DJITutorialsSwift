//
//  AlertView.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/14/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit

class AlertView: NSObject {
    
    var alertController : UIAlertController?

    public class func showAlertWith(message:String, titles:[String]?, actionClosure:((Int)->())?) -> AlertView {
        let alertView = AlertView()
        alertView.alertController = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        
        if let titles = titles {
            for title in titles {
                let actionStyle : UIAlertAction.Style = (titles.firstIndex(of: title) == 0) ? .cancel : .default
                let alertAction = UIAlertAction(title: title, style: actionStyle) { (action:UIAlertAction) in
                    if let actionClosure = actionClosure, let titleIndex = titles.firstIndex(of:title) {
                        actionClosure(titleIndex)
                    }
                }
                alertView.alertController?.addAction(alertAction)
            }
        }
        if let navController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            if let alertController = alertView.alertController {
                navController.present(alertController, animated: true, completion: nil)
            }
        }
        return alertView
    }
    
    public func dismissAlertView() {
        self.alertController?.dismiss(animated: true, completion: nil)
    }
    
    public func update(message:String) {
        self.alertController?.message = message
    }
}
