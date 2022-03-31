---
title: Application Activation and Aircraft Binding (Swift)
version: v4.14
date: 2021-06-08
github: https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift
keywords: [Application Activation, Aircraft Binding, Link Mobile Phone Number, Bound, Activated, Real Name System, Swift]
---

> Note: The binding procedure is only necessary for applications used in **China**. For this reason only an [Objective C version](https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/ActivationAndBinding.html) of this tutorial exists. See [Integrate SDK into Application Tutorial](../application-development-workflow/workflow-integrate.md#register-application) for instructions on application activation and the final product [here](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift).

You can download the tutorial's final sample project from this [Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ActivationAndBindingDemo) for an Objective C version that also covers aircraft binding. 

---

## Important Advice
- Each lab application will require an SDK key tied to the bundle identifier of the application.  A tutorial for this can be [found here](https://developer.dji.com/mobile-sdk/documentation/quick-start/index.html#generate-an-app-key).  This key should be put into the `info.plist` file under the entry `DJISDKAppKey`.
- One consequence of drone apps running on a mobile device is that there is not a visible console to show debugging info like in a typical IDE.  DJI has created a solution for this in the form of the DJI Bridge App, which Module 11 covers.  If errors are encountered in earlier modules, it may be worth looking ahead to the [Bridge App tutorial](https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/BridgeAppDemo.html) to learn how to get debugging info from a drone app.
