//
//  DemoUtility.swift
//  PlaybackDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 DJI. All rights reserved.
//

import Foundation
import DJIUXSDK
import DJISDK

class DemoUtility: NSObject {
    @objc public class func showResult(result:NSString) {
        DispatchQueue.main.async {
            let alertViewController = UIAlertController(title: nil, message: result as String, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alertViewController.addAction(okAction)
            let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
            navController.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    @objc public class func fetchProduct () -> DJIBaseProduct? {
        return DJISDKManager.product()
    }
    
    @objc public class func fetchAircraft () -> DJIAircraft? {
        return DJISDKManager.product() as? DJIAircraft
    }
    
    @objc public class func fetchCamera () -> DJICamera? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.camera
        }
        return nil
    }
    
    @objc public class func fetchFlightController() -> DJIFlightController? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.flightController
        }
        return nil
    }
}
