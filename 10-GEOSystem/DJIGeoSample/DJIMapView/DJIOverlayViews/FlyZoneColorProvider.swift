//
//  FlyZoneColorProvider.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/6/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK

extension UIColor {
    convenience init(r: CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
}

//0x979797
fileprivate let heightLimitGrayColorClear = UIColor(r: 151, g: 151, b: 151, a: 0.1)
fileprivate let heightLimitGrayColorSolid = UIColor(r: 151, g: 151, b: 151, a: 1)

//0xDE4329
fileprivate let heightLimitRedColorClear = UIColor(r: 222, g: 67, b: 41, a: 0.1)
fileprivate let heightLimitRedColorSolid = UIColor(r: 222, g: 67, b: 41, a: 1)

//0x1088F2
fileprivate let heightLimitBlueColorClear = UIColor(r: 16, g: 136, b: 242, a: 0.1)
fileprivate let heightLimitBlueColorSolid = UIColor(r: 16, g: 136, b: 242, a: 1)

//0xFFCC00
fileprivate let flySafeWarningYellowColorClear = UIColor(r: 255, g: 204, b: 0, a: 0.1)
fileprivate let flySafeWarningYellowColorSolid = UIColor(r: 255, g: 204, b: 0, a: 1)

//0xEE8815
fileprivate let flysafeWarningColorYellowClear = UIColor(r: 238, g: 238, b: 136, a: 0.1)
fileprivate let flysafeWarningColorYellowSolid = UIColor(r: 238, g: 238, b: 136, a: 1)

class FlyZoneColorProvider {
    
    class func getFlyZoneOverlayColorFor(category: DJIFlyZoneCategory, isHeightLimit: Bool, isFill:Bool) -> UIColor {
        if isHeightLimit {
            return isFill ? heightLimitGrayColorClear : heightLimitGrayColorSolid
        }
        
        switch category {
        case .authorization:
            return isFill ? heightLimitBlueColorClear : heightLimitBlueColorSolid
        case .restricted:
            return isFill ? heightLimitRedColorClear : heightLimitRedColorSolid
        case .warning:
            return isFill ? flySafeWarningYellowColorClear : flySafeWarningYellowColorSolid
        case .enhancedWarning:
            return isFill ? flysafeWarningColorYellowClear : flysafeWarningColorYellowSolid
        case .unknown:
            return UIColor(r: 0, g: 0, b: 0, a: 0)
        @unknown default:
            fatalError()
        }
    }
    
}
