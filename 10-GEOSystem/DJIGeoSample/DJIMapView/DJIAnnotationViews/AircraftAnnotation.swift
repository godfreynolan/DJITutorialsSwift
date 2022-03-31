//
//  AircraftAnnotation.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/4/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class AircraftAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var annotationView : AircraftAnnotationView?
    
    init(coordinate:CLLocationCoordinate2D, heading:Float) {
        self.coordinate = coordinate
        self.annotationView?.update(heading: heading)
        super.init()
    }
}
