//
//  DemoUtility.swift
//  PlaybackDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 RIIS. All rights reserved.
//
import Foundation
import DJISDK

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
}

func showAlertWith(_ result:String) {
    DispatchQueue.main.async {
        let alertViewController = UIAlertController(title: nil, message: result as String, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertViewController.addAction(okAction)
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(alertViewController, animated: true, completion: nil)
    }
}

func fetchFlightController() -> DJIFlightController? {
    if let aircraft = DJISDKManager.product() as? DJIAircraft {
        return aircraft.flightController
    }
    return nil
}
