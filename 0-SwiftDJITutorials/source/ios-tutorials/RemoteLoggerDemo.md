---
title: DJI Remote Logger Tutorial (Swift)
version: v4.14
date: 2021-06-08
github: https://github.com/godfreynolan/RemoteLoggerDemoSwift
keywords: [iOS remote logger demo, DJI Remote Logger, remote logging, debug, Swift]
---

<!-- toc -->

This tutorial is designed for you to obtain a better understanding of the DJI Remote Logger Tool. It will teach you how to use it for showing application log messages on a simple webpage.

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/RemoteLoggerDemoSwift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/DJIRemoteLoggerDemo) for an Objective C version. 


## Introduction

  This demo has two parts: a demo app built on **DJI iOS Mobile SDK** and a **Server Script**. The remote logger feature is integrated inside the SDK, you can use this feature in your application directly. For the server part, there are two connection modes showing below:

### HTTP Mode

![httpMode](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/httpModeFinalOne.png)

You can connect your iOS device and Mac to the same WiFi network or connect to a local wireless connection created on your Mac. Creating a local connection will allow you to test your application without an internet connection.

### Localhost Mode

![localHostMode](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/localHostModeFinal.png)

If you don't have an iOS device, you can use your Xcode Simulator to simulate one. Using the url string **http://localhost:4567** can work when using simulator.

## Setup and Run the Server

  You can get the server script from the **Server** folder from the **Github Page**. Please follow the steps below to setup the server:

  1. Open your terminal app and go to the Server folder
  2. Run bash script with the command: `./run_log_server.bash`
  3. Open the webpage with the address shown in the command line

If everything goes well, you should see something similar to the following screenshots:

---  
![localHostMode](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/commandline.png)

![webpage](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/webpageView.png)

---

### Troubleshooting

##### **1.** Lack of command line developer tools

If you meet the following error, you may need to install the command line developer tools:

![xcodeSelectInstall](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/xcodeSelectInstall.jpg)

Run this command: `xcode-select -install`, then you will see the following dialog:

![xcodeSelect](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/xcodeSelect.png)

After installing it, try `./run_log_server.bash` command again. Problem should be solved.

##### **2.** Lack of Ruby install

If you meet the following error, you may need to install ruby:

![installRuby](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/installRuby.png)

Run this command: `sudo brew install ruby`, after installing ruby successfully, try `./run_log_server.bash` command again. Problem should be solved.

For other issues, please check the two problems above.

## Download and Import the DJI SDK

 If you are not familiar with the process of installing DJI SDK in your Xcode project, please check the Github source code and this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#Xcode-Project-Integration) for details.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Enable Remote Logging

**1.** Implement the **DJISDKManagerDelegate** protocol method in ViewController.swift.

~~~Swift
    override func viewDidLoad() {
        super.viewDidAppear(animated)
        DJISDKManager.registerApp(with: self)
    }
~~~

> **Note:** If you don't know how to apply as a DJI developer and get the App Key, please refer to the [Get Started](../quick-start/index.md).

**2**. Next, let's implement the DJISDKManagerDelegate method as shown below:

~~~Swift
    //MARK: - DJISDKManager Delegate Method
    func appRegisteredWithError(_ error: Error?) {
        var message = "Register App Successed!"
        if let error = error {
            message = "Register App Failed! Please enter your App Key and check the network. Error: \(error.localizedDescription)"
        } else {
            // DeviceID can be whatever you'd like
            // URLString is provided in green when starting the server. It should begin with http:// and end with a port number
            DJISDKManager.enableRemoteLogging(withDeviceID: "DeviceID", logServerURLString: "http://192.168.128.181:4567")
        }
        NSLog("Register App: \(message)")
    }
~~~

The delegate method above gets called when the app is registered. If the registration is successful, we can call the `+(void) enableRemoteLoggingWithDeviceID: (NSString * _Nullable) deviceID logServerURLString: (NSString*) url;` class method of **DJISDKManager** to enable remote logging feature of the SDK by passing the **deviceID** parameter and **url** parameter, which you can get from the server script command line.

> **Note:**
>
> **1.** The **deviceID** is used to distinguish different iOS devices. You can show log messages from different iOS devices on the same webpage.
>
> **2.** The **url** is shown in the command line like this:
>
> ![webUrl](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/webUrl.png)

**3**. Build and run the project in Xcode. If everything is OK, you will see a "Register App Succeeded!" alert once the application loads.

## Show Log Message on Webpage

   Go to Main.storyboard and drag a UIButton to the center of the view, name it "Log SDK Version" and create an IBAction method, named `@IBAction func logSDKVersionButtonAction(_ sender: Any)` for it in the ViewController.swift file. Implement the IBAction method shown as below:

~~~Swift
    //MARK: - IBAction Method
    @IBAction func logSDKVersionButtonAction(_ sender: Any) {
        DJIRemoteLogger.log(with: .debug, file: #file, function: #function, line: #line, string: DJISDKManager.sdkVersion())
    }
~~~

Finally, build and run the project, press the button, you may be able to see the SDK version log message on the webpage like the following:

![appScreenshot](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/screenshot.png)

![webpageLog](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/webpageLog.png)

> **Note**: If you cannot see the logs on webpage and got the log message in the Xcode Console like this:
> ![consoleLog](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/consoleLog.png)
>
> You can solve this issue by adding the following item, "App Transport Security Settings" in the **Info.plist** file and modify the "Allow Arbitrary Loads" BOOL value to YES:
>
> ![appTransport](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/appTransport.png)
>

 Furthermore, the DJI Remote Logger Tool supports logging from multiple iOS devices, you can assign different Device IDs for different iOS devices in the `+(void)enableRemoteLoggingWithDeviceID:logServerURLString:` class method of DJISDKManager.

 Also you can use url content filter for specific device's log like this:
  `http://10.81.9.167:4567/?filter=113`.

 ![multipleDevices](../images/tutorials-and-samples/iOS/RemoteLoggerDemo/multipleDevices.png)

### Summary

  Congratulations! You've learned how to use DJI Remote Logger Tool to show log messages of your application using DJI Mobile SDK. With DJI Remote Logger Tool, you can develop and debug your application with DJI Mobile SDK more efficiently. Hope you enjoyed this tutorial!
