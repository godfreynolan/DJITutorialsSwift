//
//  GeoUnlockGroupViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/18/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import DJISDK

class GeoUnlockGroupViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var userUnlockingTableView: UITableView!
    var unlockedZoneGroups = [DJIUnlockedZoneGroup]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadUserUnlockGroupInfo()
    }

    func loadUserUnlockGroupInfo() {
        DJISDKManager.flyZoneManager()?.reloadUnlockedZoneGroupsFromServer(completion: { [weak self] (error:Error?) in
            if let error = error {
                print("reloadUnlockedZoneGroupsFromServer error: \(error.localizedDescription)")
                return
            }
            DJISDKManager.flyZoneManager()?.getLoadedUnlockedZoneGroups(completion: { [weak self](groups: [DJIUnlockedZoneGroup]?, error: Error?) in
                if let groups = groups, error == nil {
                    self?.unlockedZoneGroups = groups
                    self?.userUnlockingTableView.reloadData()
                }
            })
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nullableCell = tableView.dequeueReusableCell(withIdentifier: "UserUnlockingGroup")
        let cell = nullableCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: "UserUnlockingGroup")
        let group = self.unlockedZoneGroups[indexPath.row]
        cell.textLabel?.text = group.sn
        cell.detailTextLabel?.text = "self-unlocking: \(group.selfUnlockedFlyZones.count), custom-unlocking: \(group.customUnlockZones.count)"
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.unlockedZoneGroups.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let unlockedZoneGroup = self.unlockedZoneGroups[indexPath.row]
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc : GeoGroupInfoViewController = mainStoryboard.instantiateViewController(withIdentifier: "GeoGroupInfoViewController") as? GeoGroupInfoViewController {
            vc.unlockedZoneGroup = unlockedZoneGroup
            self.navigationController?.pushViewController(vc, animated: true)
        }

    }
}
