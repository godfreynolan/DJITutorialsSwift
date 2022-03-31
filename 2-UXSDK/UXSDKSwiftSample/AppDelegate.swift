//
//  AppDelegate.swift
//  UXSDKSwiftSample
//
//  Copyright © 2021 RIIS. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Start the registration at the launch of the app. This can be retriggered at anytime from the main view.
        // DJI App key needs to be registered in the Info.plist before calling this method.
        return true
    }
}

