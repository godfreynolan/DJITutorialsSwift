---
title: Creating a MapView and Waypoint Application (Swift)
version: v4.12
date: 05/27/2021
github: https://github.com/godfreynolan/iOS-GSDemo-Swift
keywords: [iOS GSDemo, waypoint mission demo, Swift]
---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

In this tutorial, you will learn how to implement the DJIWaypoint Mission feature and get familiar with the usages of DJIMissionControl.
Also you will know how to test the Waypoint Mission API with DJI Assistant 2 Simulator too. So let's get started!

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/iOS-GSDemo-Swift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-GSDemo) for an Objective C version. 

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account.

 If an application is not activated, the aircraft not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Setup The Map View

### 1. Importing the SDK

Now, let's create a new project in Xcode, choose **Single View Application** template for your project and press "Next", then enter "GSDemo" in the **Product Name** field and keep the other default settings.

Once the project is created, let's import the **DJISDK.framework** to it. If you are not familiar with the process of importing the DJI SDK, please check this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md) for details.

### 2. Creating the Map View

Now, let's open the **GSDemo.xcworkspace** and delete the **ViewController.swift** file, which was created by Xcode when you created the project. Then, create a viewController named "**RootViewController**" and set it as the **Root View Controller** in Main.storyboard. Moreover, drag a **MKMapView** from Object Library to **RootViewController**, setup its AutoLayout constraints, and set its delegate to **RootViewController**, as seen below:

![mkMapView](../images/tutorials-and-samples/iOS/GSDemo/mkMapView.png)

After that, import the **MapKit.framework** to the project and open the "RootViewController.m" file, create an IBOutlet for the MKMapView, name it "**mapView**" and link it to the MKMapView in **Main.storyboard**. Import the following header files and implement MKMapView's delegate method:

~~~Swift
import Foundation
import UIKit
import MapKit
import CoreLocation
import DJISDK

class RootViewController : UIViewController, MKMapViewDelegate {

}
~~~

Now, let's build and run the project. If everything is as it should be, you should see the following screenshot:

![mapView](../images/tutorials-and-samples/iOS/GSDemo/mapView.png)

### 3. Adding Annotations to the MapView

Currently, the map view is simple. Let's add something interesting to it. Create a new **NSObject** file named **MapController**, which will be used to deal with the MKAnnotations(or for our purposes, Waypoints) logic on the map. Open the MapController.swift file and add the following code to it:

~~~Swift
import Foundation
import UIKit
import MapKit

class MapController : NSObject {

    var editPoints : [CLLocation]

    override init() {
        self.editPoints = [CLLocation]()
        super.init()
    }

    func add(point:CGPoint, for mapView:MKMapView) {
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.editPoints.append(location)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func cleanAllPoints(with mapView: MKMapView) {
        self.editPoints.removeAll()
        let annotations = [MKAnnotation].init(mapView.annotations)
        for annotation : MKAnnotation in annotations {
            if annotation !== self.aircraftAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
}
~~~

Create an NSMutableArray called **editPoints** to store waypoint objects amd initialize it in the init method.

Implement a method to **Add** waypoints: create MKPointAnnotation objects from CGPoints and add them to our **mapView**.

Implement the **cleanAllPoints(with mapView:)** method to clean up the **editPoints** array and the annotations on the mapView.

Go back to the RootViewController.swift file and create a MapController property named **mapController**. Lastly, add a UIButton to the RootViewController scene in Main.storyboard, set its IBOutlet name as "**editBtn**", add a boolean property called isEditingPoints and add an IBAction method named "**editBtnAction**" for it, as shown below:

~~~Swift
    var mapController : MapController?

    @IBOutlet weak var editBtn: UIButton!

    @IBAction func editBtnAction(_ sender: Any) {
        if self.isEditingPoints {
            self.mapController?.cleanAllPoints(with:self.mapView)
            self.editBtn.setTitle("Edit", for: .normal)
        } else {
            self.editBtn.setTitle("Reset", for: .normal)
        }
    }
~~~

![editButton](../images/tutorials-and-samples/iOS/GSDemo/editButton.png)

Once that is complete, open the RootViewController.m file, initialize the **mapController** and **tapGesture** variables, and add the **tapGesture** to mapView to add waypoints. Furthermore, we need a boolean variable named "**isEditingPoints**" to store the edit waypoint state, which will also change the title of **editBtn** accordingly. Lastly, implement tapGesture's action method **addWayPoints**, as shown below:

~~~Swift
class RootViewController : UIViewController, DJISDKManagerDelegate, MKMapViewDelegate {

    var isEditingPoints = false
    @IBOutlet weak var mapView: MKMapView!

    //MARK: Custom Methods
    @objc func addWaypoints(tapGesture:UITapGestureRecognizer) {
        let point = tapGesture.location(in: self.mapView)
        if tapGesture.state == UIGestureRecognizer.State.ended {
            if self.isEditingPoints {
                self.mapController?.add(point: point, for: self.mapView)
            }
        }
    }

    //MARK:  MKMapViewDelegate Method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKPointAnnotation.self) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin_Annotation")
            pinView.pinTintColor = UIColor.purple
            return pinView
        }
        return nil
    }
}

~~~

In the above code, we also added an NSNotification observer to check the DJI Mobile SDK's state and make sure it was sucessfully registered. At the same time, we implement the **addWaypoints** gesture action by calling DJIMapController's add(point:CGPoint, for mapView:) method to add waypoints to the map. Next, we implement the IBAction method **editBtn**, which will update the button's title and clean up waypoints based on the value of **isEditingPoints**. Finally, we implement MKMapViewDelegate's method to change the pin color to purple.

When you are done with all the steps above, build and run your project and try to add waypoints on the map. If everything is fine, you will see the following animation:

![addWaypoint](../images/tutorials-and-samples/iOS/GSDemo/addWaypoint.gif)

### 4. Focusing the MKMapView

You may be wondering why the map's location is different from your current location and why it is difficult to find your location on the map. Focusing the map to your current location quickly would be helpful for the application. To implement that feature, we need to use **CLLocationManager**.

Open the RootViewController.swift file and import CoreLocation. Create a CLLocationManager property named "locationManager". Then create a CLLocationCoordinate2D property named "userLocation" to store the user's location data. Next, implement CLLocationManager's **CLLocationManagerDelegate** protocol in the class, as shown below:

~~~Swift
import Foundation
import UIKit
import MapKit
import DJISDK
import CoreLocation

class RootViewController : UIViewController, DJISDKManagerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    var isEditingPoints = false
    var locationManager : CLLocationManager?
    var userLocation : CLLocationCoordinate2D?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editBtn: UIButton!


    @IBAction func focusMapBtnAction(_ sender: Any) {
        self.focusMap()
    }
    
    func focusMap() {
        guard let userLocation = self.userLocation else {
            return
        }
        
        if CLLocationCoordinate2DIsValid(userLocation) {
            let center = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
}
~~~

In the code above, we also added a UIButton named "Focus Map" in RootViewController's scene in Main.storyboard and added an IBAction method named as **focusMapAction**. Here is the screenshot of the scene from Main.storyboard:

![focusMap](../images/tutorials-and-samples/iOS/GSDemo/focusMap.png)

Now go back to RootViewController.swift and add the following code:

~~~Swift
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startUpdateLocation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.locationManager?.stopUpdatingLocation()
    }


    func prefersStatusBarHidden() -> Bool {
        return false
    }

    //MARK:  CLLocation Methods
    func startUpdateLocation() {
        if CLLocationManager.locationServicesEnabled() {
            if self.locationManager == nil {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager?.distanceFilter = 0.1
                self.locationManager?.requestAlwaysAuthorization()
            }
        } else {
            showAlertWith("Location Service is not available")
        }
    }

    //MARK:  - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last?.coordinate
    }

~~~

First, we initialize **userLocation** data to kCLLocationCoordinate2DInvalid in the viewDidLoad method. Then we add a new method named as "startUpdateLocation" to initialize **locationManger**, set its properties and start updating location. If the Location Service is not available, we add a UIAlertView to display the warning. The **startUpdateLocation** is called in viewWillAppear method and is stopped in the viewWillDisappear method. Moreover, we need to implement CLLocationManagerDelegate method to update **userLocation** property. Finally, we implement the "focusMapAction" method to focus **mapView** to the user's current location.

There is a "DemoUtility" that defines methods such as `showAlertWith()` that will be used frequently in the project. Let's implement it now. Create a new swift file and named it as "DemoUtility.swift", replace its content with the following:

~~~Swift
import Foundation
import DJISDK

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
}

func showAlertWith(_ result:String) {
    DispatchQueue.main.async {
        let alertViewController = UIAlertController(title: nil, message: result as String, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertViewController.addAction(okAction)
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(alertViewController, animated: true, completion: nil)
    }
}

func fetchFlightController() -> DJIFlightController? {
    if let aircraft = DJISDKManager.product() as? DJIAircraft {
        return aircraft.flightController
    }
    return nil
}

~~~
Next, add a "Privacy - Location Always Usage Description" or "Privacy - Location When In Use Usage Description" key to your project’s Info.plist containing the message to be displayed to the user when a UIAlert asking whether or not they want to allow the application to use their location. We set the messages empty here:

![infoPlist](../images/tutorials-and-samples/iOS/GSDemo/infoPlist.png)

It's time to build and run the project to check the focus map feature. When you launch the app for the first time, a pop up alert asking for your permission to access your location will appear. Select **Allow** and press the **Focus Map** button. If the map view animates to your current location like the following animation, congratulations, you have finished the **Focus Map** feature!

![focusMap](../images/tutorials-and-samples/iOS/GSDemo/focusMap.gif)

### 5. Showing the Aircraft on Map View

Now, we can focus the mapView to our current location, which is a good start! However, let's do something more interesting. We're going to simulate the aircraft's GPS location using the DJI Assistant 2 Simulator and show it on our map view.

You can check the [DJI Assistant 2 Simulator](../application-development-workflow/workflow-testing.md#dji-assistant-2-simulator) for its basic usage. If you want to place the aircraft in your current GPS location on Map View, you can set the latitude and longitude values in the **Simulator Config** to yours. We take the simulator's initial values in the following example.

Let's come back to the code. Create a new subclass of **MKAnnotationView** named "AircraftAnnotationView" and a new subclass of NSObject named **AircraftAnnotation**. Below is the code:

- AircraftAnnotationView.swift

~~~Swift
import Foundation
import MapKit

class AircraftAnnotationView: MKAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.isEnabled = false
        self.isDraggable = false
        self.image = UIImage(named: "aircraft.png")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func update(heading:Float) {
        self.transform = CGAffineTransform.identity
        self.transform = CGAffineTransform(rotationAngle: CGFloat(heading))
    }
}

~~~

In the code above, we create a MKAnnotationView for the aircraft, add a method named **updateHeading** to change the aircraft's rotation, and set its image to "aircraft.png"(You can get the image from this tutorial's demo project.) in the init method. Also, we disable the AircraftAnnotationView's draggable property. Take a look at the code below:

- DJIAircraftAnnotation.swift

~~~Swift
import Foundation
import MapKit

class AircraftAnnotation : NSObject, MKAnnotation {
    var coordinate : CLLocationCoordinate2D
    var annotationView : AircraftAnnotationView?
    
    init(coordinate:CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    func update(heading:Float) {
        self.annotationView?.update(heading: heading)
    }
}
~~~

The **AircraftAnnotation** class implements the **MKAnnotation** protocol. It's used to store and update a CLLocationCoordinate2D property. Also, we can update AircraftAnnotationView's heading with the **updateHeading** method.

Create a property of type AircraftAnnotation in MapController and name it **aircraftAnnotation**.

~~~Swift
    var aircraftAnnotation : AircraftAnnotation?
~~~

Furthermore, add two new methods to update the aircraft's location and its heading on the map.

~~~Swift
    func updateAircraft(location:CLLocationCoordinate2D, with mapView:MKMapView) {
        if self.aircraftAnnotation == nil {
            self.aircraftAnnotation = AircraftAnnotation(coordinate: location)
            mapView.addAnnotation(self.aircraftAnnotation!)
        } else {
            self.aircraftAnnotation?.coordinate = location
        }
    }
    
    func updateAircraftHeading(heading:Float) {
        if let _ = self.aircraftAnnotation {
            self.aircraftAnnotation!.update(heading: heading)
        }
    }
~~~

Also, since we don't want the **aircraftAnnotation** removed by the **cleanAllPointsWithMapView** method in the MapController.swift file, we need to modify it, as shown below:

~~~Swift
    func cleanAllPoints(with mapView: MKMapView) {
        self.editPoints.removeAll()
        let annotations = [MKAnnotation].init(mapView.annotations)
        for annotation : MKAnnotation in annotations {
            if annotation !== self.aircraftAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
~~~
We add an if statement to check if the annotation of the map view is equal to the **aircraftAnnotation** property, and if it is not, we remove it. By doing so, we can prevent the Aircraft's annotation from being removed.

To provide a better user experience, we need to add a status view on top of the mapView to show the aircraft's flight mode type, current GPS satellite count, vertical and horizontal flight speed and the flight altitude. Let's add the UI in Main.storyboard's RootViewController Scene, as seen below:

![statusView](../images/tutorials-and-samples/iOS/GSDemo/statusView.png)

Once that's done, open RootViewController.swift, and create IBOutlets for the above UI elements and import DJISDK's header file and implement "DJIFlightControllerDelegate" and "DJISDKManagerDelegate" protocols. Also, we need to create a CLLocationCoordinate2D property named **droneLocation** to record the aircraft's location, as shown below:

~~~Swift
import Foundation
import UIKit
import MapKit
import CoreLocation
import DJISDK

class RootViewController : UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate {

    var droneLocation : CLLocationCoordinate2D?

    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var gpsLabel: UILabel!
    @IBOutlet weak var hsLabel: UILabel!
    @IBOutlet weak var vsLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!

~~~

Now, let's initialize the location data for RootViewController a new method called **initData**. Call the initData method in the viewDidLoad method. Lastly, make sure you register your app in the viewDidLoad() method too.

~~~Swift

    //MARK:  Init Methods
    func initData() {
        self.userLocation = kCLLocationCoordinate2DInvalid
        self.droneLocation = kCLLocationCoordinate2DInvalid
        self.mapController = MapController()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoints(tapGesture:)))
        self.mapView.addGestureRecognizer(tapGesture)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DJISDKManager.registerApp(with: self)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoints(tapGesture:)))
        self.mapView.addGestureRecognizer(tapGesture)
    }
~~~

Next, implement the "DJISDKManagerDelegate" method as follows:

~~~Swift

    //MARK: DJISDKManagerDelegate Methods
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            let registerResult = "Registration Error: \(error.localizedDescription)"
            showAlertWith(registerResult)
        } else {
            DJISDKManager.startConnectionToProduct()
        }
    }

    func productConnected(_ product: DJIBaseProduct?) {
        if let _ = product, let flightController = fetchFlightController() {
            flightController.delegate = self
        } else {
            showAlertWith("Flight controller disconnected")
        }
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state:DJIUserAccountState, error: Error?) in
            if let error = error {
                NSLog("Login failed: %@", error.localizedDescription)
            }
        }
    }

~~~

In the code above, we can implement DJISDKManager's `appRegisteredWithError:` delegate method to check the register status and invoke the DJISDKManager's "startConnectionToProduct" method to connect to the aircraft. Moreover, the `productConnected:` delegate method will be invoked when the product connectivity status changes, so we can set DJIFlightController's delegate as RootViewController here when product is connected.


Then in the **viewWillDisappear** method of RootViewController, we need to invoke the "stopUpdatingLocation" method of CLLocationManager to stop update location as shown below:

~~~Swift
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.locationManager?.stopUpdatingLocation()
    }
~~~

Also, update **focusMap** to set **droneLocation** as the center of the map view's region, as shown below:

~~~Swift
    func focusMap() {
        guard let droneLocation = self.droneLocation else {
            return
        }
        
        if CLLocationCoordinate2DIsValid(droneLocation) {
            let center = CLLocationCoordinate2D(latitude: droneLocation.latitude, longitude: droneLocation.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
~~~

Next, We need to modify the **MKMapViewDelegate** method to what is shown below. It will set the annotation's annotationView to a **AircraftAnnotationView** Class type object if it's an AircraftAnnotation:

~~~Swift
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKPointAnnotation.self) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin_Annotation")
            pinView.pinTintColor = UIColor.purple
            return pinView
        } else if annotation.isKind(of: AircraftAnnotation.self) {
            let annotationView = AircraftAnnotationView(annotation: annotation, reuseIdentifier: "Aircraft_Annotation")
            (annotation as? AircraftAnnotation)?.annotationView = annotationView
            return annotationView
        }
        return nil
    }
~~~

Furthermore, let's implement the **DJIFlightControllerDelegate** method:

~~~Swift
    //MARK:  DJIFlightControllerDelegate
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        self.droneLocation = state.aircraftLocation?.coordinate
        self.modeLabel.text = state.flightModeString
        self.gpsLabel.text = String(state.satelliteCount)
        self.vsLabel.text = String(format: "%0.1f M/S", state.velocityZ)
        self.hsLabel.text = String(format: "%0.1f M/S", sqrt(pow(state.velocityX,2) + pow(state.velocityY,2)))
        self.altitudeLabel.text = String(format: "%0.1f M", state.altitude)
        
        if let droneLocation = droneLocation {
            self.mapController?.updateAircraft(location: droneLocation, with: self.mapView)
        }
        let radianYaw = state.attitude.yaw.degreesToRadians
        self.mapController?.updateAircraftHeading(heading: Float(radianYaw))
    }
~~~

First, it will update the **droneLocation** with the aircraft's current location. Next, update the text for the status labels from the `DJIFlightControllerState`. Furthermore, update the aircraft's location and heading by calling the related methods from **DJIMapController**.

Now, let's test the application!

Build and run the project to install the app onto your mobile device. After that, please connect the aircraft to your Mac via a Micro USB cable, and then power on the aircraft and the remote controller. Click **Simulator** to enter the Simulator page. You can type in your current location's latitude and longitude data in the Simulator Settings, if you would like.

![simulatorPreview](../images/tutorials-and-samples/iOS/GSDemo/simulator_preview.png)

Then, run the app and connect your mobile device to the remote controller using Apple's lightning cable.

Next, let's go to the DJI Assistant 2 Simulator on your Mac and press the **Start Simulation** button. If you check the application now, a tiny red aircraft will be shown on the map as seen below:

![aircraftOnMap](../images/tutorials-and-samples/iOS/GSDemo/aircraftOnMap.png)

If you cannot find the aircraft, press the "**Focus Map**" button and the map view will zoom in to center the aircraft on the center of the map view region as shown below:

![focusAircraft](../images/tutorials-and-samples/iOS/GSDemo/focusAircraft.gif)

Now, if you press the **Stop Simulation** button on the Simulator Config, the aircraft will disappear on the map, since the simulator stops providing GPS data to the aircraft.

## Refactoring the UI

As you seen, the project's code structure was simple and not robust. In order to develop it further in this tutorial, it will need to be refactored and we will need to add more UI elements.

### 1. Adding & Handling the New UIButtons

Firstly, we will create a new file named "DJIGSButtonController", which will be subclass of **UIViewController**. Make sure the check box saying "Also create XIB file" is selected when creating the file. Then open the DJIGSButtonController.xib file and set its size to **Freeform** under the "Size" dropdown in the **Simulated Metrics** section. In the view section, change the width to "100" and height to "288". Take a look at the changes made below:

![freeform](../images/tutorials-and-samples/iOS/GSDemo/freeform.png)
![changeSize](../images/tutorials-and-samples/iOS/GSDemo/changeFrameSize.png)

Next, drag eight UIButtons to the view and change their names to "Edit", "Back", "Clear", "Focus Map", "Start", "Stop", "Add" and "Config". "Edit" will sit on top of "Back", and "Focus Map" will sit on top of "Add". Make sure to hide the "Back", "Clear", "Start", "Stop", "Add" and "Config" buttons.

![gsButtons](../images/tutorials-and-samples/iOS/GSDemo/gsButtonViews.png)

 Then add IBOutlets and IBActions for each of the eight buttons in the DJIGSButtonViewController.swift file. Also, we will add an Enum named **DJIGSViewMode** with the two different modes the application could be in. Next, we add serveral delegate methods to be called by the delegate viewcontroller when IBAction methods for the buttons are triggered. Lastly, add the method **switchToMode:inGSButtonVC:** to update the state of the buttons when the **DJIGSViewMode** changed. Take a look at the code below:

 ~~~Swift
import Foundation
import UIKit

enum GSViewMode {
    case view
    case edit
}

protocol GSButtonViewControllerDelegate : AnyObject {
    func stopBtnActionIn(gsBtnVC:GSButtonViewController)
    func clearBtnActionIn(gsBtnVC:GSButtonViewController)
    func focusMapBtnActionIn(gsBtnVC:GSButtonViewController)
    func startBtnActionIn(gsBtnVC:GSButtonViewController)
    func add(button:UIButton, actionIn gsBtnVC:GSButtonViewController)
    func configBtnActionIn(gsBtnVC:GSButtonViewController)
    func switchTo(mode:GSViewMode, inGSBtnVC:GSButtonViewController)
}

class GSButtonViewController : UIViewController {
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var focusMapBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var configBtn: UIButton!
    var mode = GSViewMode.view
    var delegate : GSButtonViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init() {
        super.init(nibName:"GSButtonViewController", bundle:Bundle.main)
    }
    
    convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init()
    }
    
    convenience required init?(coder: NSCoder) {
        self.init()
    }
    
    //MARK - Property Method
    func setMode(mode:GSViewMode) {
        self.mode = mode
        self.editBtn.isHidden = (mode == GSViewMode.edit)
        self.focusMapBtn.isHidden = (mode == GSViewMode.edit)
        self.backBtn.isHidden = (mode == GSViewMode.view)
        self.clearBtn.isHidden = (mode == GSViewMode.view)
        self.startBtn.isHidden = (mode == GSViewMode.view)
        self.stopBtn.isHidden = (mode == GSViewMode.view)
        self.addBtn.isHidden = (mode == GSViewMode.view)
        self.configBtn.isHidden = (mode == GSViewMode.view)
    }
        
    //MARK: - IBAction Methods
    @IBAction func backBtnAction(_ sender: Any) {
        self.setMode(mode: GSViewMode.view)
        self.delegate?.switchTo(mode: self.mode, inGSBtnVC: self)
    }
    
    @IBAction func stopBtnAction(_ sender: Any) {
        self.delegate?.stopBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func clearBtnAction(_ sender: Any) {
        self.delegate?.clearBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func focusMapBtnAction(_ sender: Any) {
        self.delegate?.focusMapBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func editBtnAction(_ sender: Any) {
        self.setMode(mode: GSViewMode.edit)
        self.delegate?.switchTo(mode: self.mode, inGSBtnVC: self)
    }
    
    @IBAction func startBtnAction(_ sender: Any) {
        self.delegate?.startBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func addBtnAction(_ sender: Any) {
        self.delegate?.add(button: self.addBtn, actionIn: self)
    }
    
    @IBAction func configBtnAction(_ sender: Any) {
        self.delegate?.configBtnActionIn(gsBtnVC: self)
    }
}
 ~~~

 With those changes, the code structure will look cleaner and more robust, which will help in its maintainence later on.

 Now, let's go to the RootViewController.swift file and delete the **editButton** IBOutlet, the **resetPointsAction** method, and the **focusMapAction** method. After making those deletions, create an UIView IBOutlet named "topBarView" and link it to the Main.storyboard's RootViewController's view, as seen below:

 ![topBarView](../images/tutorials-and-samples/iOS/GSDemo/topBarView.png)

 Then, create a property of type "GSButtonViewController" named **gsButtonVC** and implement GSButtonViewController's **GSButtonViewControllerDelegate** protocol within the class, as shown below:

~~~Swift
import Foundation
import UIKit
import MapKit
import CoreLocation
import DJISDK


class RootViewController : UIViewController, GSButtonViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate {
    var isEditingPoints = false
    var gsButtonVC : GSButtonViewController?

    ...
}
~~~

Furthermore, initialize the **gsButtonVC** property in the initUI method and move the original **focusMapAction** method's content to a new method named **focusMap**, as shown below:

~~~Swift
        self.gsButtonVC = GSButtonViewController()
        if let gsButtonVC = self.gsButtonVC {
            gsButtonVC.view.frame = CGRect(x: 0.0,
                                           y: self.topBarView.frame.origin.y + self.topBarView.frame.size.height,
                                           width: self.gsButtonVC!.view.frame.size.width,
                                           height: self.gsButtonVC!.view.frame.size.height)
            gsButtonVC.delegate = self
            self.view.addSubview(self.gsButtonVC!.view)
        }
~~~

~~~Swift
    func focusMap() {
        guard let droneLocation = self.droneLocation else {
            return
        }
        
        if CLLocationCoordinate2DIsValid(droneLocation) {
            let center = CLLocationCoordinate2D(latitude: droneLocation.latitude, longitude: droneLocation.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
~~~

Finally, implement **DJIGSButtonViewController**'s delegate methods, as shown below:

~~~Swift
    //MARK: - DJIGSButtonViewController Delegate Methods
    func stopBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.stopMission(completion: { (error:Error?) in
            if let error = error {
                let failedMessage = "Stop Mission Failed: \(error.localizedDescription)"
                showAlertWith(failedMessage)
            } else {
                showAlertWith("Stop Mission Finished")
            }
        })
    }
    
    func clearBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.mapController?.cleanAllPoints(with: self.mapView)
    }
    
    func focusMapBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.focusMap()
    }
    
    func startBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.startMission(completion: { (error:Error?) in
            if let error = error {
                showAlertWith("Start Mission Failed: \(error.localizedDescription)")
            } else {
                showAlertWith("Mission Started")
            }
        })
    }
    
    func add(button: UIButton, actionIn gsBtnVC: GSButtonViewController) {
        if self.isEditingPoints {
            self.isEditingPoints = false
            button.setTitle("Add", for: UIControl.State.normal)
        } else {
            self.isEditingPoints = true
            button.setTitle("Finished", for: UIControl.State.normal)
        }
    }
    
    func configBtnActionIn(gsBtnVC: GSButtonViewController) {
        guard let wayPoints = self.mapController?.editPoints else {
            showAlertWith("No waypoints")
            return
        }
        if wayPoints.count < 2 {
            showAlertWith("Not enough waypoints for mission")
            return
        }
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 1.0
        }

        self.waypointMission?.removeAllWaypoints()
        
        if self.waypointMission == nil {
            self.waypointMission = DJIMutableWaypointMission()
        }
        
        for location in wayPoints {
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                self.waypointMission?.add(DJIWaypoint(coordinate: location.coordinate))
            }
        }
        
    }

~~~

In the **switchToMode:inGSButtonVC:** delegate method, we call the **focusMap** method. By doing this, we can focus the map view to the aircraft's location when the edit button is pressed, making it user friendly by preventing the user from having to zoom in to edit. Moreover, the  **isEditingPoints** property value and the add button title will be updated in the **addBtn:withActionInGSButtonVC** method when the button is pressed.

Now, let's build and run the project and try to press the **Edit** and **Back** Buttons. Here are the animation when you press them:

![pressEditBtn](../images/tutorials-and-samples/iOS/GSDemo/pressEditBtn.gif)

## Configuring DJIWaypoint and DJIWaypointMission

### DJIWaypoint

Let's go to **DJIWaypoint.h** file and check it out. For example, you can use:

~~~Swift
-(id) initWithCoordinate:(CLLocationCoordinate2D)coordinate;
~~~
to create a waypoint object with a specific coordinate. Once you create a waypoint, you can add a **DJIWaypointAction** to it by calling:

~~~Swift
-(BOOL) addAction:(DJIWaypointAction*)action;
~~~

Moreover, with waypoints, you have the ability to set the coordinate, altitude, heading and much more. For more details, please check the **DJIWaypoint.h** header file.

### DJIWaypointMission

A DJIWaypointMission is used when you want to upload, start and stop a Waypoint Mission. You can add waypoints of type **DJIWaypoint** using the method:

~~~Swift
- (void)addWaypoint:(DJIWaypoint *_Nonnull)waypoint;
~~~

On the contrary, you can also delete waypoints from a task by using the method:

~~~Swift
- (void)removeWaypoint:(DJIWaypoint *_Nonnull)waypoint;
~~~

 Moreover, you can set the "finishedAction" property which is of **DJIWaypointMissionFinishedAction** enum type to configure what the aircraft does when the task is finished. Finally, you can set the **headingMode** property which is a **DJIWaypointMissionHeadingMode** enum type to configure what the aircraft's heading is while executing a task.

For more details, please check the **DJIWaypointMission.h** header file in the DJI Mobile SDK.

### Creating The DJIWaypointConfigViewController

For this demo, we will assume that the parameters of each waypoint being added to the map view are the same.

Now, let's create a new ViewController that will let the user to set the parameters of waypoints. Go to Xcode’s project navigator, right click on the **GSDemo** folder, select **New File...**, set its subclass to UIViewController, named it "DJIWaypointConfigViewController", and make sure "Also create XIB file" is selected. Next, open the DJIWaypointConfigViewController.xib file and implement the UI, as you see it below:

![wayPointConfig](../images/tutorials-and-samples/iOS/GSDemo/wayPointConfigureView.png)

In the Waypoint Configuration ViewController, we use a UITextField to let the user set the **altitude** property of a DJIWaypoint object. Then, we use two UITextField to let the user set the **maxFlightSpeed** and **autoFlightSpeed** properties of DJIWaypointMission. Next, there are two UISegmentedControls to configure the **finishedAction** property and the **headingMode** property of a DJIWaypointMission object.

At the bottom, we add two UIButtons for the **Cancel** and **Finish** actions. For more details about the settings, such as frame's position, frame's size, and background color of each UI element, please check the DJIWaypointConfigViewController.xib file in the downloaded project source code.

Now, let's create IBOutlets and IBActions for each of the UI elements in the WaypointConfigViewController.swift file, as shown below:

~~~Swift
import Foundation
import UIKit

protocol WaypointConfigViewControllerDelegate : AnyObject {
    func cancelBtnActionInDJIWaypointConfigViewController(viewController : WaypointConfigViewController)
    func finishBtnActionInDJIWaypointConfigViewController(viewController : WaypointConfigViewController)
}

class WaypointConfigViewController : UIViewController {
    @IBOutlet weak var altitudeTextField: UITextField!
    @IBOutlet weak var autoFlightSpeedTextField: UITextField!
    @IBOutlet weak var maxFlightSpeedTextField: UITextField!
    @IBOutlet weak var actionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var headingSegmentedControl: UISegmentedControl!

    weak var delegate : WaypointConfigViewControllerDelegate?
    
    init() {
        super.init(nibName: "WaypointConfigViewController", bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
    }

    func initUI() {
        self.altitudeTextField.text = "20" //Set the altitude to 20
        self.autoFlightSpeedTextField.text = "8" //Set the autoFlightSpeed to 8
        self.maxFlightSpeedTextField.text = "10" //Set the maxFlightSpeed to 10
        self.actionSegmentedControl.selectedSegmentIndex = 1 //Set the finishAction to DJIWaypointMissionFinishedGoHome
        self.headingSegmentedControl.selectedSegmentIndex = 0 //Set the headingMode to DJIWaypointMissionHeadingAuto
    }

    @IBAction func cancelBtnAction(_ sender: Any) {
        self.delegate?.cancelBtnActionInDJIWaypointConfigViewController(viewController:self)
    }

    @IBAction func finishBtnAction(_ sender: Any) {
        self.delegate?.finishBtnActionInDJIWaypointConfigViewController(viewController: self)
    }
}
~~~

In the code above, we create an **initUI** method, which is called in the viewDidload method, to initialize the UI controls with some default data. For example, we set the default text for the **altitudeTextField** to **100**, so there is no need for the user to type in a custom altitude value in the textField when the application is first opened. They will be able to press the **Finish** button right away instead of having to change the settings before they start.

## Implementing the DJIWaypoint Mission

### Adding the DJIWaypointConfigViewController to RootViewController

Now,let's go to RootViewController.m file, add the DJIWaypointConfigViewController.h header file at the top, and create a property of type **DJIWaypointConfigViewController** with the name "waypointConfigVC". Then, implement the DJIWaypointConfigViewControllerDelegate protocol, as shown below:

~~~Swift
class RootViewController : UIViewController, GSButtonViewControllerDelegate, WaypointConfigViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate {

    var isEditingPoints = false
    var gsButtonVC : GSButtonViewController?
    var waypointConfigVC : WaypointConfigViewController?

    ...
}
~~~

Next, let's add some code to initialize the **waypointConfigVC** instance variable and set its delegate as "RootViewController" at the bottom of the **initUI** method:

~~~Swift
    func initUI() {
        self.modeLabel.text = "N/A"
        self.gpsLabel.text = "0"
        self.vsLabel.text = "0.0 M/S"
        self.hsLabel.text = "0.0 M/S"
        self.altitudeLabel.text = "0 M"
        
        self.gsButtonVC = GSButtonViewController()
        if let gsButtonVC = self.gsButtonVC {
            gsButtonVC.view.frame = CGRect(x: 0.0,
                                           y: self.topBarView.frame.origin.y + self.topBarView.frame.size.height,
                                           width: self.gsButtonVC!.view.frame.size.width,
                                           height: self.gsButtonVC!.view.frame.size.height)
            gsButtonVC.delegate = self
            self.view.addSubview(self.gsButtonVC!.view)
        }

        self.waypointConfigVC = WaypointConfigViewController()

        self.waypointConfigVC?.view.alpha = 0
        self.waypointConfigVC?.view.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        self.waypointConfigVC?.view.center = self.view.center
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            self.waypointConfigVC?.view.center = self.view.center
        }
        
        self.waypointConfigVC?.delegate = self
        if let _ = self.waypointConfigVC {
            self.view.addSubview(self.waypointConfigVC!.view)
        }
    }
~~~

In the code above, we set the **alpha** property of the **waypointConfigVC**'s view to 0 to initially hide the view. Then, center its location to the center of RootViewController's view when it runs on iPad.

Furthermore, implement the **WaypointConfigViewControllerDelegate** methods, as shown below:

~~~Swift
    //MARK - WaypointConfigViewControllerDelegate Methods

    func cancelBtnActionInDJIWaypointConfigViewController(viewController: WaypointConfigViewController) {
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 0
        }
    }

    func finishBtnActionInDJIWaypointConfigViewController(viewController: WaypointConfigViewController) {
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 0
        }
    }
~~~

In the first delegate method, we use a class method from UIView to animate the changing **alpha** value of **waypointConfigVC**'s view:

~~~Swift
    open class func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void)
~~~

In the second delegate method, we do the same thing as we did in the first delegate method.

Lastly, replace the code in the **configBtnActionInGSButtonVC:** method with the following code to show the **waypointConfigVC**'s view when the user presses the **Config** button:

~~~Swift
    func configBtnActionIn(gsBtnVC: GSButtonViewController) {
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 1.0
        }
    }
~~~

Once that's done, let's build and run the project. Try to show the **waypointConfigVC**'s view by pressing the **Edit** button and **Config** button:

![waypointConfigView](../images/tutorials-and-samples/iOS/GSDemo/waypointConfigView.png)

### Handling The DJIWaypoint Mission

Now let's go back to RootViewController.swift file. Create a property of type **DJIMutableWaypointMission** and named it as "waypointMission" as shown below:

~~~Swift
    var waypointMission : DJIMutableWaypointMission?
~~~

We use **DJIMutableWaypointMission** here since it represents a waypoint mission that can be changed by modifying its parameters.

Next, replace the code in **configBtnActionInGSButtonVC** delegate method with the following:

~~~Swift
    func configBtnActionIn(gsBtnVC: GSButtonViewController) {
        guard let wayPoints = self.mapController?.editPoints else {
            showAlertWith("No waypoints")
            return
        }
        if wayPoints.count < 2 {
            showAlertWith("Not enough waypoints for mission")
            return
        }
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 1.0
        }

        self.waypointMission?.removeAllWaypoints()
        
        self.waypointMission = self.waypointMission ?? DJIMutableWaypointMission()
        
        for location in wayPoints {
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                self.waypointMission?.add(DJIWaypoint(coordinate: location.coordinate))
            }
        }
    }
~~~

In the code above, we create a local array named **wayPoints** and assign its value as the mapController's **wayPoints** array. Next, check whether or not the array exists or whether or not it's empty. If it is empty or does not exist, show a UIAlertView letting the user know there are no waypoints for the mission.

**Important**: For safety, it's important to add logic to check the GPS satellite count, before the start of the mission. If the satellite count is less than 6, you should prevent the user from starting the waypoint mission and show a warning. Since we are using the DJI Assistant 2 Simulator here, we are testing the application under a perfect situation, where the GPS satellite count is always 10.

Next, we use a for loop to get the **CLLocation** for each waypoint from the **wayPoints** array and check if its **coordinate** is valid by using the method:

~~~Swift
public func CLLocationCoordinate2DIsValid(_ coord: CLLocationCoordinate2D) -> Bool
~~~

Finally, if the coordinate is valid, we create a waypoint of type **DJIWaypoint** and add it to the **waypointMission**.

Once that is complete, let's create a `missionOperator` method and go to WaypointConfigViewController's delegate method **finishBtnActionInDJIWaypointConfigViewController** and replace the code inside with the followings:

~~~Swift
    func missionOperator() -> DJIWaypointMissionOperator? {
        return DJISDKManager.missionControl()?.waypointMissionOperator()
    }

    func showAlertViewWith(title:String, message:String?) {
        let alert = UIAlertController(title: title, message: message ?? "", preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func finishBtnActionInDJIWaypointConfigViewController(viewController: WaypointConfigViewController) {
        
        UIView.animate(withDuration: 0.25) { [weak self] () in
            self?.waypointConfigVC?.view.alpha = 0
        }
        
        if let waypointMission = self.waypointMission, let waypointConfigVC = self.waypointConfigVC {
            for waypoint in waypointMission.allWaypoints() {
                let altitude = Float(waypointConfigVC.altitudeTextField.text ?? "20") ?? 20.0
                waypoint.altitude = altitude
            }
        }

        if let waypointConfigVC = self.waypointConfigVC {
            self.waypointMission?.maxFlightSpeed = ((self.waypointConfigVC?.maxFlightSpeedTextField.text ?? "0.0") as NSString).floatValue
            self.waypointMission?.autoFlightSpeed = ((self.waypointConfigVC?.autoFlightSpeedTextField.text ?? "0.0") as NSString).floatValue
            
            let selectedHeadingIndex = waypointConfigVC.headingSegmentedControl.selectedSegmentIndex
            self.waypointMission?.headingMode = DJIWaypointMissionHeadingMode(rawValue:UInt(selectedHeadingIndex)) ?? DJIWaypointMissionHeadingMode.auto
            
            let selectedActionIndex = waypointConfigVC.actionSegmentedControl.selectedSegmentIndex
            self.waypointMission?.finishedAction = DJIWaypointMissionFinishedAction(rawValue: UInt8(selectedActionIndex)) ?? DJIWaypointMissionFinishedAction.noAction
        }
        
        if let waypointMission = self.waypointMission {
            self.missionOperator()?.load(waypointMission)
            
            self.missionOperator()?.addListener(toFinished: self, with: DispatchQueue.main, andBlock: { [weak self] (error: Error?) in
                if let error = error {
                    self?.showAlertViewWith(title: "Mission Execution Failed", message: error.localizedDescription)
                } else {
                    self?.showAlertViewWith(title: "Mission Execution Finished", message: nil)
                }
            })
        }
        
        self.missionOperator()?.uploadMission(completion: { (error:Error?) in
            if let error = error {
                let uploadErrorString = "Upload Mission failed:\( error.localizedDescription)"
                showAlertWith(uploadErrorString)
            } else {
                showAlertWith("Upload Mission Finished")
            }
        })
    }
~~~

Above, we use a for loop to set the **altitude** property of each DJIWaypoint in the **waypointMission** waypoint array based on the settings that are set in the DJIWaypointConfigViewController. After that is complete, we update the "maxFlightSpeed", "autoFlightSpeed", "headingMode" and "finishedAction" properties of **waypointMission**. Then we invoke the `loadMission:` method of **DJIWaypointMissionOperator** to load the `waypointMission` into the operator.

Furthermore, invoke the `addListenerToFinished:withQueue:andBlock` method of **DJIWaypointMissionOperator** and implement its block to inform the user by showing an alert view when the waypoint mission is finished.

Lastly, we call the `uploadMissionWithCompletion:` method of **DJIWaypointMissionOperator** to upload the waypoint mission for execution and show result messages.

Once you finished the above step, let's implement the `startBtnActionInGSButtonVC` method  as shown below:

~~~Swift
    func startBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.startMission(completion: { (error:Error?) in
            if let error = error {
                showAlertWith("Start Mission Failed: \(error.localizedDescription)")
            } else {
                showAlertWith("Mission Started")
            }
        })
    }
~~~

Here, call the `startMissionWithCompletion:` method of DJIWaypointMissionOperator to start the DJIWaypoint mission! Then create a UIAlertView to display error message when start mission failed.

Finally, let's implement the **stopMissionExecutionWithCompletion** method of DJIMissionControl in the **GSButtonViewController** delegate method to stop the waypoint mission, as shown below:

~~~Swift
    func stopBtnActionIn(gsBtnVC: GSButtonViewController) {
        self.missionOperator()?.stopMission(completion: { (error:Error?) in
            if let error = error {
                let failedMessage = "Stop Mission Failed: \(error.localizedDescription)"
                showAlertWith(failedMessage)
            } else {
                showAlertWith("Stop Mission Finished")
            }
        })
    }
~~~

## Showtime

You've come a long way in this tutorial, and it's time to test the whole application.

**Important**: Make sure the battery level of your aircraft is more than 10%, otherwise the waypoint mission may fail!

Build and run the project to install the application into your mobile device. After that, please connect the aircraft to your Mac via a Micro USB cable. Then, power on the remote controller and the aircraft, in that order.

Next, press the **Simulator** button in the DJI Assistant 2 and feel free to type in your current location's latitude and longitude data into the simulator.

![simulatorPreview](../images/tutorials-and-samples/iOS/GSDemo/simulator_preview.png)

Next, let's come back to the DJI Assistant 2 Simulator on your Mac and press the **Start Simulation** button. A tiny red aircraft will appear on the map in your application, as seen below:

![aircraftOnMap](../images/tutorials-and-samples/iOS/GSDemo/aircraftOnMap.png)

Press the **Edit** button, and the map view will zoom in to the region you are in and will center the aircraft:

![locateAircraft](../images/tutorials-and-samples/iOS/GSDemo/locateTheAircraft.gif)

Next, test the waypoint feature by tapping wherever you'd like on the map view. Wherever you do tap, a waypoint will be added and a purple pin will appear exactly at the location of the waypoint, as shown below:

![addWayPoints](../images/tutorials-and-samples/iOS/GSDemo/addWaypoints_Action.gif)

Once you press the **Config** button, the **Waypoint Configuration** view will appear. After you're satisfied with the changes, press the **Finish** button. The waypoint mission will start to prepare. Then press the **Start** button to start the waypoint mission execution. Now you will should see the aircraft move towards the waypoints you set previously on the map view, as shown below:

![flyTowards](../images/tutorials-and-samples/iOS/GSDemo/startFlying.gif)

At the same time, you will be able to see the Mavic Pro take off and start to fly in the DJI Assistant 2 Simulator.

![takeOff](../images/tutorials-and-samples/iOS/GSDemo/takeOff.gif)

When the waypoint mission finishes, the Mavic Pro will start to go home!

![goHome](../images/tutorials-and-samples/iOS/GSDemo/goHome.gif)

The remote controller will start beeping. Let's take a look at the DJI Assistant 2 Simulator now:

![landing](../images/tutorials-and-samples/iOS/GSDemo/landing.gif)

The Mavic Pro will eventually go home, land, and the beeping from the remote controller will stop. The application will go back to its normal status. If you press the **Clear** button, all the waypoints you previously set will be cleared. During the mission, if you'd ever like to stop the DJIWaypoint mission, you can do so by pressing the **Stop** button.

### Summary

   In this tutorial, you’ve learned how to setup and use the DJI Assistant 2 Simulator to test your waypoint mission application, upgrade your aircraft's firmware to the developer version, use the DJI Mobile SDK to create a simple map view, modify annotations of the map view, show the aircraft on the map view by using GPS data from the DJI Assistant 2 Simulator. Next, you learned how to configure **DJIWaypoint** parameters, how to add waypoints to **DJIMutableWaypointMission**. Moreover, you learned how to use DJIMissionControl to **prepare**, **start** and **stop** missions.

   Congratulations! Now that you've finished the demo project, you can build on what you've learned and start to build your own waypoint mission application. You can improve the method which waypoints are added(such as drawing a line on the map and generating waypoints automatically), play around with the properties of a waypoint (such as heading, etc.), and adding more functionality. In order to make a cool waypoint mission application, you still have a long way to go. Good luck and hope you enjoy this tutorial!
