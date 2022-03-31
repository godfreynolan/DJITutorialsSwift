//
//  FlyLimitPolygonView.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class FlyLimitPolygonView : MKPolygonRenderer {
    init(polygon: Polygon) {
        super.init(polygon: polygon)
        self.fillColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: polygon.level, isHeightLimit: false, isFill: false)
        self.strokeColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: polygon.level, isHeightLimit: false, isFill: true)
        self.lineWidth = 1.0
        self.lineJoin = CGLineJoin.bevel
        self.lineCap = CGLineCap.butt
    }
}
