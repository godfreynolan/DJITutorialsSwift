//
//  FlyZoneCircleView.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit

class FlyZoneCircleView : MKCircleRenderer {
    init(circle: FlyZoneCircle) {
        super.init(circle: circle as MKCircle)
        self.fillColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: circle.category,
                                                                        isHeightLimit: false,
                                                                        isFill: true)
        self.strokeColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: circle.category,
                                                                          isHeightLimit: false,
                                                                          isFill: false)
        self.lineWidth = 1.0
    }
}
