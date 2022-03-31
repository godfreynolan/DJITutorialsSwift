//
//  LimitSpaceOverlay.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK
import MapKit

let kDJILimitFlightSpaceBufferHeight = 5

class LimitSpaceOverlay : MapOverlay {
    
    var limitSpaceInfo : DJIFlyZoneInformation
    
    init(limitSpaceInfo:DJIFlyZoneInformation) {
        self.limitSpaceInfo = limitSpaceInfo
        super.init()
        self.createOverlays()
    }
    
    func overlaysFor(aSubFlyZoneSpace:DJISubFlyZoneInformation) -> [MKOverlay] {
        let isHeightLimit = aSubFlyZoneSpace.maximumFlightHeight > 0 && aSubFlyZoneSpace.maximumFlightHeight < UINT16_MAX
        if aSubFlyZoneSpace.shape == .cylinder {
            let circle = Circle(center: aSubFlyZoneSpace.center, radius: aSubFlyZoneSpace.radius)
            circle.lineWidth = self.strokeLineWidthWith(height: aSubFlyZoneSpace.maximumFlightHeight)
            circle.fillColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: self.limitSpaceInfo.category,
                                                                              isHeightLimit: isHeightLimit,
                                                                              isFill: true)
            circle.strokeColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: self.limitSpaceInfo.category,
                                                                                isHeightLimit: isHeightLimit,
                                                                                isFill: false)
            return [circle]
        } else if aSubFlyZoneSpace.shape == .polygon {
            if aSubFlyZoneSpace.vertices.count <= 0 { return [MKOverlay]() }
            
            let coordinates = aSubFlyZoneSpace.vertices as? [CLLocationCoordinate2D]
            guard var coordinates = coordinates else { return [MKOverlay]() }
            
            let polygon = MapPolygon(coordinates: &coordinates, count: aSubFlyZoneSpace.vertices.count)
            polygon.lineWidth = self.strokeLineWidthWith(height: aSubFlyZoneSpace.maximumFlightHeight)
            polygon.strokeColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: self.limitSpaceInfo.category, isHeightLimit: isHeightLimit, isFill: false)
            polygon.fillColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: self.limitSpaceInfo.category, isHeightLimit: isHeightLimit, isFill: true)
            return [polygon]
        }
        return [MKOverlay]()
    }

    func overlaysFor(aFlyZoneSpace:DJIFlyZoneInformation) -> [MKOverlay] {
        guard let subFlyZones = aFlyZoneSpace.subFlyZones else {
            print("subFlyZones Nil- perhaps should enter the <=0 if check?")
            fatalError()
        }
        
        if subFlyZones.count <= 0 {
            let circle = FlyZoneCircle(center: aFlyZoneSpace.center, radius: aFlyZoneSpace.radius)
            circle.category = aFlyZoneSpace.category
            circle.flyZoneID = aFlyZoneSpace.flyZoneID
            circle.name = aFlyZoneSpace.name
            circle.heightLimit = 0
            return [circle]
        } else {
            var results = [MKOverlay]()
            for aSubSpace in subFlyZones {
                results.append(contentsOf: self.overlaysFor(aSubFlyZoneSpace: aSubSpace))
            }
            return results
        }
    }

    func createOverlays() {
        self.subOverlays = [MKOverlay]()
        self.subOverlays.append(contentsOf: self.overlaysFor(aFlyZoneSpace: self.limitSpaceInfo))
    }
    
    func strokeLineWidthWith(height:NSInteger) -> Float {
        if height <= (30 + kDJILimitFlightSpaceBufferHeight) {
            return 0.0
        }
        return 1.0
    }
}
