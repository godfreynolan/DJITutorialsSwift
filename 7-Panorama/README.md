# Swift-PanoramaDemo

## Introduction

From this demo, you will learn how to build a cool panorama app. You will use the Waypoint feature of Intelligent Navigation and Virtual Stick to rotate the aircraft to take photos and use OpenCV to stitch and crop photos into a panorama.

## Requirements

 - iOS 9.0+
 - Xcode 8.0+
 - DJI iOS SDK 4.14

## SDK Installation with CocoaPods

Since this project has been integrated with [DJI iOS SDK CocoaPods](https://cocoapods.org/pods/DJI-SDK-iOS) now, please check the following steps to install **DJISDK.framework** using CocoaPods after you downloading this project:

**1.** Install CocoaPods

Open Terminal and change to the download project's directory, enter the following command to install it:

~~~
sudo gem install cocoapods
~~~

The process may take a long time, please wait. For further installation instructions, please check [this guide](https://guides.cocoapods.org/using/getting-started.html#getting-started).

**2.** Install SDK with CocoaPods in the Project

Run the following command in the project's path:

~~~
pod install
~~~

If you install it successfully, you should get the messages similar to the following:

~~~
Analyzing dependencies
Downloading dependencies
Installing DJI-SDK-iOS (4.14)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `PanoDemo.xcworkspace` for this project from now on.
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

For this demo's tutorial: **Creating a Panorama Application**, please refer to <https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/PanoDemo.html>.

The tutorial is currently only available in Objective C.

## Known Issues

Due to the use of C++ for open cv stitching and clipping, some objective c++ files remain. This thread may be helpful in porting more of it to swift: https://stackoverflow.com/questions/35229149/interacting-with-c-classes-from-swift

## Feedback
When reporting bugs, at a minimum please let us know:

* Which DJI Product you are using
* Which iOS Device and iOS version you are using
* A short description of your problem includes debug logs or screenshots.
* Any bugs or typos you come across.

## License

Swift-PanoramaDemo is property of RIIS. All rights reserved.
