//
//  MapPolygon.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class MapPolygon : MKPolygon {
    var strokeColor : UIColor?
    var fillColor : UIColor?
    var lineWidth : Float = 0.0
    var lineDashPhase = 0.0
    var lineCap = CGLineCap(rawValue: 0)
    var lineJoin = CGLineJoin(rawValue: 0)
    var lineDashPattern : [NSNumber]?
}
