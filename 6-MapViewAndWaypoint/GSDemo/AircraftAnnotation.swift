//
//  AircraftAnnotation.swift
//  GSDemo
//
//  Created by Samuel Scherer on 4/25/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class AircraftAnnotation : NSObject, MKAnnotation {
    @objc dynamic var coordinate : CLLocationCoordinate2D
    var annotationView : AircraftAnnotationView?
    
    init(coordinate:CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    func update(heading:Float) {
        self.annotationView?.update(heading: heading)
    }
}
