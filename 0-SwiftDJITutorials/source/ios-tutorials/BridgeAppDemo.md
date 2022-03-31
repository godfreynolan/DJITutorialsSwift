---
title: DJI Bridge App Tutorial (Swift)
version: v4.14
date: 5-25-2021
github: https://github.com/godfreynolan/BridgeDemoSwift
keywords: [DJI Bridge App demo, remote debugging, Swift]
---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

This tutorial is designed to give you a better understanding of the DJI Bridge App. It will teach you how to use it for app debugging by implementing the live video view and two basic camera functionalities: "Take Photo" and "Record video".

You can download and install the DJI SDK Bridge App from <a href="https://itunes.apple.com/us/app/sdk-bridge/id1263583917?ls=1&mt=8" target="_blank">App Store</a> to your mobile device.

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/BridgeDemoSwift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/DJIBridgeAppDemo) for an Objective C version. 

## Introduction

The design of the DJI Bridge App is simple. It's a universal app that supports both iPhone and iPad. You can use it to debug app for Phantom 3 Professional, Phantom 3 Advanced, Inspire 1, M100 and other products using USB/MFI connection between RC and your app.

### Workflow

![workflow](../images/tutorials-and-samples/iOS/BridgeAppDemo/workFlow.png)

As you see above, the Bridge App and the iOS Device or Xcode Simulator should work in the same local network using TCP service to communicate. You can connect them to the same WiFi network or connect to a local wireless connection created on your Mac too.

### Signal Light

At the top of the screen, there are two signal lights, which represent the connection between the bridge app and the remote controller or your application. When the bridge app connects to the remote controller successfully, the **RC light** will turn green. Similarly, when the bridge app connects to your app successfully, the **App Light** will turn green too.

![signalLight](../images/tutorials-and-samples/iOS/BridgeAppDemo/toolScreenshot.png)

### TCP Connection

The bridge app uses TCP sockets to communicate with your app. It uses **Debug Id** to distinguish between different bridge apps running on different mobile devices.

TCP connections are stable and support secure networks, which means your local network has firewall. The debug ID will change for different IP addresses.

Now try to open the bridge app, and connect your mobile device to the remote controller using a usb cable. You should see the RC Light turn green!

> **Note**:
>
> If you connect the bridge app to the RC and the RC light is still red, you may need to restart the app and try again. It should work.
>

## Importing the DJI SDK

Now, let's create a new project in Xcode, choose **Single View Application** template for your project and press "Next", then enter "BridgeAppDemo" in the **Product Name** field and keep the other default settings.

Once the project is created, let's import the **DJISDK.framework**. If you are not familiar with the process of importing and activating DJI SDK, see this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#Xcode-Project-Integration) for details.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft is not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Importing the DJIWidget

 You can check this tutorial [Creating a Camera Application](./index.md#importing-the-djiwidget) to learn how to download and import the **DJIWidget** into your Xcode project.

## Implement the Live Video View

  **1**. In the Main.storyboard, add a new View Controller and call it **FPVViewController**. Set **FPVViewController** as the root View Controller for the new View Controller you just added in Main.storyboard:

  ![rootController](../images/tutorials-and-samples/iOS/BridgeAppDemo/cameraViewController.png)

  Add a UIView inside the View Controller and set it as an IBOutlet called "**fpvView**". Then, add two UIButtons and one UISegmentedControl at the bottom of the View Control and set their IBOutlets and IBActions, as shown below:

  ![Storyboard](../images/tutorials-and-samples/iOS/BridgeAppDemo/mainStoryboard.png)

  Go to **FPVViewController.swift** file and import the **DJISDK** and **DJIVideoPreviewer** modules. Then implement several delegate protocols as shown below:

~~~Swift
import DJISDK
import DJIWidget

class FPVViewController: UIViewController, DJICameraDelegate, DJISDKManagerDelegate, DJIVideoFeedListener {
    
    @IBOutlet var recordTimeLabel: UILabel!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var workModeControl: UISegmentedControl!
    @IBOutlet var fpvView: UIView!
~~~

  **2**. Implement the showAlertViewWithTitle method which will be used to display status messages.
  
~~~Swift
    func showAlertViewWithTitle(title: String, withMessage message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
~~~

  **3**. Implement the DJISDKManagerDelegate method as shown below:

~~~Swift

    func fetchCamera() -> DJICamera? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.camera
        }
        return (DJISDKManager.product() as? DJIHandheld)?.camera
    }
    
    // MARK: DJISDKManagerDelegate Methods
    func productConnected(_ product: DJIBaseProduct?) {
        if let camera = fetchCamera() {
            camera.delegate = self
        }

        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state, error) in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            }
        }
    }

~~~

The delegate method above is called when SDK detects a product. Then invoke the `fetchCamera` method to fetch the updated DJICamera object.

Next, in the viewWillAppear method, set "fpvPreviewView" instance as a View of DJIVideoPreviewer to show the Video Stream, register the app with your DJI app key and reset it to nil in the viewWillDisappear method:

> Note: If you don't know how to apply as a DJI developer and get the App Key, please refer to [Get Started](../quick-start/index.md).

~~~Swift
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
~~~

  Lastly, implement the `DJIVideoFeedListener` delgate method, as shown below:

~~~Swift
    // MARK: DJIVideoFeedListener Method
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData rawData: Data) {
        let videoData = rawData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoData.length))
    }
~~~

  The `videoFeed:didUpdateVideoData:` method is used to send the video stream to **DJIVideoPreviewer** to decode.

## Enter Debug Mode

**1**. Let's implement the DJISDKManagerDelegate method as shown below:

~~~Swift
    func appRegisteredWithError(_ error: Error?) {
        var message = "App registration succeeded!"
        if let _ = error {
            message = "App registration failed! Please enter your app key and check the network."
        } else {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: "192.168.128.169")
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
            DJIVideoPreviewer.instance().start()
        }
        
        self.showAlertViewWithTitle(title:"Register App", withMessage: message)
    }
~~~

The delegate method above gets called when the app is registered. If the registration is successful, we can call the `enableBridgeMode(withBridgeAppIP:)` class method of **DJISDKManager** to enter debug mode of the SDK by passing the **bridgeAppIP** parameter, which you can get from **the Bridge App**. Then add the listener for the `primaryVideoFeed` of `videoFeeder` in **DJISDKManager** and call the start method of the DJIVideoPreviewer class to start video decoding.

**2**. Build and Run the project in Xcode. If everything is OK, you will see a "Register App Successed!" alert once the application loads.

  ![Screenshot](../images/tutorials-and-samples/iOS/BridgeAppDemo/Screenshot.png)

## Debug Live Video View on iOS Simulator

After you finish the steps above, you can now connect the DJI Bridge app to your aircraft to try debugging the Live Video View on your **iOS Simulator**. Here are the guidelines:

 In order to connect to DJI Inspire 1, Phantom 3 Professional, Phantom 3 Advanced or M100:

  **1**. First, turn on your remote controller and connect it to the mobile device which is running the DJIBridge app.

  **2**. Trust the device if an alert asking “Do you trust this device” comes up.

  **3**. Make sure your mobile device connect to the same WiFi network to your Mac.

  **4**. Then, turn on the power of the aircraft.

  **5**. Now build and run the project in Xcode, wait for a few seconds, you will be able to view the live video stream from your aircraft's camera on your iOS simulator now!

Here are the screenshots of the bridge app and iOS simulator if everthing goes well:

  ![TCP](../images/tutorials-and-samples/iOS/BridgeAppDemo/workMode.png)

![simulator](../images/tutorials-and-samples/iOS/BridgeAppDemo/simulator.png)

> **Note:**
>
> **1.** If you cannot see the live video, please check the log message in Xcode's console and try to move your aircraft around the RC. The live video should show up.
>
> **2.** You may notice that the live video has mosaics. It's due to the delayed transmission and the software decoding quality of iOS Simulator.

Congratulations! By using the bridge app, you can now debug your app with all the Xcode features, like adding **Breakpoints** in your code, using **Instruments** to profile the app, etc. Let's move forward.

## Implement the Capture and Record function

Create a Bool property variable named **isRecording** in FPVViewController.swift and implement the DJICameraDelegate method as shown below:

~~~Swift

    var isRecording = false

    func format(seconds: UInt) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return(dateFormatter.string(from: date))
    }

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
~~~

The delegate method above is used to get the camera state from the camera on your aircraft. It will be called frequently, so you can update your user interface or camera settings accordingly here. We update the **recordTimeLabel**'s text with latest recording time. Then, update the recordButton's title with the correct state. Lastly, update the workModeControl's selected index with **cameraState**'s `mode` value.

Once you finish it, let's implement the **captureAction**, **recordAction** and **changeWorkModeAction** IBAction methods, and show an alertView when error occurs as shown below:

~~~Swift
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
~~~

   Now, we can build and run the project. You can try to play with the **Record** and **Switch Camera WorkMode** functions, if everything is going well, you should see the simulator screenshot like this:

   ![Screenshot](../images/tutorials-and-samples/iOS/BridgeAppDemo/record_screenshot.png)

## Debug on Actual iOS Device

   Currently, we are running the app on **iOS Simulator**. Although the iOS Simulator is extremely useful during app development, when you want to ensure the required functionality and performance of an application, such as App Memory Usage, Hardware usage like Accelerometer, Gyroscope, etc, testing on an actual device is still required. For more difference between iOS Simulator and actual iOS device, please refer to <a href="http://bluetubeinc.com/blog/2014/11/ios-simulator-vs-device-testing" target="_blank"> iOS Simulator Vs. Actual Device Testing </a>.

   The good thing is DJI Bridge app supports actual iOS device debugging. You can find another iOS device, like an iPhone 6, iPad air 2, etc, and connect it to your Mac. Then build and run the project on it. It should work just like the iOS Simulator.

## Debug on DJI Product requires WiFI Connection

   For the Phantom 3 Standard and OSMO, you cannot use DJI Bridge App to debug your application because they use WiFi to connect between your application and the remote controller or the handheld device.

   You can run the app without bridge mode too. Let's add properties named enableDebugMode and bridgeIP to FPVViewController as shown below:

~~~Swift
    fileprivate let enableDebugMode = true
    fileprivate let bridgeIP = "192.168.128.169"
~~~

  Then go to ` func appRegisteredWithError(_ error: Error?) ` method and replace the code with the following:

~~~Swift
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
~~~

   As the code shown above, if you don't want to use debug mode of the SDK with DJI Bridge app, you can call `+ (BOOL)startConnectionToProduct;` class method of DJISDKManager instead once the app registration is successful.

   Finally, connect to DJI Product. Build and run the application on your Mac, if everthing goes well, you should see the following screenshot for iOS Simulator:

   ![Screenshot](../images/tutorials-and-samples/iOS/BridgeAppDemo/osmoScreenshot.png)

>**Notes:**
>
>**1.** If it's the first time to run the application, which isn't registered before, you may need to connect your Mac or iOS device's WiFi to the internet and build and run the app for registration. Next time, you can connect their WiFi back to the DJI Product to debug without problems.
>
>**2.** You may notice the video is clear without mosaic. This is because the iOS device uses hardware decoding for live video, which is better than software decoding.
>

### Summary

   Congratulations! You've learned how to use DJI Bridge App to debug your application using DJI Mobile SDK. Also, for better understanding, the tutorial shows you how to show the live video view from the DJI Product's camera and control the camera to take photo and record video too.

   With DJI Bridge App, you can develop your application with DJI Mobile SDK more efficiently. Hope you enjoy this tutorial, Thanks!
