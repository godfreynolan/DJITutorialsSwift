---
title: Getting Started with DJI UXSDK
version: v4.14
date: 5-25-2021
github: https://github.com/godfreynolan/UXSDK-Demo-Swift
keywords: [UXSDK, Default Layout, playback, preview photos and videos, download photos and videos, delete photos and videos]

---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

In this tutorial, you will learn how to use DJI iOS UXSDK and DJI iOS Mobile SDK to easily create a fully functioning mini-DJI Go app, with standard DJI Go UIs and functionalities. By the end of this tutorial you will have an app that you can use to show the camera FPV view, check aircraft status, shoot photos, record videos and so on.

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/UXSDK-Demo-Swift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-UXSDKDemo) for an Objective C version. 

We used Mavic Pro and iPad Air as an example to make this demo. Let's get started!

## Introduction

DJI UXSDK is a visual framework consisting of UI Elements. It helps you simplify the creation of DJI Mobile SDK based apps in iOS. With a similar design to DJI Go, DJI UXSDK allow you to create consistent UX between your apps and DJI apps.

In addition, with the ease of use that the UXSDK provides, it frees developers to focus more on business and application logic.

As DJI UXSDK is built on top of DJI Mobile SDK and DJIWidget, you need to use them together in your application development.

For a more in depth understanding of the DJI UXSDK, please go to the [UX SDK Introduction](../introduction/ux_sdk_introduction.md).

## Importing DJI SDK, UXSDK and DJIWidget with CocoaPods

Now, let's create a new project in Xcode, select the iOS platform tab, then choose the normal **App** template, press "Next" and enter "UXSDKDemo" in the **Product Name** field. Make sure interface is set to Storyboard and Lanugage is set to Swift (keep the other default settings).

Once the project is created, let's download and import the **DJISDK.framework** and **DJIUXSDK.framework** using CocoaPods. In Finder, navigate to the root folder of the project and create a **Podfile**. To learn more about Cocoapods, please check [this guide](https://guides.cocoapods.org/using/getting-started.html#getting-started).

Replace the content of the **Podfile** with the following:

~~~
platform :ios, '10.0'

target 'UXSDKDemo' do
  use_frameworks!
  pod 'DJI-SDK-iOS', '~> 4.14'
  pod 'DJI-UXSDK-iOS', '~> 4.14'
  pod 'DJIWidget', '~> 1.6.4'
  pod 'DJIFlySafeDatabaseResource', '~> 01.00.01.18'
  pod 'iOS-Color-Picker'
end

~~~

Next, run the following command in the path of the project's root folder:

~~~
pod install
~~~

If you installed it successfully, you should get a message similar to the following:

~~~
Analyzing dependencies
Downloading dependencies
Installing DJI-SDK-iOS (4.12)
Installing DJI-UXSDK-iOS (4.12)
Installing DJIWidget (1.6.2)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `UXSDKDemo.xcworkspace` for this project from now on.
Sending stats
Pod installation complete! There are 2 dependencies from the Podfile and 2 total pods installed.
~~~

> **Note**: If you saw "Unable to satisfy the following requirements" issue during pod install, please run the following commands to update your pod repo and install the pod again:
>
~~~
 pod repo update
 pod install
~~~

## Configure Build Settings

 You can also check our previous tutorial [Integrate SDK into Application](../application-development-workflow/workflow-integrate.md#configure-build-settings) to learn how to configure the necessary Xcode project build settings.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile applications used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft will not bind (if required) or if a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled and flight will be limited to a zone of 100m diameter and 30m height to ensure that the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Implementing the DUXDefaultLayoutViewcontroller

After you finish the steps above, let's implement standard DJI Go functionalities, by just going through a few simple steps.

#### Working on the Storyboard

Open the `UXSDKDemo.xcworkspace` file in Xcode and delete the **ViewController** class that Xcode created by default. Then create a new file, pick the "Cocoa Touch Class" template, choose **UIViewController** as its subclass and name it "DefaultLayoutViewController".

Once you finish the steps above, let's open the "Main.storyboard" and set the existing View Controller's "Class" value to **DefaultLayoutViewController** as shown below:

![](../images/tutorials-and-samples/iOS/UXSDKDemo/defaultLayoutViewController.png)

For more details on the storyboard settings, please check the tutorial's Github Sample Project.

#### Subclassing DUXDefaultLayoutViewController

Next, let's remove ViewController.swift, create a file called **DefaultLayoutViewController.swift**, import the **DJIUXSDK** module, change the subclass to `DUXDefaultLayoutViewcontroller` and conform DefaultLayoutViewController to DJISDKManagerDelegate as shown below:

~~~Swift
import DJIUXSDK

class DefaultLayoutViewController: DUXDefaultLayoutViewController, DJISDKManagerDelegate {

}
~~~

The **DUXDefaultLayoutViewcontroller** is a viewController designed around 5 child view controllers, and it's a fully functioning mini-DJI Go. It uses all the elements of the UXSDK to give you the foundation of your app. It includes status bar, take off, go home, camera actions buttons and camera settings, OSD dashboard, FPV live vide feed view, etc. The default layout is easily configured and adjusted.

## Application Registration

Now, add the following code to **DefaultLayoutViewController** to handle application registration:

~~~Swift
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Please enter your App Key in the info.plist file.
        DJISDKManager.registerApp(with: self)
    }

    open func connectToProduct() {
        print("Connecting to product...")
        if useDebugMode {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeIP)
        } else {
            let startedResult = DJISDKManager.startConnectionToProduct()
            
            if startedResult {
                print("Connecting to product started successfully!")
            } else {
                print("Connecting to product failed to start!")
            }
        }
    }

    //MARK: - DJISDKManagerDelegate
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            self.showAlertViewWith(message:"Error Registering App: \(error.localizedDescription)")
            return
        }
        self.showAlertViewWith(message: "Registration Success")
        self.connectToProduct()
    }

    func showAlertViewWith(message: String) {
        let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        //unused
    }
~~~

In the code above, we have implemented the following logic:

1. In the `viewDidLoad` method, we invoked the `registerAppWithDelegate` method of `DJISDKManager` to make the application connect to a DJI Server through the internet. Doing this verified the App Key and set the `DJISDKManagerDelegate` to `DefaultLayoutViewController`. For more details on registering the application, please check this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#register-application).

2. We also implemented the delegate method `appRegisteredWithError(_ error: Error?)` of **DJISDKManagerDelegate** to connect the application to a DJI Product by invoking the `startConnectionToProduct` method of **DJISDKManager** when registered successfully. Also showed an alert view displaying the result of the registration attempt.

3. Next we added a method for displaying the registration result in an alert.

4. Finally we implemented didUpdateDatabaseDownloadProgress(_ progress:) in order to conform to DJISDKManagerDelegate but don't actually use it for anything. 

## Bug fix for UXSDK 4.14

Due to a bug in UXSDK 4.14 you may need to remove the following lines from DJIUXSDK.h. Simply try to build the project and the errors will guide you to the correct lines.

~~~objc
#import <DJIUXSDK/DUXWidgetcollectionView.h>
#import <DJIUXSDK/DUXAircraftConnectionChecklistItem.h>
~~~

## Connecting to the Aircraft and Run the Project

Now, please check this [Connect Mobile Device and Run Application](../application-development-workflow/workflow-run.md#connect-mobile-device-and-run-application) guide to run the application and try the mini-DJI Go features we built so far using the UXSDK!

If you can see the live video feed and are able to test the features like in the video below, then congratulations! Using the DJI UXSDK is that easy.

![freeform](../images/tutorials-and-samples/iOS/UXSDKDemo/playVideo.gif)

### Summary

In this tutorial, you have learned how to easily use the DJI iOS UXSDK and DJI iOS Mobile SDK to create a fully functioning mini-DJI Go app, with standard DJI Go UI and functionality. Hope you enjoy it!
