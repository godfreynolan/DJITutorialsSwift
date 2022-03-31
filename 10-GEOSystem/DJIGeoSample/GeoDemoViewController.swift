//
//  GeoDemoViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/12/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import MapKit
import DJISDK

class GeoDemoViewController : UIViewController, DJIFlyZoneDelegate, DJIFlightControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var loginStateLabel: UILabel!
    @IBOutlet weak var unlockBtn: UIButton!
    @IBOutlet weak var flyZoneStatusLabel: UILabel!
    @IBOutlet weak var getUnlockButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var customUnlockButton: UIButton!
    @IBOutlet weak var showFlyZoneMessageTableView: UITableView!

    var mapController: MapController?
    var updateLoginStateTimer : Timer?
    var updateFlyZoneDataTimer : Timer?
    var unlockFlyZoneIDs = [NSNumber]()
    var unlockedFlyZones = [DJIFlyZoneInformation]()
    var selectedFlyZone : DJIFlyZoneInformation?
    var isUnlockEnable = false
    var flyZoneView : DJIScrollView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pickerContainerView.isHidden = true
        
        guard let aircraft = fetchAircraft() else { return }

        aircraft.flightController?.delegate = self
        DJISDKManager.flyZoneManager()?.delegate = self
        self.initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let aircraft = fetchAircraft() {
            aircraft.flightController?.simulator?.setFlyZoneLimitationEnabled(true, withCompletion: { (error:Error?) in
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "setFlyZoneLimitationEnabled failed:\(error.localizedDescription)")
                } else {
                    print("setFlyZoneLimitationEnabled success")
                }
            })
        }

        self.updateLoginStateTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                          target: self,
                                                          selector: #selector(onUpdateLoginState),
                                                          userInfo: nil,
                                                          repeats: true)
        
        self.updateFlyZoneDataTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                           target: self,
                                                           selector: #selector(onUpdateFlyZone),
                                                           userInfo: nil,
                                                           repeats: true)
        
        self.mapController?.updateFlyZonesInSurroundingArea()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let aircraft = fetchAircraft() {
            aircraft.flightController?.simulator?.setFlyZoneLimitationEnabled(false, withCompletion: { (error:Error?) in
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "setFlyZoneLimitationEnabled failed:\(error.localizedDescription)")
                } else {
                    print("setFlyZoneLimitationEnabled success")
                }
            })
        }
        self.updateLoginStateTimer = nil
        self.updateFlyZoneDataTimer = nil
    }

    func initUI() {
        self.title = "DJI GEO Demo"
        
        self.mapController = MapController(map: self.mapView)
        self.flyZoneView = DJIScrollView(parentViewController: self)
        self.flyZoneView?.isHidden = true
        self.flyZoneView?.setDefaultSize()
    }

    //MARK: IBAction Methods
    @IBAction func onLoginButtonClicked(_ sender: Any) {
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: true) { (_:DJIUserAccountState, error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "GEO Login Error: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "GEO Login Success")
            }
        }
    }
    
    @IBAction func onLogoutButtonClicked(_ sender: Any) {
        DJISDKManager.userAccountManager().logOutOfDJIUserAccount { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Logout error: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Logout success")
            }
        }
    }
    
    @IBAction func onUnlockButtonClicked(_ sender: Any) {
        self.showFlyZoneIDInputView()
    }
    
    @IBAction func onGetUnlockButtonClicked(_ sender: Any) {
        DJISDKManager.flyZoneManager()?.getUnlockedFlyZonesForAircraft(completion: { [weak self] (infos:[DJIFlyZoneInformation]?, error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Get Unlock Error: \(error.localizedDescription)")
            } else {
                guard let infos = infos else { fatalError() }
                guard let self = self else { return }
                var unlockInfo = "unlock zone count = \(infos.count) \n"
                self.unlockedFlyZones.removeAll()
                self.unlockedFlyZones.append(contentsOf: infos)
                for info in infos {
                    unlockInfo = unlockInfo + "ID:\(info.flyZoneID) Name:\(info.name) Begin:\(info.unlockStartTime) end:\(info.unlockEndTime)\n"
                }
                DJIGeoSample.showAlertWith(result: unlockInfo)
            }
        })
    }
    
    @IBAction func onStartSimulatorButtonClicked(_ sender: Any) {
        guard let flightController = DJIGeoSample.fetchFlightController() else { return }

        let alertController = UIAlertController(title: "", message: "Input coordinate", preferredStyle: .alert)
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "latitude"
        }
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "longitude"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let startAction = UIAlertAction(title: "Start", style: .default) { (action:UIAlertAction) in
            guard let latitudeString = alertController.textFields?[0].text else { return }
            guard let longitudeString = alertController.textFields?[1].text else { return }
            guard let latitude = Double(latitudeString) else { return }
            guard let longitude = Double(longitudeString) else { return }

            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            flightController.simulator?.start(withLocation: location,
                                              updateFrequency: 20,
                                              gpsSatellitesNumber: 10,
                                              withCompletion: { [weak self] (error:Error?) in
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "Start simulator error: \(error.localizedDescription)")
                } else {
                    DJIGeoSample.showAlertWith(result: "Start simulator success")
                    self?.mapController?.refreshMapViewRegion()
                    self?.mapController?.aircraftAnnotation = nil
                }
            })
        }

        alertController.addAction(cancelAction)
        alertController.addAction(startAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func onStopSimulatorButtonClicked(_ sender: Any) {
        guard let flightController = DJIGeoSample.fetchFlightController() else { return }
        
        flightController.simulator?.stop(completion: { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Stop simulator error:\(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Stop simulator success")
            }
        })
    }

    @IBAction func enableUnlocking(_ sender: Any) {
        self.pickerContainerView.isHidden = false
        self.pickerView.reloadAllComponents()
    }

    @IBAction func setSelectedUnlockEnabled(_ sender: Any) {
        guard let selectedInfo = self.selectedFlyZone else { return }
        
        selectedInfo.setUnlockingEnabled(self.isUnlockEnable) { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Set unlocking enabled failed: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Set unlocking enabled success")
            }
        }
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.pickerContainerView.isHidden = true
    }

    //MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return self.unlockedFlyZones.count
        } else if component == 1 {
            return 2
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title = ""
        
        if component == 0 {
            title = "\(self.unlockedFlyZones[row].flyZoneID)"
        } else if component == 1 {
            title = row == 0 ? "YES" : "NO"
        }
        return title
    }

    //MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            if self.unlockedFlyZones.count > row {
                self.selectedFlyZone = self.unlockedFlyZones[row]
            }
        } else if component == 1 {
            self.isUnlockEnable = pickerView.selectedRow(inComponent: 1) == 0
        }
    }

    func showFlyZoneIDInputView() {
        let alertController = UIAlertController(title: "", message: "Input ID", preferredStyle: .alert)
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "Input"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak self] (action:UIAlertAction) in
            if let flyZoneIdText = alertController.textFields?[0].text  {
                let flyZoneID = NSNumber(nonretainedObject: Int(flyZoneIdText))
                self?.unlockFlyZoneIDs.append(flyZoneID)
            }
            self?.showFlyZoneIDInputView()
        }

        let unlockAction = UIAlertAction(title: "Unlock", style: .default) { [weak self] (action:UIAlertAction) in
            guard let self = self else { return }
            if let content = alertController.textFields?[0].text {
                if let idToUnlock = Int(content) {
                    self.unlockFlyZoneIDs.append(NSNumber(value: idToUnlock))
                }
            }
            
            DJISDKManager.flyZoneManager()?.unlockFlyZones(self.unlockFlyZoneIDs, withCompletion: { (error:Error?) in
                self.unlockFlyZoneIDs.removeAll()
                
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "unlock fly zones failed: \(error.localizedDescription)")
                    return
                }
                DJISDKManager.flyZoneManager()?.getUnlockedFlyZonesForAircraft(completion: { (infos:[DJIFlyZoneInformation]?, error:Error?) in
                    if let error = error {
                        DJIGeoSample.showAlertWith(result: "get unlocked fly zones failed: \(error.localizedDescription)")
                        return
                    }
                    guard let infos = infos else { fatalError() } //Should return at least an empty array if no error
                    var resultMessage = "Unlock Zones: \(infos.count)"
                    for info in infos {
                        resultMessage = resultMessage + "\n ID:\(info.flyZoneID) Name:\(info.name) Begin:\(info.unlockStartTime) End:\(info.unlockEndTime)\n"
                    }
                    DJIGeoSample.showAlertWith(result: resultMessage)
                })

            })
        }

        alertController.addAction(cancelAction)
        alertController.addAction(continueAction)
        alertController.addAction(unlockAction)
        self.present(alertController, animated: true, completion: nil)
    }

    @objc func onUpdateLoginState() {
        let state = DJISDKManager.userAccountManager().userAccountState
        var stateString = "DJIUserAccountStatusUnknown"
        
        switch state {
        case .notLoggedIn:
            stateString = "DJIUserAccountStatusNotLoggedIn"
        case .notAuthorized:
            stateString = "DJIUserAccountStatusNotVerified"
        case .authorized:
            stateString = "DJIUserAccountStatusSuccessful"
        case .tokenOutOfDate:
            stateString = "DJIUserAccountStatusNotLoggedIn"
        case .unknown:
            fallthrough
        @unknown default:
            stateString = "DJIUserAccountStatusUnknown"
        }

        self.loginStateLabel.text = stateString
    }
    
    @objc func onUpdateFlyZone() {
        self.showFlyZoneMessageTableView.reloadData()
    }
    //MARK: - DJIFlyZoneDelegate Method
    func flyZoneManager(_ manager: DJIFlyZoneManager, didUpdate state: DJIFlyZoneState) {
        var flyZoneStatusString = "Unknown"
        switch state {
        case .clear:
            flyZoneStatusString = "NoRestriction"
        case .inWarningZone:
            fallthrough
        case .inWarningZoneWithHeightLimitation:
            flyZoneStatusString = "AlreadyInWarningArea"
        case .nearRestrictedZone:
            flyZoneStatusString = "ApproachingRestrictedArea"
        case .inRestrictedZone:
            flyZoneStatusString = "AlreadyInRestrictedArea"
        case .unknown:
            fallthrough
        @unknown default:
            flyZoneStatusString = "Unknown"
        }
        self.flyZoneStatusLabel.text = flyZoneStatusString
    }
    
    //MARK: - DJIFlightControllerDelegate Method
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        guard let aircraftCoordinate = state.aircraftLocation?.coordinate else { return }
        if CLLocationCoordinate2DIsValid(aircraftCoordinate) {
            // Convert degrees to radians
            let heading = Float(state.attitude.yaw * Double.pi / 180.0)
            self.mapController?.updateAircraft(coordinate: aircraftCoordinate,
                                               heading: heading)
        }
    }

    //MARK: - UITableViewDelgete
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mapController?.flyZones.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nullableCell = tableView.dequeueReusableCell(withIdentifier: "flyzone-id")
        let cell = nullableCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: "flyzone-id")

        if let flyZone = self.mapController?.flyZones[indexPath.row] {
            cell.textLabel?.text = "\(flyZone.flyZoneID):\(self.getFlyZoneStringFor(flyZone.category)):\(flyZone.name)"
            cell.textLabel?.adjustsFontSizeToFitWidth = true
        }
        return cell
    }

    func getFlyZoneStringFor(_ category: DJIFlyZoneCategory) -> String {
        switch category {
        case .warning:
            return "Warning"
        case .restricted:
            return "Restricted"
        case .authorization:
            return "Authorization"
        case .enhancedWarning:
            return "EnhancedWarning"
        case .unknown:
            fallthrough
        @unknown default:
            return "Unknown"
        }
    }

    func stringFor(_ subFlyZones: [DJISubFlyZoneInformation]?) -> String? {
        guard let subFlyZones = subFlyZones else { return nil }
        var subInfoString = ""
        for subZone in subFlyZones {
            subInfoString.append("-----------------\n")
            subInfoString.append("SubAreaID:\(subZone.areaID)")
            subInfoString.append("Graphic:\( subZone.shape == .cylinder ? "Circle": "Polygon")")
            subInfoString.append("MaximumFlightHeight:\(subZone.maximumFlightHeight)")
            subInfoString.append("Radius:\(subZone.radius)")
            subInfoString.append("Coordinate:\(subZone.center.latitude),\(subZone.center.longitude)")
            for point in subZone.vertices {
                if let coordinate = point as? CLLocationCoordinate2D {
                    subInfoString.append("     \(coordinate.latitude),\(coordinate.longitude)\n")
                }
            }
            subInfoString.append("-----------------\n")
        }
        return subInfoString;
    }

    func stringFor(_ flyZone:DJIFlyZoneInformation) -> String {
        var infoString = ""
        infoString.append("ID:\(flyZone.flyZoneID)n")
        infoString.append("Name:\(flyZone.name)\n")
        infoString.append("Coordinate:(\(flyZone.center.latitude),\(flyZone.center.longitude)\n")
        infoString.append("Radius:\(flyZone.radius)\n")
        infoString.append("StartTime:\(flyZone.startTime), EndTime:\(flyZone.endTime)\n")
        infoString.append("unlockStartTime:\(flyZone.unlockStartTime), unlockEndTime:\(flyZone.unlockEndTime)\n")
        infoString.append("GEOZoneType:\(flyZone.type)")
        infoString.append("FlyZoneType:\(flyZone.shape == .cylinder ? "Cylinder" : "Cone")")
        infoString.append("FlyZoneCategory:\(self.getFlyZoneStringFor(flyZone.category))\n")

        if flyZone.subFlyZones?.count ?? -1 > 0 {
            if let subInfoString = self.stringFor(flyZone.subFlyZones) {
                infoString.append(subInfoString)
            }
        }
        
        return infoString
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.flyZoneView?.isHidden = false
        self.flyZoneView?.show()
        if let selectedFlyZone = self.mapController?.flyZones[indexPath.row] {
            self.flyZoneView?.write(status:self.stringFor(selectedFlyZone))
        }
    }

    func flyZoneManager(_ manager: DJIFlyZoneManager,
                        didUpdateBasicDatabaseUpgradeProgress progress: Float,
                        andError error: Error?) { }
    
    func flyZoneManager(_ manager: DJIFlyZoneManager,
                        didUpdateFlyZoneNotification notification: DJIFlySafeNotification) { }
}
