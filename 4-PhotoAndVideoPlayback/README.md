# PlaybackDemoSwift

## Introduction

This PlaybackDemo is designed for you to learn how to use `DJIPlaybackManager` to access the media resources on the SD card of the aircraft's camera to preview photos, play videos, download or delete files.

## Requirements

 - iOS 10.0+
 - Xcode 8.0+
 - DJI iOS SDK 4.14
 - DJI iOS UX SDK 4.14
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
Installing DJI-UXSDK-iOS (4.14)
Installing DJIWidget (1.6.4)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `PlaybackDemo.xcworkspace` for this project from now on.
Pod installation complete! There is 1 dependency from the Podfile and 1 total pod
installed.
~~~

> **Note**: If you saw "Unable to satisfy the following requirements" issue during pod install, please run the following commands to update your pod repo and install the pod again:
>
> ~~~
> pod repo update
> pod install
> ~~~

## Not Supported DJI Products

 - OSMO
 - Phantom 3 Standard
 - Phantom 3 4K
 - Phantom 3 Advanced
 - Mavic Pro
 - Mavic 2 Series
 - Phantom 4 Pro
 - Inspire 2
 - Spark

## Tutorial

For this demo's tutorial: **Creating a Photo and Video Playback Application**, please refer to <https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/PlaybackDemo.html>.

The tutorial is currently only available in Objective C.

## Known Issues
PlaybackDemoSwift hasn't been completely converted to Swift from its Objective C counterpart. 


## Feedback
When reporting bugs, at a minimum please let us know:

* Which DJI Product you are using
* Which iOS Device and iOS version you are using
* A short description of your problem includes debug logs or screenshots.
* Any bugs or typos you come across.

## License

PlaybackDemoSwift is property of RIIS. All rights reserved.
