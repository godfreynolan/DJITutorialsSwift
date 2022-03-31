//
//  DemoUtility.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/3/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK

func showAlertWith(result:String) {
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    showAlertWith(title: nil, message: result, cancelAction: nil, defaultAction: okAction, presentingViewController: nil)
}

func showAlertWith(title: String?, message: String, cancelAction:UIAlertAction?, defaultAction:UIAlertAction?, presentingViewController:UIViewController?) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let defaultAction = defaultAction {
            alertController.addAction(defaultAction)
        }
        if let cancelAction = cancelAction {
            alertController.addAction(cancelAction)
        }
        if let presentingViewController = presentingViewController {
            presentingViewController.present(alertController, animated: true, completion: nil)
        } else {
            let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
            navController.present(alertController, animated: true, completion: nil)
        }
    }
}

func fetchAircraft () -> DJIAircraft? {
    return DJISDKManager.product() as? DJIAircraft
}

func fetchFlightController() -> DJIFlightController? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.flightController
}
