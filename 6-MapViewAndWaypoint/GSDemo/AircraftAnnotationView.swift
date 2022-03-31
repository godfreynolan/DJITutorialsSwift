//
//  AircraftAnnotationView.swift
//  GSDemo
//
//  Created by Samuel Scherer on 4/25/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class AircraftAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.isEnabled = false
        self.isDraggable = false
        self.image = UIImage(named: "aircraft.png")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func update(heading:Float) {
        self.transform = CGAffineTransform.identity
        self.transform = CGAffineTransform(rotationAngle: CGFloat(heading))
    }
}

