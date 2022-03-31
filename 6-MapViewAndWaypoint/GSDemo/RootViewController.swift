//
//  RootViewController.swift
//  GSDemo
//
//  Created by Samuel Scherer on 4/26/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import DJISDK


class RootViewController : UIViewController, GSButtonViewControllerDelegate, WaypointConfigViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate {
    
    fileprivate let useBridgeMode = false
    fileprivate let bridgeIPString = "192.168.128.169"

    var isEditingPoints = false
    var gsButtonVC : GSButtonViewController?
    var waypointConfigVC : WaypointConfigViewController?
    var mapController : MapController?
    var locationManager : CLLocationManager?
    var userLocation : CLLocationCoordinate2D?
    var droneLocation : CLLocationCoordinate2D?
    var waypointMission : DJIMutableWaypointMission?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var gpsLabel: UILabel!
    @IBOutlet weak var hsLabel: UILabel!
    @IBOutlet weak var vsLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startUpdateLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.locationManager?.stopUpdatingLocation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerApp()
        self.initUI()
        self.initData()
    }

    func prefersStatusBarHidden() -> Bool {
        return false
    }

    //MARK:  Init Methods
    func initData() {
        self.userLocation = kCLLocationCoordinate2DInvalid
        self.droneLocation = kCLLocationCoordinate2DInvalid
        self.mapController = MapController()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoints(tapGesture:)))
        self.mapView.addGestureRecognizer(tapGesture)
    }
    
    func initUI() {
        self.modeLabel.text = "N/A"
        self.gpsLabel.text = "0"
        self.vsLabel.text = "0.0 M/S"
        self.hsLabel.text = "0.0 M/S"
        self.altitudeLabel.text = "0 M"
        
        self.gsButtonVC = GSButtonViewController()
        if let gsButtonVC = self.gsButtonVC {
            gsButtonVC.view.frame = CGRect(x: 0.0,
                                           y: self.topBarView.frame.origin.y + self.topBarView.frame.size.height,
                                           width: self.gsButtonVC!.view.frame.size.width,
                                           height: self.gsButtonVC!.view.frame.size.height)
            gsButtonVC.delegate = self
            self.view.addSubview(self.gsButtonVC!.view)
        }

        self.waypointConfigVC = WaypointConfigViewController()

        self.waypointConfigVC?.view.alpha = 0
        self.waypointConfigVC?.view.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        self.waypointConfigVC?.view.center = self.view.center
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            self.waypointConfigVC?.view.center = self.view.center
        }
        
        self.waypointConfigVC?.delegate = self
        if let _ = self.waypointConfigVC {
            self.view.addSubview(self.waypointConfigVC!.view)
        }
    }

    func registerApp() {
        DJISDKManager.registerApp(with: self)
    }
    
    //MARK: DJISDKManagerDelegate Methods
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            let registerResult = "Registration Error: \(error.localizedDescription)"
            showAlertWith(registerResult)
        } else {
            if useBridgeMode {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeIPString)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
        }
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if let _ = product, let flightController = fetchFlightController() {
            flightController.delegate = self
        } else {
            showAlertWith("Flight controller disconnected")
        }
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state:DJIUserAccountState, error: Error?) in
            if let error = error {
                NSLog("Login failed: %@", error.localizedDescription)
            }
        }
    }
    
    func missionOperator() -> DJIWaypointMissionOperator? {
        return DJISDKManager.missionControl()?.waypointMissionOperator()
    }
    
    func focusMap() {
        guard let droneLocation = self.droneLocation else {
            return
        }
        
        if CLLocationCoordinate2DIsValid(droneLocation) {
            let center = CLLocationCoordinate2D(latitude: droneLocation.latitude, longitude: droneLocation.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }

    //MARK:  CLLocation Methods
    func startUpdateLocation() {
        if CLLocationManager.locationServicesEnabled() {
            if self.locationManager == nil {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager?.distanceFilter = 0.1
                self.locationManager?.requestAlwaysAuthorization()
            }
        } else {
            showAlertWith("Location Service is not available")
        }
    }

    //MARK:  UITapGestureRecognizer Methods
    @objc func addWaypoints(tapGesture:UITapGestureRecognizer) {
        let point = tapGesture.location(in: self.mapView)
        if tapGesture.state == UIGestureRecognizer.State.ended {
            if self.isEditingPoints {
                self.mapController?.add(point: point, for: self.mapView)
            }
        }
    }
    
    //MARK - WaypointConfigViewControllerDelegate Methods
    func cancelBtnActionInDJIWaypointConfigViewController(viewController: WaypointConfigViewController) {
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 0
        }
    }
    
    func showAlertViewWith(title:String, message:String?) {
        let alert = UIAlertController(title: title, message: message ?? "", preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func finishBtnActionInDJIWaypointConfigViewController(viewController: WaypointConfigViewController) {
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 0
        }
        
        if let waypointMission = self.waypointMission, let waypointConfigVC = self.waypointConfigVC {
            for waypoint in waypointMission.allWaypoints() {
                let altitude = Float(waypointConfigVC.altitudeTextField.text ?? "20") ?? 20.0
                waypoint.altitude = altitude
            }
        }

        if let waypointConfigVC = self.waypointConfigVC {
            self.waypointMission?.maxFlightSpeed = ((self.waypointConfigVC?.maxFlightSpeedTextField.text ?? "0.0") as NSString).floatValue
            self.waypointMission?.autoFlightSpeed = ((self.waypointConfigVC?.autoFlightSpeedTextField.text ?? "0.0") as NSString).floatValue
            
            let selectedHeadingIndex = waypointConfigVC.headingSegmentedControl.selectedSegmentIndex
            self.waypointMission?.headingMode = DJIWaypointMissionHeadingMode(rawValue:UInt(selectedHeadingIndex)) ?? DJIWaypointMissionHeadingMode.auto
            
            let selectedActionIndex = waypointConfigVC.actionSegmentedControl.selectedSegmentIndex
            self.waypointMission?.finishedAction = DJIWaypointMissionFinishedAction(rawValue: UInt8(selectedActionIndex)) ?? DJIWaypointMissionFinishedAction.noAction
        }
        
        if let waypointMission = self.waypointMission {
            self.missionOperator()?.load(waypointMission)
            
            self.missionOperator()?.addListener(toFinished: self, with: DispatchQueue.main, andBlock: { [weak self] (error: Error?) in
                if let error = error {
                    self?.showAlertViewWith(title: "Mission Execution Failed", message: error.localizedDescription)
                } else {
                    self?.showAlertViewWith(title: "Mission Execution Finished", message: nil)
                }
            })
        }
        
        self.missionOperator()?.uploadMission(completion: { (error:Error?) in
            if let error = error {
                let uploadErrorString = "Upload Mission failed:\( error.localizedDescription)"
                showAlertWith(uploadErrorString)
            } else {
                showAlertWith("Upload Mission Finished")
            }
        })
    }
    
    //MARK: - DJIGSButtonViewController Delegate Methods
    func stopBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.stopMission(completion: { (error:Error?) in
            if let error = error {
                let failedMessage = "Stop Mission Failed: \(error.localizedDescription)"
                showAlertWith(failedMessage)
            } else {
                showAlertWith("Stop Mission Finished")
            }
        })
    }
    
    func clearBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.mapController?.cleanAllPoints(with: self.mapView)
    }
    
    func focusMapBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.focusMap()
    }
    
    func startBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.startMission(completion: { (error:Error?) in
            if let error = error {
                showAlertWith("Start Mission Failed: \(error.localizedDescription)")
            } else {
                showAlertWith("Mission Started")
            }
        })
    }
    
    func add(button: UIButton, actionIn gsBtnVC: GSButtonViewController) {
        if self.isEditingPoints {
            self.isEditingPoints = false
            button.setTitle("Add", for: UIControl.State.normal)
        } else {
            self.isEditingPoints = true
            button.setTitle("Finished", for: UIControl.State.normal)
        }
    }
    
    func configBtnActionIn(gsBtnVC: GSButtonViewController) {
        guard let wayPoints = self.mapController?.editPoints else {
            showAlertWith("No waypoints")
            return
        }
        if wayPoints.count < 2 {
            showAlertWith("Not enough waypoints for mission")
            return
        }
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 1.0
        }

        self.waypointMission?.removeAllWaypoints()
        
        self.waypointMission = self.waypointMission ?? DJIMutableWaypointMission()
        
        for location in wayPoints {
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                self.waypointMission?.add(DJIWaypoint(coordinate: location.coordinate))
            }
        }
    }
    
    func switchTo(mode: GSViewMode, inGSBtnVC: GSButtonViewController) {
        if mode == GSViewMode.edit {
            self.focusMap()
        }
    }

    //MARK:  - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last?.coordinate
    }
    
    //MARK:  MKMapViewDelegate Method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKPointAnnotation.self) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin_Annotation")
            pinView.pinTintColor = UIColor.purple
            return pinView
        } else if annotation.isKind(of: AircraftAnnotation.self) {
            let annotationView = AircraftAnnotationView(annotation: annotation, reuseIdentifier: "Aircraft_Annotation")
            (annotation as? AircraftAnnotation)?.annotationView = annotationView
            return annotationView
        }
        return nil
    }

    //MARK:  DJIFlightControllerDelegate
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        self.droneLocation = state.aircraftLocation?.coordinate
        self.modeLabel.text = state.flightModeString
        self.gpsLabel.text = String(state.satelliteCount)
        self.vsLabel.text = String(format: "%0.1f M/S", state.velocityZ)
        self.hsLabel.text = String(format: "%0.1f M/S", sqrt(pow(state.velocityX,2) + pow(state.velocityY,2)))
        self.altitudeLabel.text = String(format: "%0.1f M", state.altitude)
        
        if let droneLocation = droneLocation {
            self.mapController?.updateAircraft(location: droneLocation, with: self.mapView)
        }
        let radianYaw = state.attitude.yaw.degreesToRadians
        self.mapController?.updateAircraftHeading(heading: Float(radianYaw))
    }

    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("unused: didUpdateDatabaseDownloadProgress")
    }
    
}
