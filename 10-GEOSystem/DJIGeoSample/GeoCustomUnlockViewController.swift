//
//  GeoCustomUnlockViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/3/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import DJISDK


class GeoCustomUnlockViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var customUnlockedZonesTableView: UITableView!
    var customUnlockZones : [DJICustomUnlockZone]?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadCustomUnlockInfo()
    }
    
    func loadCustomUnlockInfo() {
        guard let modelName = DJISDKManager.product()?.model else { return }
        if modelName == DJIAircraftModelNameInspire1 ||
           modelName == DJIAircraftModelNamePhantom3Professional ||
           modelName == DJIAircraftModelNameMatrice100 {
            
            self.customUnlockZones = DJISDKManager.flyZoneManager()?.getCustomUnlockZonesFromAircraft()
            self.customUnlockedZonesTableView.reloadData()
        } else {
            DJISDKManager.flyZoneManager()?.syncUnlockedZoneGroupToAircraft(completion: { [weak self] (error:Error?) in
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "Sync custom unlock zones to aircraft failed: \(error.localizedDescription)")
                } else {
                    self?.customUnlockZones = DJISDKManager.flyZoneManager()?.getCustomUnlockZonesFromAircraft()
                    self?.customUnlockedZonesTableView.reloadData()
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.customUnlockZones?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let optionalCell = tableView.dequeueReusableCell(withIdentifier: "CustomUnlock")
        let cell = optionalCell ?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle,
                                                   reuseIdentifier: "CustomUnlock")
        
        if let zone = self.customUnlockZones?[indexPath.row] {
            cell.textLabel?.text = zone.name
            cell.detailTextLabel?.text = "Lat: \(zone.center.latitude), Long: \(zone.center.longitude)"
        }
        return cell
    }
    
    
}
