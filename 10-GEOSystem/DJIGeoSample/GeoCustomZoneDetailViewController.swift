//
//  GeoCustomZoneDetailViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/18/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK
import UIKit

class GeoCustomZoneDetailViewController : UIViewController {
    var customUnlockZone : DJICustomUnlockZone?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var expiredLabel: UILabel!
    @IBOutlet weak var enableZoneButton: UIButton!
    var enabledCustomUnlockZone : DJICustomUnlockZone?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let customUnlockZone = self.customUnlockZone else { return }

        self.nameLabel.text = customUnlockZone.name
        self.idLabel.text = customUnlockZone.name
        self.latitudeLabel.text = "\(customUnlockZone)"
        self.longitudeLabel.text = "\(customUnlockZone.center.longitude)"
        self.radiusLabel.text = "\(customUnlockZone.radius)"
        self.startLabel.text = "\(customUnlockZone.startTime)"
        self.endLabel.text = "\(customUnlockZone.endTime)"

        if customUnlockZone.isExpired {
            self.enableZoneButton.titleLabel?.text = "Expired"
            self.expiredLabel.text = "Yes"
            self.enableZoneButton.isEnabled = false
        } else {
            self.expiredLabel.text = "No"
            DJISDKManager.flyZoneManager()?.getEnabledCustomUnlockZone(completion: { [weak self] (zone:DJICustomUnlockZone?, error:Error?) in
                if let error = error {
                    showAlertWith(result: "get enabled custom ulock zone failed:\(error.localizedDescription)")
                    return
                }
                guard let self = self else { return }

                if let zone = zone, zone.id == self.customUnlockZone!.id {
                    self.enableZoneButton.setTitle("Disable", for: .normal)
                    self.enabledCustomUnlockZone = zone
                } else {
                    self.enableZoneButton.setTitle("Enable Zone", for: .normal)
                }
                self.enableZoneButton.isEnabled = true
            })
        }
    }

    @IBAction func enableZoneButtonPressed(_ sender: Any) {
        if self.enabledCustomUnlockZone != nil{
            DJISDKManager.flyZoneManager()?.enable(nil, withCompletion: { [weak self](error:Error?) in
                if let error = error {
                    showAlertWith(result: "Disable custom unlock zone failed:\( error.localizedDescription)")
                    return
                }
                self?.enableZoneButton.setTitle("Enable Zone", for: .normal)
                self?.enabledCustomUnlockZone = nil
                showAlertWith(result: "Disable custom unlock zone success")
            })
        } else {
            DJISDKManager.flyZoneManager()?.enable(self.customUnlockZone!, withCompletion: { [weak self](error:Error?) in
                if let error = error {
                    showAlertWith(result: "Enable custom unlock zone failed:\(error.localizedDescription)")
                    return
                }
                self?.enableZoneButton.setTitle("Disable", for: .normal)
                self?.enabledCustomUnlockZone = self?.customUnlockZone
                showAlertWith(result: "Enable custom unlock zone success")
            })
        }

    }
    
}
