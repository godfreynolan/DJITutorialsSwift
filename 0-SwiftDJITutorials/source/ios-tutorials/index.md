---
title: Creating a Camera Application (Swift)
version: v4.14
date: 2021-06-08
github: https://github.com/DJI-Mobile-SDK-Tutorials/iOS-FPVDemo-Swift
keywords: [iOS FPVDemo, capture, shoot photo, take photo, record video, basic tutorial, Swift]
---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

This tutorial is designed for you to gain a basic understanding of the DJI Mobile SDK. It will implement the FPV view and two basic camera functionalities: **Take Photo** and **Record video**.

You can download the tutorial's final sample project from this [Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-FPVDemo-Swift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-FPVDemo) for an Objective C version. 

We used a Mavic Pro to make this demo.

## Importing and Activating the SDK

Now, let's create a new project in Xcode, choose **Single View Application** template for your project and press "Next", then enter "FPVDemo" in the **Product Name** field and keep the other default settings.

Once the project is created, let's delete the "ViewController.swift" file created by Xcode by default. Create a new ViewController named "FPVViewController".

Now, let's install the **DJISDK.framework** in the Xcode project using Cocoapods and implement the SDK activation process in the "FPVViewController.swift" file. If you are not familiar with the process of installing and activating DJI SDK, please check the Github source code and this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#Xcode-Project-Integration) for details.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Implementing the First Person View

### Importing the DJIWidget

  **1**. We use the **FFMPEG** decoding library (found at <a href="http://ffmpeg.org" target="_blank">http://ffmpeg.org</a>) to do software video decoding here. For the hardware video decoding, we provide a **H264VTDecode** decoding library. You can find them in the `DJIWidget/DJIWidget/VideoPreviewer` folder, which you can download it from <a href="https://github.com/dji-sdk/DJIWidget/tree/master/DJIWidget/VideoPreviewer" target="_blank">DJIWidget Github Repository</a>.

  DJIWidget is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following lines to your Podfile:

  ```
  use_frameworks!
  pod 'DJIWidget', '~> 1.6.4'
  ```

Next, run the following command in the path of the project's root folder:

~~~
pod install
~~~

If you installed it successfully, you should get a message similar to the following:

~~~
Analyzing dependencies
Downloading dependencies
Installing DJI-SDK-iOS (4.14)
Installing DJIWidget (1.6.4)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `ImportSDKDemo.xcworkspace` for this project from now on.
Pod installation complete! There are 2 dependencies from the Podfile and 2 total pods installed.
~~~

### Working on the FPVViewController

 **1**. Let's open the `FPVDemo.xcworkspace` file in Xcode and open the Main.storyboard, then add a new View Controller and set its **Class** as **FPVViewController**:

  ![rootController](../images/tutorials-and-samples/iOS/FPVDemo/rootController.png)

Add a UIView inside the View Controller. Then, add two UIButtons and one UISegmentedControl at the bottom of the View Controller as shown below:

  ![Storyboard](../images/tutorials-and-samples/iOS/FPVDemo/Storyboard.png)

Replace "ViewController.swift" with a new file called "FPVViewController.swift" and import **DJISDK** and **DJIWidget**. Next implement four delegate protocols and set the IBOutlets and IBActions for the UI we just created in Main.storyboard as shown below:

~~~Swift
import UIKit
import DJISDK
import DJIWidget

class FPVViewController: UIViewController,  DJIVideoFeedListener, DJISDKManagerDelegate, DJICameraDelegate {

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var workModeSegmentControl: UISegmentedControl!
    @IBOutlet var fpvView: UIView!

    @IBAction func captureAction(_ sender: UIButton) {
        // Implement Later
    }
    
    @IBAction func recordAction(_ sender: UIButton) {
        // Implement Later
    }
    
    @IBAction func workModeSegmentChange(_ sender: UISegmentedControl) {
        // Implement Later
    }
}
~~~

**2.** Furthermore, let's create the `setupVideoPreviewer` and `resetVideoPreviewer` methods as shown below:

~~~Swift
    func setupVideoPreviewer() {
        DJIVideoPreviewer.instance().setView(self.fpvView)
        let product = DJISDKManager.product();
        
        //Use "SecondaryVideoFeed" if the DJI Product is A3, N3, Matrice 600, or Matrice 600 Pro, otherwise, use "primaryVideoFeed".
        if ((product?.model == DJIAircraftModelNameA3)
            || (product?.model == DJIAircraftModelNameN3)
            || (product?.model == DJIAircraftModelNameMatrice600)
            || (product?.model == DJIAircraftModelNameMatrice600Pro)) {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.add(self, with: nil)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        }
        DJIVideoPreviewer.instance().start()
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
~~~

In the `setupVideoPreviewer` method, we set the `fpvView` instance variable as the superview of the `MovieGLView` in the **DJIVideoPreviewer** class. Then get a `DJIBaseProduct` object from the `DJISDKManager` and use its `model` property to display the correct video feed (Some larger drones have a dedicated FPV camera in addition to the primary detachable payload(s)). Lastly, we invoke the `start` method of `DJIVideoPreviewer` instance to start the video decoding.

In the `resetVideoPreview` method, we invoke the `unSetView` method of `DJIVideoPreviewer` instance to remove the `MovieGLView` of the `DJIVideoPreviewer` class from the `fpvPreviewView` instance first. Then also check the current `product`'s model using an if statement.

If the product is **A3**, **N3**, **Matrice 600** or **Matrice 600 Pro**, we invoke the `removeListener:` method of `DJIVideoFeeder` class to remove the `DJICameraViewController` listener from the `secondaryVideoFeed` for video feed, otherwise, we remove the `DJICameraViewController` listener from the `primaryVideoFeed` for video feed.

**3.** Once you finished the above steps, let's implement the `DJISDKManagerDelegate` delegate methods and the `viewWillDisappear` method as shown below:

~~~Swift
    func fetchCamera() -> DJICamera? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.camera
        }
        if let handheld = DJISDKManager.product() as? DJIHandheld {
            return handheld.camera
        }
        return nil
    }

    // MARK: DJISDKManagerDelegate Methods
    func productConnected(_ product: DJIBaseProduct?) {
        
        NSLog("Product Connected")
        if let camera = fetchCamera() {
            camera.delegate = self
        }
        self.setupVideoPreviewer()
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state, error) in
            if let _ = error {
                NSLog("Login failed: %@" + String(describing: error))
            }
        }
    }
    
    func productDisconnected() {
        NSLog("Product Disconnected")

        if let camera = fetchCamera(), let delegate = camera.delegate, delegate.isEqual(self) {
            camera.delegate = nil
        }
        self.resetVideoPreview()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if let camera = fetchCamera(), let delegate = camera.delegate, delegate.isEqual(self) {
            camera.delegate = nil
        }
        
        self.resetVideoPreview()
    }

    func appRegisteredWithError(_ error: Error?) {
        var message = "Register App Successed!"
        if let _ = error {
            message = "Register app failed! Please enter your app key and check the network."
        } else {
            DJISDKManager.startConnectionToProduct()
        }
        
        print("Register App: \(message)")
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        //Unused
    }
~~~

First we create the `- (DJICamera*) fetchCamera` method to fetch the updated DJICamera object. Before we get the return DJICamera object, we need to check if the product object of DJISDKManager is kind of **DJIAircraft** of **DJIHandheld** class. Since the camera component of the aircraft or handheld device may be changed or disconnected, we need to fetch the camera object everytime we want to use it to ensure we get the correct camera object.

Then invoke the `setupVideoPreviewer` method to setup the DJIVideoPreviewer in the `productConnected` delegate method. Lastly, reset the `camera` instance's delegate to nil and invoke the `resetVideoPreview` method to reset the videoPreviewer in the `productDisconnected` and `viewWillDisappear` methods.

**4**. Lastly, let's implement the "DJIVideoFeedListener" and "DJICameraDelegate" delegate methods, as shown below:

~~~Swift

    // MARK: DJIVideoFeedListener Method
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData rawData: Data) {
        let videoData = rawData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoData.length))
    }

    // MARK: DJICameraDelegate Method
    func camera(_ camera: DJICamera, didUpdate cameraState: DJICameraSystemState) {
        self.isRecording = cameraState.isRecording
        
        //Update UISegmented Control's State
        if (cameraState.mode == DJICameraMode.shootPhoto) {
            self.workModeSegmentControl.selectedSegmentIndex = 0
        } else {
            self.workModeSegmentControl.selectedSegmentIndex = 1
        }
    }

~~~

Here, we use the `-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData` method to get the live H264 video feed data and send them to the **DJIVideoPreviewer** to decode.

Moreover, the `-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState` method is used to get the camera state from the camera on your aircraft. It will be invoked frequently, so you can update your user interface or camera settings accordingly here.

 Now we can implement the `changeWorkModeAction` IBAction method as follows:

~~~Swift
    @IBAction func workModeSegmentChange(_ sender: UISegmentedControl) {
        guard let camera = fetchCamera() else {
            return
        }
        
       if (sender.selectedSegmentIndex == 0) {
            camera.setMode(DJICameraMode.shootPhoto,  withCompletion: { (error) in
                if let _ = error {
                    NSLog("Set ShootPhoto Mode Error: " + String(describing: error))
                }
            })
            
        } else if (sender.selectedSegmentIndex == 1) {
            camera.setMode(DJICameraMode.recordVideo,  withCompletion: { (error) in
                if let _ = error {
                    NSLog("Set RecordVideo Mode Error: " + String(describing: error))
                }
            })
        }
    }

~~~

## Connecting to the Aircraft or Handheld Device

Please check this [Connect Mobile Device and Run Application](../application-development-workflow/workflow-run.md#connect-mobile-device-and-run-application) guide to run the application and view the live video stream from your DJI product's camera based on what we've finished of the application so far!

## Enjoying the First Person View

If you can see the live video stream in the application, congratulations! Let's move forward.

Note that you may have to change the camera's mode before the fpv will show.

  ![fpv](../images/tutorials-and-samples/iOS/FPVDemo/fpv.jpg)

## Implementing the Capture function

Let's implement the `captureAction` IBAction method as shown below:

~~~Swift
    @IBAction func captureAction(_ sender: UIButton) {
        guard let camera = fetchCamera() else {
            return
        }
        
        camera.setMode(DJICameraMode.shootPhoto, withCompletion: {(error) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
                camera.startShootPhoto(completion: { (error) in
                    if let _ = error {
                        NSLog("Shoot Photo Error: " + String(describing: error))
                    }
                })
            }
        })
    }
~~~

In the code above, we first invoke the following method of DJICamera to set the camera mode to `DJICameraMode.shootPhoto`:

~~~Swift
- (void)setMode:(DJICameraMode)mode withCompletion:(DJICompletionBlock)completion;
~~~

  Normally, once an operation is finished, the camera still needs some time to finish up all the work. It's safe to delay the next operation after an operation is finished. So let's enqueue the block which may invoke the following method with 1 second delay to shoot a photo:

`- (void)startShootPhotoWithCompletion:(DJICompletionBlock)completion;`

  You can check the shoot photo result in the `DJICompletionBlock`.

  Build and run your project and then try the shoot photo function. If the screen flash after your press the **Capture** button, your capture fuction should work now.

## Implementing the Record function

First, let's go to Main.storyboard and drag a UILabel on top of the screen, set up the Autolayout constraints for it and create an IBOutlet named `recordTimeLabel` in the **FPVViewController.swift** file.

Then add a BOOL variable `isRecording` to **FPVViewController**. Be sure to hide the `recordTimeLabel` and register the app in the `viewDidLoad` method as well.

~~~Swift
    var isRecording!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DJISDKManager.registerApp(with: self)
        recordTimeLabel.isHidden = true
    }
~~~

We can update `isRecording` and `recordTimeLabel`'s text value in the following delegate method:

~~~Swift
    func camera(_ camera: DJICamera, didUpdate cameraState: DJICameraSystemState) {
        self.isRecording = cameraState.isRecording
        self.recordTimeLabel.isHidden = !self.isRecording
        
        self.recordTimeLabel.text = formatSeconds(seconds: cameraState.currentVideoRecordingTimeInSeconds)
        
        if (self.isRecording == true) {
            self.recordButton.setTitle("Stop Record", for: .normal)
        } else {
            self.recordButton.setTitle("Start Record", for: .normal)
        }
        
        //Update UISegmented Control's State
        if (cameraState.mode == DJICameraMode.shootPhoto) {
            self.workModeSegmentControl.selectedSegmentIndex = 0
        } else {
            self.workModeSegmentControl.selectedSegmentIndex = 1
        }
    }
~~~

   Because the text value of `currentRecordingTime` is counted in seconds, so we need to convert it to "mm:ss" format like this:

~~~Swift
    func formatSeconds(seconds: UInt) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return(dateFormatter.string(from: date))
    }
~~~

   Next, add the following code to the `recordAction` IBAction method as follows:

~~~Swift
    @IBAction func recordAction(_ sender: UIButton) {
        guard let camera = fetchCamera() else {
            return
        }
        
        if (self.isRecording) {
            camera.stopRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Stop Record Video Error: " + String(describing: error))
                }
            })
        } else {
            camera.startRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Start Record Video Error: " + String(describing: error))
                }
            })
        }
    }
~~~

  In the code above, we implement the `startRecordVideoWithCompletion` and `stopRecordVideoWithCompletion` methods of the **DJICamera** class based on the `isRecording` property value. And show an alertView when an error occurs.

  Now, let's build and run the project and check the functions. You can try to play with the **Record** and **Switch Camera WorkMode** functions, if everything goes well, you should see the screenshot like this:

  ![Screenshot](../images/tutorials-and-samples/iOS/FPVDemo/record_screenshot.jpg)

  Congratulations! Your Aerial FPV iOS app is complete, you can now use this app to control the camera of your Mavic Pro.

### Summary

   In this tutorial, you’ve learned how to use DJI Mobile SDK to show the FPV View from the aircraft's camera, take photos and record video. These are the most basic and common features in a typical drone mobile app: **Capture** and **Record**. However, if you want to create a drone app which is more fancy, you still have a long way to go. More advanced features can be implemented such as previewing the photos and videos on the SD Card, showing the aircraft's OSD data and more. Hope you enjoyed this tutorial!
