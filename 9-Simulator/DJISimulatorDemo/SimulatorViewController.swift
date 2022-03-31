//
//  SimulatorViewController.swift
//  DJISimulatorDemo
//
//  Created by Samuel Scherer on 5/1/21.
//  Copyright © 2021 RIIS. All rights reserved.

/**
 *  This file demonstrates how to use the advanced set of methods in DJIFlightController to control the aircraft and how to start the simulator.
 *
 *  Through DJIFlightController, user can make the aircraft enter the virtual stick mode. In this mode, SDK gives the flexibility for user to control the aircraft just like controlling it using the virtual stick. There are different combinations to control the aircraft in the
 *  virtual stick mode. In this sample, we will control the horizontal movement by velocity. For more information about the virtual stick, please refer to the Flight Controller guide page on https://developer.dji.com/mobile-sdk/documentation/introduction/component-guide-flightController.html.
 *
 *  Through the simulator object in DJIFlightController, user can test the flight controller interfaces and Mission Manager without PC. In this sample, we will start/stop the simulator and display the aircraft's state during the simulation.
 *
 */

import Foundation
import UIKit
import DJISDK

class SimulatorViewController : UIViewController, DJISimulatorDelegate {

    @IBOutlet weak var virtualStickLeft: VirtualStickView!
    @IBOutlet weak var virtualStickRight: VirtualStickView!
    
    @IBOutlet weak var simulatorButton: UIButton!
    @IBOutlet weak var simulatorStateLabel: UILabel!

    var isSimulatorOn = false
    var mXVelocity : Float = 0.0
    var mYVelocity : Float = 0.0
    var mYaw : Float = 0.0
    var mThrottle : Float = 0.0

    //MARK: - Inherited Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "DJISimulator Demo"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onStickChangedWith(notification:)),
                                               name: NSNotification.Name("StickChanged"),
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let flightController = fetchFlightController(), let simulator = flightController.simulator {
            self.isSimulatorOn = simulator.isSimulatorActive
            self.updateSimulatorUI()
            
            simulator.addObserver(self, forKeyPath: "isSimulatorActive", options: NSKeyValueObservingOptions.new, context: nil)
            simulator.delegate = self
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let flightController = fetchFlightController(), let simulator = flightController.simulator {
            simulator.removeObserver(self, forKeyPath: "isSimulatorActive")
            simulator.delegate = nil
        }
    }

    //MARK: - Custom Methods
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let change = change, keyPath == "isSimulatorActive" {
            self.isSimulatorOn = change[NSKeyValueChangeKey.newKey] as? Bool ?? false
            self.updateSimulatorUI()
        }
    }

    func updateSimulatorUI() {
        if !self.isSimulatorOn {
            self.simulatorButton.setTitle("Start Simulator", for: UIControl.State.normal)
            self.simulatorStateLabel.isHidden = true
        } else {
            self.simulatorButton.setTitle("Stop Simulator", for: UIControl.State.normal)
        }
    }
    
    @IBAction func onEnterVirtualStickControlButtonClicked(_ sender: Any) {
        if let flightController = fetchFlightController() {
            flightController.yawControlMode = .angularVelocity
            flightController.rollPitchControlMode = .velocity

            flightController.setVirtualStickModeEnabled(true) { (error:Error?) in
                if let error = error {
                    showAlertWith("Enter Virtual Stick Mode: \(error.localizedDescription)")
                } else {
                    showAlertWith("Enter Virtual Stick Mode: Succeeded")
                }
            }
        } else {
            showAlertWith("Component does not exist.")
        }
    }
    
    @IBAction func onExitVirtualStickControlButtonClicked(_ sender: Any) {
        if let flightController = fetchFlightController() {
            flightController.setVirtualStickModeEnabled(false) { (error:Error?) in
                if let error = error {
                    showAlertWith("Exit Virtual Stick Mode: \(error.localizedDescription)")
                } else {
                    showAlertWith("Exit Virtual Stick Mode:Succeeded")
                }
            }
        } else {
            showAlertWith("Component does not exist.")
        }
    }
    
    @IBAction func onSimulatorButtonClicked(_ sender: Any) {
        guard let flightController = self.verboseFetchFlightController() else { return }
        guard let simulator = flightController.simulator else {
            print("Failed to fetch simulator")
            return
        }
        if !self.isSimulatorOn {
            // The initial aircraft's position in the simulator.
            let location = CLLocationCoordinate2DMake(22, 113)
            simulator.start(withLocation: location, updateFrequency: 20, gpsSatellitesNumber: 10) { (error:Error?) in
                if let error = error {
                    showAlertWith("Start simulator error: \(error.localizedDescription)")
                } else {
                    showAlertWith("Start simulator succeeded.")
                }
            }
        } else {
            simulator.stop() { (error:Error?) in
                if let error = error {
                    showAlertWith("Stop simulator error: \(error.localizedDescription)")
                } else {
                    showAlertWith("Stop simulator succeeded.")
                }
            }
        }
    }

    @IBAction func onTakeoffButtonClicked(_ sender: Any) {
        self.verboseFetchFlightController()?.startTakeoff { (error:Error?) in
            if let error = error {
                showAlertWith("Takeoff \(error.localizedDescription)")

            } else {
                showAlertWith("Takeoff Success.")
            }
        }
    }

    @IBAction func onLandButtonClicked(_ sender: Any) {
        self.verboseFetchFlightController()?.startLanding { (error:Error?) in
            if let error = error {
                showAlertWith("Landing \(error.localizedDescription)")
            } else {
                showAlertWith("Landing Success.")
            }
        }
    }
    
    func verboseFetchFlightController() -> DJIFlightController? {
        guard let flightController = fetchFlightController() else {
            showAlertWith("Failed to fetch flightController")
            return nil
        }
        return flightController
    }

    @objc func onStickChangedWith(notification:NSNotification) {
        let userInfoDictionary = notification.userInfo
        guard let directionValue = userInfoDictionary?["dir"] as? NSValue else {
            print("Failed to get directionValue from stick changed notification")
            return
        }
        let directionPoint = directionValue.cgPointValue
        if let virtualStick = notification.object as? VirtualStickView {
            if virtualStick === self.virtualStickLeft {
                self.set(throttle: Float(directionPoint.y), yaw: Float(directionPoint.x))
            } else {
                self.set(xVelocity: Float(directionPoint.x), yVelocity: Float(directionPoint.y))
            }
        }
    }

    func set(throttle:Float, yaw:Float) {
        self.mThrottle = throttle * 2
        self.mYaw = yaw * 30
        self.updateVirtualStick()
    }
    
    func set(xVelocity:Float, yVelocity:Float) {
        self.mXVelocity = xVelocity * 10.0
        self.mYVelocity = yVelocity * 10.0
        self.updateVirtualStick()
    }

    func updateVirtualStick() {
        let controlData = DJIVirtualStickFlightControlData(pitch: self.mYVelocity,
                                                           roll: self.mXVelocity,
                                                           yaw: self.mYaw,
                                                           verticalThrottle: self.mThrottle)
        if let flightController = fetchFlightController(), let _ = flightController.simulator {
            flightController.send(controlData, withCompletion: nil)
        }
    }

    //MARK: - DJI Simulator Delegate
    func simulator(_ simulator: DJISimulator, didUpdate state: DJISimulatorState) {
        self.simulatorStateLabel.isHidden = false
        self.simulatorStateLabel.text = String(format:"Yaw: %0.2f Pitch: %0.2f, Roll: %0.2f\n PosX: %0.2f PosY: %0.2f PosZ: %0.2f", state.yaw, state.pitch, state.roll, state.positionX, state.positionY, state.positionZ)
    }
}
