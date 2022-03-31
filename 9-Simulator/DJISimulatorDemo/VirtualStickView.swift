//
//  VirtualStickView.swift
//  DJISimulatorDemo
//
//  Created by Samuel Scherer on 5/1/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit

let kStickCenterTargetPositionLength : CGFloat = 20.0

class VirtualStickView : UIView {
    
    @IBOutlet var stickViewBase : UIImageView!
    @IBOutlet var stickView : UIImageView!
    var imageStickNormal : UIImage?
    var imageStickHold : UIImage?
    
    var centerPoint : CGPoint?
    var updateTimer : Timer?
    var touchPoint : CGPoint?

    init(with frame:CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder:NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        self.imageStickNormal = UIImage(named: "stick_normal.png")!
        self.imageStickHold = UIImage(named: "stick_hold.png")!
        self.centerPoint = CGPoint(x: 64, y: 64)
    }

    func sendNotificationWith(direction: CGPoint) {
        let directionValue = NSValue(cgPoint: direction)
        let userInfo = ["dir" : directionValue]
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "StickChanged"), object: self, userInfo: userInfo)
    }

    func stickMoveTo(deltaToCenter:CGPoint) {
        var frame = stickView.frame
        frame.origin.x = deltaToCenter.x
        frame.origin.y = deltaToCenter.y
        stickView.frame = frame
    }
    
    func touchEvent(touches:Set<UITouch>) {
        guard let centerPoint = self.centerPoint else { return }
        if touches.count != 1 { return }

        let touch = touches.first
        let view = touch?.view
        if view !== self { return }

        let touchPoint = touch?.location(in: view) ?? centerPoint
        var targetDirection : CGPoint?
        var rawDirection = CGPoint(x: touchPoint.x - centerPoint.x, y: touchPoint.y - centerPoint.y)
        let length = sqrt(pow(rawDirection.x,2) + pow(rawDirection.y,2))

        if (length < 10.0) && (length > -10.0) {
            targetDirection = CGPoint(x: 0.0, y: 0.0)
            rawDirection.x = 0
            rawDirection.y = 0
        } else {
            let inverseLength = 1.0 / length
            rawDirection.x *= inverseLength
            rawDirection.y *= inverseLength
            targetDirection = CGPoint(x: rawDirection.x * kStickCenterTargetPositionLength, y: rawDirection.y * kStickCenterTargetPositionLength)
        }
        if let target = targetDirection {
            self.stickMoveTo(deltaToCenter: target)
            self.sendNotificationWith(direction: rawDirection)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stickView.image = self.imageStickHold

        if touches.count != 1 { return }

        let touch = touches.first
        guard let view = touch?.view else { return }
        if view !== self { return }

        self.touchPoint = touch?.location(in: view)
        self.startUpdateTimer()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count != 1 { return }
        let touch = touches.first
        let view = touch?.view
        if view !== self { return }
        self.touchPoint = touch?.location(in: view)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.recenterSticks()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.recenterSticks()
    }
    
    func recenterSticks() {
        self.stickView.image = imageStickNormal
        let centerPoint = CGPoint(x: 0.0, y: 0.0)
        self.stickMoveTo(deltaToCenter: centerPoint)
        self.sendNotificationWith(direction: centerPoint)
        self.stopUpdateTimer()
    }

    @objc func onUpdateTimerTicked() {
        guard let touchPoint = self.touchPoint else { return }
        guard let centerPoint = self.centerPoint else { return }
        var dir = CGPoint(x: touchPoint.x - centerPoint.x, y: touchPoint.y - centerPoint.y )
        var dTarget = dir
        let length = sqrt(pow(dir.x, 2) + pow(dir.y,2))
        
        if length > kStickCenterTargetPositionLength {
            let inverseLength = 1.0 / length
            dir.x *= inverseLength
            dir.y *= inverseLength
            dTarget.x = dir.x * kStickCenterTargetPositionLength
            dTarget.y = dir.y * kStickCenterTargetPositionLength
        }

        dir.x = dTarget.x / kStickCenterTargetPositionLength
        dir.y = dTarget.y / kStickCenterTargetPositionLength
        self.stickMoveTo(deltaToCenter: dTarget)
        self.sendNotificationWith(direction: dir)
    }
    
    func startUpdateTimer() {
        if self.updateTimer == nil {
            self.updateTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(onUpdateTimerTicked), userInfo: nil, repeats: true)
            self.updateTimer?.fire()
        }
    }

    func stopUpdateTimer() {
        if let updateTimer = self.updateTimer {
            updateTimer.invalidate()
            self.updateTimer = nil
        }
    }
}
