//
//  CustomUnlockOverlay.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK

class CustomUnlockOverlay : MapOverlay {
    public var customUnlockInformation : DJICustomUnlockZone
    
    init(customUnlockInformation:DJICustomUnlockZone) {
        self.customUnlockInformation = customUnlockInformation
        super.init()
    }
    
    convenience init(customUnlockInformation:DJICustomUnlockZone, isEnabled:Bool) {
        self.init(customUnlockInformation:customUnlockInformation)
        self.createOverlays(isEnabled: isEnabled)
    }
    
    func createOverlays(isEnabled:Bool) {
        let circle = Circle(center: self.customUnlockInformation.center,
                            radius: self.customUnlockInformation.radius)

        circle.lineWidth = 1
        let greenColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.2)
        let blueColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2)
        circle.fillColor = isEnabled ? greenColor : blueColor
        circle.strokeColor = isEnabled ? greenColor : blueColor

        self.subOverlays = [MKOverlay]()
        self.subOverlays.append(circle)
    }
}
