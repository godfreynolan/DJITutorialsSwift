//
//  GeoGroupInfoViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/18/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import DJISDK

class GeoGroupInfoViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var unlockedZoneGroup : DJIUnlockedZoneGroup?
    
    @IBOutlet weak var selfUnlockingTable: UITableView!
    @IBOutlet weak var customUnlockingTable: UITableView!
    fileprivate var flyZoneView : DJIScrollView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flyZoneView = DJIScrollView(parentViewController: self)
        self.flyZoneView?.isHidden = true
        self.flyZoneView?.setDefaultSize()
        
        self.selfUnlockingTable.reloadData()
        self.customUnlockingTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === self.selfUnlockingTable {
            let nullableCell = tableView.dequeueReusableCell(withIdentifier: "SelfUnlockingCell")
            let cell = nullableCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: "SelfUnlockingCell")
            if let zone = self.unlockedZoneGroup?.selfUnlockedFlyZones[indexPath.row] {
                cell.textLabel?.text = zone.name
                cell.detailTextLabel?.text = "AreaID:\(zone.flyZoneID), Lat: \(zone.center.latitude), Long: \(zone.center.longitude)"
            }
            return cell
            
        } else if tableView === self.customUnlockingTable {
            let nullableCell = tableView.dequeueReusableCell(withIdentifier: "CustomUnlockingCell")
            let cell = nullableCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: "CustomUnlockingCell")
            if let zone = self.unlockedZoneGroup?.customUnlockZones[indexPath.row] {
                cell.textLabel?.text = zone.name
                cell.detailTextLabel?.text = "AreaID:\(zone.id), Lat: \(zone.center.latitude), Long: \(zone.center.longitude)"
            }
            return cell
            
        }
        fatalError()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === self.selfUnlockingTable {
            return self.unlockedZoneGroup?.selfUnlockedFlyZones.count ?? 0
        } else if tableView.isEqual(self.customUnlockingTable) {
            return self.unlockedZoneGroup?.customUnlockZones.count ?? 0
        }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.flyZoneView?.isHidden = true
        self.flyZoneView?.show()
        
        if tableView === self.selfUnlockingTable {
            if let unlockedFlyZone = self.unlockedZoneGroup?.selfUnlockedFlyZones[indexPath.row] {
                self.flyZoneView?.write(status: self.formatFlyZoneInformtionString(for: unlockedFlyZone))
            }
        } else if tableView === self.customUnlockingTable {
            if let customUnlockZone = self.unlockedZoneGroup?.customUnlockZones[indexPath.row] {
                self.flyZoneView?.write(status: self.formatCustomUnlockZoneInformtionString(customUnlockZone: customUnlockZone))
            }
        }
    }

    func formatCustomUnlockZoneInformtionString(customUnlockZone:DJICustomUnlockZone) -> String {
        var infoString = ""
        infoString.append("ID:\(customUnlockZone.id)\n")
        infoString.append("Name\(customUnlockZone.name)\n")
        infoString.append("Coordinate:\(customUnlockZone.center.latitude),\(customUnlockZone.center.longitude)\n")
        infoString.append("Radius:\(customUnlockZone.radius)\n")
        infoString.append("StartTime:\(customUnlockZone.startTime), EndTime\(customUnlockZone.endTime)\n")
        infoString.append("isExpired:\(customUnlockZone.isExpired)\n")
        return infoString
    }

    func formatFlyZoneInformtionString(for information:DJIFlyZoneInformation) -> String {
        var infoString = ""
        infoString.append("ID:\(information.flyZoneID)\n")
        infoString.append("Name:\(information.name)\n")
        infoString.append("Coordinate:(\(information.center.latitude),\(information.center.longitude)")
        infoString.append("Radius:\(information.radius)\n")
        infoString.append("StartTime:\(information.startTime), EndTime:\(information.endTime)\n")
        infoString.append("unlockStartTime:\(information.unlockStartTime), unlockEndTime:\(information.unlockEndTime)\n")
        infoString.append("GEOZoneType:\(information.type)")
        infoString.append("FlyZoneType:\(information.shape == .cylinder ? "Cylinder" : "Cone")")
        infoString.append("FlyZoneCategory:\(self.getFlyZoneCategoryString(category: information.category))\n")
        
        if let subFlyZones = information.subFlyZones {
            if subFlyZones.count > 0 {
                infoString.append(self.formatSubFlyZoneInformtionString(for: subFlyZones))
            }
        }
        
        return infoString
    }

    func formatSubFlyZoneInformtionString(for subFlyZoneInformations: [DJISubFlyZoneInformation]) -> String {
        var subInfoString = ""
        for subInformation in subFlyZoneInformations {
            subInfoString.append("-----------------\n")
            subInfoString.append("SubAreaID:\(subInformation.areaID)\n")
            subInfoString.append("Graphic:\(subInformation.shape == .cylinder ? "Circle" : "Polygon")")
            subInfoString.append("MaximumFlightHeight:\(subInformation.maximumFlightHeight)")
            subInfoString.append("Radius:\(subInformation.radius)\n")
            subInfoString.append("Coordinate:(\(subInformation.center.latitude),\(subInformation.center.longitude)")
            
            for point in subInformation.vertices {
                if let coordinate = point as? CLLocationCoordinate2D {
                    subInfoString.append("    (\(coordinate.latitude),\(coordinate.longitude)\n")
                }
            }
            subInfoString.append("-----------------\n")
        }
        return subInfoString
    }

    func getFlyZoneCategoryString(category:DJIFlyZoneCategory) -> String {
        switch category {
        case .warning:
            return "Warning"
        case .restricted:
            return "Restricted"
        case .authorization:
            return "Authorization"
        case .enhancedWarning:
            return "EnhancedWarning"
        default:
            return "Unknown"
        }
    }
}
