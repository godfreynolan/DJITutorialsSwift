---
title: DJI Simulator Tutorial
version: v4.14
date: 2021-06-03
github: https://github.com/godfreynolan/SimulatorDemo-Swift
keywords: [iOS simulator demo, VirtualStick, virtual stick, Swift]
---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

In this tutorial, you will learn how to use the DJISimulator in your Xcode project using DJI Mobile SDK. With the help of Virtual Stick control, you can input Virtual Stick flight control data and check the changes of simulator state in real time.

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/SimulatorDemo-Swift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-SimulatorDemo) for an Objective C version. 

We used a Mavic Pro to make this demo.

Let's get started!

## Introduction

DJISimulator is used to control the aircraft in a simulated environment based on the virtual stick input. The simulated aircraft state information will also be displayed on the screen.

You can use the `DJISimulator` class in `DJIFlightController` to control the simulation. It allows both manual and automated flights to be simulated without actually flying the aircraft.

Additionally, simulator initialization, monitoring and termination can be controlled directly through the SDK allowing for application development in continuous integration environments.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Implementing the UI of the Application

### Importing SDK and Register Application

Now, let's create a new project in Xcode, choose **Single View Application** template for your project and press "Next", then enter "DJISimulatorDemo" in the **Product Name** field and keep the other default settings.

Once the project is created, let's delete the **ViewController.swift file, which was created by Xcode when you created the project. Then create a UIView Controller named **RootViewController** and set the class of original ViewController object in the main storyboard to "RootViewController".

Next, let's import the DJISDK.framework to the project and implement the registration process in the **RootViewController**. If you are not familiar with the process of importing and activating DJI SDK, please check this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#Xcode-Project-Integration) for details.

### Working on the UI of Application

#### Creating the UI of RootViewController

Let's open "Main.storyboard" and embed **RootViewController** in a Navigation Controller which should be set as the Storyboard Entry Point. Next, drag and drop two UILabel objects to the RootViewController and set their default text to "Product Connection Status" and "Model: Not Available". Drag and drop a UIButton under the two UILabels, name it "Open", then set its background image as "btn.png" file, which you can get it from the tutorial's Github Sample Project. Lastly, setup the UI elements' auto layout to support multiple screen sizes.

#### Creating the UI of SimulatorViewController

Drag and drop another ViewController object from the Object Library to the right of **RootViewController** in the storyboard. Then create a new file called "SimulatorViewController.swift" in the navigator and initialize a subclass of UIViewController called SimulatorViewController there. Then set the class name of the new view controller in storyboard to SimulatorViewController too.

Furthermore, drag and drop 5 UIButton objects and place them on top, named them from the left to right as "EnterVirtualStickControl", "ExitVirtualStickControl", "Start Simulator", "Takeoff" and "Land". Make sure they are place inside a UIView object as subviews. Next, drag and drop a UILabel and place it under the 5 UIButton objects, named it as "Simulator State".

Lastly, place two UIImageViews inside a UIView (Label it as "VirtualStick Left") as subviews, and set their images as "stick\_base.png" and "stick\_normal.png", which you can get them from the tutorial's Github sample project. Now, the left joystick's UI has been setup. Similiarly, let's make the right joystick's UI in the same way.

For more detail configurations of storyboard, please check the tutorial's Github sample project. Your storyboard should look like this:

![](../images/tutorials-and-samples/iOS/SimulatorDemo/simulatorStoryboard.png)

## Working on RootViewController

Let's open RootViewController.swift file and create IBOutlets properties to link the UI elements in storyboard.

~~~swift
    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
~~~

Then add the following method to update the two UILabel objects' content when product connection updates:

~~~swift
    func updateStatusBasedOn(_ newConnectedProduct:DJIBaseProduct?) {
        if let product = newConnectedProduct {
            self.connectStatusLabel.text = "Status: Product Connected"
            self.modelNameLabel.text = "Model: \(product.model ?? "Not Available")"
            self.modelNameLabel.isHidden = false
        } else {
            self.connectStatusLabel.text = "Status: Product Not Connected"
            self.modelNameLabel.text = "Model: Unknown"
        }
    }
~~~

Next, invoke the above method in the `viewDidAppear` and `productConnected:` methods as shown below:

~~~swift
    override func viewDidAppear(_ animated: Bool) {
        if let product = self.product {
            self.updateStatusBasedOn(product)
        }
    }

    func productConnected(_ product: DJIBaseProduct?) {
        self.updateStatusBasedOn(product)
    }
~~~

For more details of the implementation of RootViewController, please check the tutorial's Github sample project.

## Implementing VirtualStickView

In order to input some simulated data, like `pitch`, `roll`, `yaw` and `verticalThrottle`, you will need a virtual stick control. In our previous step, we have finished the UI of the virtual stick, let's work on the implementation.

We implement the virtual stick control base on an open source Github project <a href="https://github.com/pyzhangxiang/joystick-ios" target="_blank">joystick_ios</a>, now create a new UIView class and named it as **VirtualStickView**. You can check the same class files in the tutorial's Github Sample Project for implementation details, here we just explain the notification logic.

The following method will be invoked in `touchEvent:`, `touchesEnded:withEvent:`, `touchesCancelled:withEvent:` and `onUpdateTimerTicked:` methods in VirtualStickView.m file:

~~~swift
    func sendNotificationWith(direction: CGPoint) {
        let directionValue = NSValue(cgPoint: direction)
        let userInfo = ["dir" : directionValue]
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "StickChanged"), object: self, userInfo: userInfo)
    }
~~~

When you touch the virtual stick image and drag it around inside the **VirtualStickView**, the NSNotificationCenter will post a notification with the name of "StickChanged" and the location of the virtual stick, which is represented by a CGPoint.

## Implementing SimulatorViewController

Once you finished implementing the VirtualStickView, let's continue to implement the rest of **SimulatorViewController**. Open the SimulatorViewController.swift file, import the following header files and create related IBOutlet properties and IBAction methods:

~~~swift
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

    @IBAction func onEnterVirtualStickControlButtonClicked(_ sender: Any) {

    }
    
    @IBAction func onExitVirtualStickControlButtonClicked(_ sender: Any) {

    }
    
    @IBAction func onSimulatorButtonClicked(_ sender: Any) {

    }

    @IBAction func onTakeoffButtonClicked(_ sender: Any) {

    }

    @IBAction func onLandButtonClicked(_ sender: Any) {

    }

}
~~~

Here, we first conform to **DJISimulatorDelegate** in the interface then create IBOutlet properties for the left and right `VirtualStickView`, `simulatorButton` and `simulatorStateLabel`. The `isSimulatorOn` bool property is used to store the start state of DJISimulator. `mXVelocity`, `mYVelocity`, `mYaw` and `mThrottle` properties are used to store the `DJIVirtualStickFlightControlData` struct data of `DJIFlightController`.

The remaining five IBAction methods are related to the five UIButtons on top. We will use them to **enter** or **exit** virtual stick, **take off** or **auto land** the aircraft and **start** or **stop** simulator. 

Before we continue to implement the **SimulatorViewController**, let's create a **DemoUtility** file to define some common methods:

- DemoUtility.swift

~~~swift
import Foundation
import UIKit
import DJISDK

func showAlertWith(_ result:String) {
    DispatchQueue.main.async {
        let alertViewController = UIAlertController(title: nil, message: result as String, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertViewController.addAction(okAction)
        let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        navController.present(alertViewController, animated: true, completion: nil)
    }
}

func showAlertWith(title:String?, message:String, cancelAction:UIAlertAction, defaultAction:UIAlertAction, presentingViewController:UIViewController) {
    let alertViewController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    alertViewController.addAction(cancelAction)
    alertViewController.addAction(defaultAction)
    presentingViewController.present(alertViewController, animated: true, completion: nil)
}

func fetchProduct () -> DJIBaseProduct? {
    return DJISDKManager.product()
}

func fetchAircraft () -> DJIAircraft? {
    return DJISDKManager.product() as? DJIAircraft
}

func fetchFlightController() -> DJIFlightController? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.flightController
}
~~~

The `fetchProduct`, `fetchAircraft` and `fetchFlightController ` methods are used to get the latest DJIBaseProduct, DJIAircraft and DJIFlightController objects. The `showAlertViewWithTitle:message: cancelAlertAction:defaultAlertAction:viewController:` method is used to show an alertView to the user.

### Working on the Virtual Stick Control feature

Now, let's come back to "SimulatorViewController.swift" and implement the virtual stick feature. First, we create an NSNotificationCenter variable and invoke the `addObserver:selector:name:object:` method to observe the "StickChanged" notification, which is posted from the **VirtualStickView**. When the notification is posted, a selector method `onStickChanged:` will be invoked to send virtual stick flight control data as shown below:

~~~swift
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "DJISimulator Demo"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onStickChangedWith(notification:)),
                                               name: NSNotification.Name("StickChanged"),
                                               object: nil)
    }
~~~

Next, implement the `onStickChanged:` select method and `setThrottle:andYaw:`, `setXVelocity:andYVelocity:` methods as shown below:

~~~swift
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

    func updateVirtualStick() {
        let controlData = DJIVirtualStickFlightControlData(pitch: self.mYVelocity,
                                                           roll: self.mXVelocity,
                                                           yaw: self.mYaw,
                                                           verticalThrottle: self.mThrottle)
        if let flightController = fetchFlightController(), let _ = flightController.simulator {
            flightController.send(controlData, withCompletion: nil)
        }
    }
~~~

In the code above, we implement the following features:

**1.** In the `onStickChanged:` method, we get the CGPoint object of the moving virtual stick's position, cast the notification object to get the `VirtualStickView` object. Then we invoke the `setThrottle:andYaw` and `setXVelocity:andYVelocity:` methods based on the current controlling virtual stick.

**2.** The range of VirtualStickView's movement is [-1, 1], up and down, left and right. Please check the follow diagram for details:

![](../images/tutorials-and-samples/iOS/SimulatorDemo/virtualStickControl.png)

The range of **x** and **y** in the `dir` variable is [-1, 1]. In the `setThrottle:andYaw:` method, we multiply `y` by -2 to change the range to [-2, 2] from bottom to top, then multiply `x` by 30 to change the range to [-30, 30]. These ranges are tested by us to achieve a more realistic control experience.

Lastly, invoke the `updateVirtualStick` method to send the virtual stick control data.

**3.** In the `setXVelocity:andYVelocity:` method, we multiply the `x` and `y` variables with `DJIVirtualStickRollPitchControlMaxVelocity` to change the range to [-15, 15].

Then invoke the `updateVirtualStick` method to send the virtual stick control data.

**4.** In the `updateVirtualStick` method, we first create and initialize a `DJIVirtualStickFlightControlData` variable and assign its `pitch`, `roll`, `yaw` and `verticalThrottle` values with `self.mYVelocity`, `self.mXVelocity`, `self.mYaw` and `self.mThrottle`. Then invoke the `sendVirtualStickFlightControlData:withCompletion:` method of DJIFlightController to send the simulated virtual stick control data to the aircraft.
Once you finished the above step, let's implement the **Enable Virtual Stick** and **Exit Virtual Stick** IBAction methods:

~~~swift
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
~~~

~~~swift
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
~~~

In the `onEnterVirtualStickControlButtonClicked:` IBAction method, we first assign the `yawControlMode` and `rollPitchControlMode` properties of DJIFlightController to `DJIVirtualStickYawControlModeAngularVelocity` and `DJIVirtualStickRollPitchControlModeVelocity`. Then invoke the `setVirtualStickModeEnabled:withCompletion:` method of DJIFlightController to enable the virtual stick control.

Similiarly, in the `onExitVirtualStickControlButtonClicked:` IBAction method, we invoke the `setVirtualStickModeEnabled:withCompletion:` method of DJIFlightController to disable virtual stick control.

### Implementing DJISimulator

  Before we implement the DJISimulator feature, we may need to update the `simulatorButton`'s title and hidden state first. Let's override the `viewWillAppear:` and `viewWillDisappear:` methods as shown below:

~~~swift
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
~~~

In the `viewWillAppear:` method, we first fetch the DJIFlightController object and update the `isSimulatorOn` variable, then invoke the `updateSimulatorUI` method to update the `simulatorButton` label. Furthermore, we use KVO here to observe the changes of `isSimulatorActive` variable value of `DJISimulator`. Then set the delegate of the DJIFlightController's DJISimulator to self(SimulatorViewController).

Next in the `viewWillDisappear:` method, we fetch the latest DJIFlightController object, then remove the observer of `isSimulatorActive`, and set the delegate of DJISimulator to nil.

Moreover, in the NSKeyValueObserving method, we fetch and update the latest `isSimulatorOn` property and invoke the `updateSimulatorUI` method to update the `simulatorButton`.

Now, let's implement the `onSimulatorButtonClicked:` IBAction method as shown below:

~~~swift
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

~~~

Also, implement a helper method for fetching the flight controller and sending failure messages to an alert.

~~~swift
    func verboseFetchFlightController() -> DJIFlightController? {
        guard let flightController = fetchFlightController() else {
            showAlertWith("Failed to fetch flightController")
            return nil
        }
        return flightController
    }
~~~

In the code above, we first check if the simulator is started, if not, then create an initial aircraft location with CLLocationCoordinate2DMake(22, 113). Next invoke the `startWithLocation:updateFrequency:GPSSatellitesNumber:withCompletion:` method of `DJISimulator` with the frequency of 20 and GPS satellite number of 10 to start the simulator. For more details of this method, please check the following method's inline documentation:

~~~objc
/**
 *  Start simulator. Will result in error if simulation is already started.
 *
 *  @param location     Simulator coordinate latitude and longitude in degrees.
 *  @param frequency    Aircraft simulator state push frequency in Hz with range
 *                      [2, 150]. A setting of 10 Hz will result in delegate
 *                      method being called, 10 times per second.
 *  @param number       The initial number of GPS satellites with range [0, 20].
 *  @param completion        The completion block.
 */
- (void)startWithLocation:(CLLocationCoordinate2D)location
          updateFrequency:(NSUInteger)frequency
      GPSSatellitesNumber:(NSUInteger)number
           withCompletion:(DJICompletionBlock)completion;
~~~

if the simulator has already started, we can invoke the `stopWithCompletion:` method of DJISimulator to stop the simulator.

Lastly, let's implement the DJI Simulator delegate method as shown below:

~~~swift
    func simulator(_ simulator: DJISimulator, didUpdate state: DJISimulatorState) {
        self.simulatorStateLabel.isHidden = false
        self.simulatorStateLabel.text = String(format:"Yaw: %0.2f Pitch: %0.2f, Roll: %0.2f\n PosX: %0.2f PosY: %0.2f PosZ: %0.2f", state.yaw, state.pitch, state.roll, state.positionX, state.positionY, state.positionZ)
    }
~~~

This delegate method will be invoked when the simulator state is updated. We can update the `simulatorStateLabel`'s hidden state and its text content here.

### Working on Takeoff and AutoLanding features

In order to simulate the aircraft's flight behaviour in a simulated environment, we will implement the take off and auto landing features here in the following two IBAction methods:

~~~swift
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
        self.verboseFetchFlightController()?.startTakeoff { (error:Error?) in
            if let error = error {
                showAlertWith("Landing \(error.localizedDescription)")
            } else {
                showAlertWith("Landing Success.")
            }
        }
    }
~~~

In the `onTakeoffButtonClicked:` IBAction method, we invoke the `startTakeoffWithCompletion:` method of DJIFlightController to send the take off command to the aircraft. Similiarly, in the `onLandButtonClicked:` IBAction method, we invoke the `startLandingWithCompletion:` method to send the auto landing command. It's just that simple and easy.

We have gone through a long way so far, now, let's build and run the project, connect the demo application to  your Mavic Pro (Please check the [Run Application](../application-development-workflow/workflow-run.md) for more details) and check all the features we have implemented so far.

If everything goes well, you should see something similiar to the following gif animation:

![](../images/tutorials-and-samples/iOS/SimulatorDemo/simulatorAnimation.gif)

- If the demo application is connected with Mavic Pro successfully, you should see the `connectButton` button is available to press and the `connectStatusLabel` and `modelNameLabel` show the correct infos.
- Press **Open** and enter the simulator demo page, press **EnterVirtualStickControl** button to enable virtual stick control, then press "Start Simulator" to start the simulator.
- Moreover, press the **Takeoff** button to send take off command to the aircraft, if the command executes successfully, you should see the **PosZ** value start to change, means that the aircraft is rising.
- Now you can drag the left and right virtual stick controls to simulate the flight behavious.
- Lastly, press the "Land" button to make the aircraft start auto landing, once it finish, you may notice the **PosZ** value become "0.00". Press the "Stop Simulator" button to stop the simulator and then press "ExitVirtualStickControl" to disable the virtual stick control.

### Summary

In this tutorial, you've learned how to use the DJISimulator feature to simulate aircraft's flight behaviour in a simulated environment based on the virtual stick control input and show the changes of simulator state(Yaw,Pitch,Roll,PosX,PosY and PosZ) in real time. Also you've learned how to use Virtual Stick control to send virtual stick flight control data to the aircraft.

This demo is a simple demonstration of using DJISimulator, to have a better user experience, you can create a 3D simulated environment using 3D game engine like <a href="https://unity3d.com" target="_blank"> Unity3D </a> or <a href="http://cocos3d.org" target="_blank"> Cocos3D </a> to show the simulated data and aircraft flight behaviors inside your mobile application (Like the Flight Simulator in DJI Go app)!  

Furthermore, the DJISimulator allows for automated testing in continous integration environment(Like <a href="https://jenkins.io" target="_blank"> Jenkins </a>), it would help your DJI-SDK based application testing process. Good luck, and hope you enjoyed this tutorial!
