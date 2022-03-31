//
//  DemoUtility.swift
//  PlaybackDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 RIIS. All rights reserved.
//
import Foundation
import DJIUXSDK
import DJISDK

func showAlertWith(_ result:String) {
    DispatchQueue.main.async {
        let alertViewController = UIAlertController(title: nil, message: result, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertViewController.addAction(okAction)
        let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        navController.present(alertViewController, animated: true, completion: nil)
    }
}

func fetchCamera () -> DJICamera? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.camera
}

