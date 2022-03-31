//
//  FlyZoneCircle.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit
import DJISDK

class FlyZoneCircle : MKCircle {
     public var flyZoneCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
     public var flyZoneRadius : CGFloat = 0.0
     public var category = DJIFlyZoneCategory.unknown
     public var flyZoneID : UInt = 0
     public var name : String?
     public var heightLimit : CGFloat = 0.0
}
