//
//  DemoUtility.swift
//  DJISimulatorDemo
//
//  Created by Samuel Scherer on 4/30/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK

func showAlertWith(_ result:String) {
    DispatchQueue.main.async {
        let alertViewController = UIAlertController(title: nil, message: result as String, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertViewController.addAction(okAction)
        let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        navController.present(alertViewController, animated: true, completion: nil)
    }
}

func showAlertWith(title:String?, message:String, cancelAction:UIAlertAction, defaultAction:UIAlertAction, presentingViewController:UIViewController) {
    let alertViewController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    alertViewController.addAction(cancelAction)
    alertViewController.addAction(defaultAction)
    presentingViewController.present(alertViewController, animated: true, completion: nil)
}

func fetchProduct () -> DJIBaseProduct? {
    return DJISDKManager.product()
}

func fetchAircraft () -> DJIAircraft? {
    return DJISDKManager.product() as? DJIAircraft
}

func fetchFlightController() -> DJIFlightController? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.flightController
}
