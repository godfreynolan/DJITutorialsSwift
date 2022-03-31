//
//  FPVViewController.swift
//  BridgeAppDemo
//
//  Created by Samuel Scherer on 4/16/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import UIKit
import DJISDK
import DJIWidget

class FPVViewController: UIViewController, DJICameraDelegate, DJISDKManagerDelegate, DJIVideoFeedListener {
    
    @IBOutlet var recordTimeLabel: UILabel!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var workModeControl: UISegmentedControl!
    @IBOutlet var fpvView: UIView!
    
    var isRecording = false
    
    fileprivate let enableDebugMode = true
    fileprivate let bridgeIP = "192.168.128.169"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DJIVideoPreviewer.instance().setView(self.fpvView)
        DJISDKManager.registerApp(with: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DJIVideoPreviewer.instance().setView(nil)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.recordTimeLabel.isHidden = true
    }
    
    func showAlertViewWithTitle(title: String, withMessage message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func format(seconds: UInt) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return(dateFormatter.string(from: date))
    }
    
    func fetchCamera() -> DJICamera? {
        guard let product = DJISDKManager.product() else {
            return nil
        }
        if let aircraft = product as? DJIAircraft {
            return aircraft.camera
        }
        if let handheld = product as? DJIHandheld {
            return handheld.camera
        }
        return nil
    }
    
    func resetVideoPreview() {
        DJIVideoPreviewer.instance().unSetView()
        let product = DJISDKManager.product();
        
        //Use "SecondaryVideoFeed" if the DJI Product is A3, N3, Matrice 600, or Matrice 600 Pro, otherwise, use "primaryVideoFeed".
        if ((product?.model == DJIAircraftModelNameA3)
            || (product?.model == DJIAircraftModelNameN3)
            || (product?.model == DJIAircraftModelNameMatrice600)
            || (product?.model == DJIAircraftModelNameMatrice600Pro)) {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.remove(self)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        }
    }

    // MARK: DJISDKManagerDelegate Methods
    func productConnected(_ product: DJIBaseProduct?) {
        if let camera = fetchCamera() {
            camera.delegate = self
        }
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state, error) in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            }
        }
    }
    
    func appRegisteredWithError(_ error: Error?) {
        var message = "App registration succeeded!"
        if let _ = error {
            message = "App registration failed! Please enter your app key and check the network."
        } else {
            if enableDebugMode {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeIP)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
            DJIVideoPreviewer.instance().start()
        }
        
        self.showAlertViewWithTitle(title:"Register App", withMessage: message)
    }
    
    // MARK: DJIVideoFeedListener Method
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData rawData: Data) {
        let videoData = rawData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoData.length))
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("Download database : \n%lld/%lld", progress.completedUnitCount, progress.totalUnitCount)
    }
    
    // MARK: DJICameraDelegate Method
    func camera(_ camera: DJICamera, didUpdate cameraState: DJICameraSystemState) {
        self.isRecording = cameraState.isRecording
        self.recordTimeLabel.isHidden = !self.isRecording
        
        self.recordTimeLabel.text = format(seconds: cameraState.currentVideoRecordingTimeInSeconds)
        
        if self.isRecording == true {
            self.recordButton.setTitle("Stop Record", for: .normal)
        } else {
            self.recordButton.setTitle("Start Record", for: .normal)
        }
        
        //Update UISegmented Control's State
        if (cameraState.mode == DJICameraMode.shootPhoto) {
            self.workModeControl.selectedSegmentIndex = 0
        } else {
            self.workModeControl.selectedSegmentIndex = 1
        }
    }
    
    // MARK: IBAction Methods
    @IBAction func captureAction(_ sender: UIButton) {
        guard let camera = fetchCamera() else {
            return
        }
        
        camera.setMode(DJICameraMode.shootPhoto, withCompletion: {(error: Error?) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
                camera.startShootPhoto(completion: { (error) in
                    if let error = error {
                        print("Shoot Photo Error: \(error.localizedDescription)")
                    }
                })
            }
        })
    }
    
    @IBAction func recordAction(_ sender: UIButton) {
        guard let camera = fetchCamera() else { return }
        
        if (self.isRecording) {
            camera.stopRecordVideo(completion: { (error: Error?) in
                if let error = error {
                    print("Stop Record Video Error: \(error.localizedDescription)")
                }
            })
        } else {
            camera.startRecordVideo(completion: { (error: Error?) in
                if let error = error {
                    print("Start Record Video Error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    @IBAction func workModeSegmentChange(_ sender: UISegmentedControl) {
        guard let camera = fetchCamera() else { return }
        
       if (sender.selectedSegmentIndex == 0) {
            camera.setMode(DJICameraMode.shootPhoto,  withCompletion: { (error) in
                if let error = error {
                    print("Set ShootPhoto Mode Error: \(error.localizedDescription)")
                }
            })
            
        } else if (sender.selectedSegmentIndex == 1) {
            camera.setMode(DJICameraMode.recordVideo,  withCompletion: { (error) in
                if let error = error {
                    print("Set RecordVideo Mode Error: \(error.localizedDescription)")
                }
            })
        }
    }

}
