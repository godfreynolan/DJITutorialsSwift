# UXSDK-Demo-Swift

## Introduction

This UXSDK-Demo-Swift is designed for you to gain a better understanding of the DJI Bridge App. It will teach you how to use it for app debugging by implementing the live video view and two basic camera functionalities: "Take Photo" and "Record video".

## Requirements

 - iOS 9.0+
 - Xcode 8.0+
 - DJI iOS SDK 4.14
 - DJIWidget 1.6.4

## SDK Installation with CocoaPods

Since this project has been integrated with [DJI iOS SDK CocoaPods](https://cocoapods.org/pods/DJI-SDK-iOS) now, please check the following steps to install **DJISDK.framework** using CocoaPods after you downloading this project:

**1.** Install CocoaPods

Open Terminal and change to the download project's directory, enter the following command to install it:

~~~
sudo gem install cocoapods
~~~

The process may take a long time, please wait. For further installation instructions, please check [this guide](https://guides.cocoapods.org/using/getting-started.html#getting-started).

**2.** Install SDK and DJIWidget with CocoaPods in the Project

Run the following command in the project's path:

~~~
pod install
~~~

If you install it successfully, you should get the messages similar to the following:

~~~
Analyzing dependencies
Downloading dependencies
Installing DJI-SDK-iOS (4.14)
Installing DJIWidget (1.6.2)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `BridgeAppDemo.xcworkspace` for this project from now on.
Pod installation complete! There is 1 dependency from the Podfile and 1 total pod
installed.
~~~

> **Note**: If you saw "Unable to satisfy the following requirements" issue during pod install, please run the following commands to update your pod repo and install the pod again:
> 
> ~~~
> pod repo update
> pod install
> ~~~

## Tutorial

Here's this demo's [tutorial](https://github.com/SamScherer1/SwiftDJITutorials/blob/master/source/ios-tutorials/UXSDKDemo.md).

Here's a [version using Objective C](https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/UXSDKDemo.html).

The tutorial is currently only available in Objective C, but there are plans to create a Swift version.

A demo video of the application [can be found here](https://www.youtube.com/watch?v=niESaYdsdpQ)


## Known Issues

The demo app won't initially compile. You must comment out two lines from the UXSDK framework's header after running pod install. 
These lines import DUXWidgetcollectionView and DUXAircraftConnectionChecklistItem

## Feedback
When reporting bugs, at a minimum please let us know:

* Which DJI Product you are using
* Which iOS Device and iOS version you are using
* A short description of your problem includes debug logs or screenshots.
* Any bugs or typos you come across.

## License

UXSDK-Demo-Swift is property of RIIS. All rights reserved.
