---
title: DJI GEO System Tutorial (Swift)
version: v4.14
date: 2021-6-03
github: https://github.com/godfreynolan/GeoDemoSwift
keywords: [iOS GEODemo, GEO System, Fly Zone, Unlock, Authorization Fly Zone, NFZ, Swift]
---

*If you come across any mistakes in this tutorial feel free to open Github pull requests.*

---

In this tutorial, you will learn how to use the `DJIFlyZoneManager` and `DJIFlyZoneInformation` of DJI Mobile SDK to get the fly zone information, and unlock authorization fly zones.

You can download the tutorial's final sample project from this [Github Page](https://github.com/godfreynolan/GeoDemoSwift).

See [this Github Page](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-GEODemo) for an Objective C version. 

We used a Mavic Pro to make this demo. Let's get started!

## Introduction

The [Geospatial Environment Online (GEO) system](http://www.dji.com/flysafe/geo-system) is a best-in-class geospatial information system that provides drone operators with information that will help them make smart decisions about where and when to fly. It combines up-to-date airspace information, a warning and flight-restriction system, a mechanism for [unlocking](https://fly-safe.dji.com/unlock/unlock-request/list) (self-authorizing) drone flights in locations where flight is permitted under certain conditions, and a minimally-invasive accountability mechanism for these decisions.

## Application Activation and Aircraft Binding in China

 For DJI SDK mobile application used in China, it's required to activate the application and bind the aircraft to the user's DJI account. 

 If an application is not activated, the aircraft not bound (if required), or a legacy version of the SDK (< 4.1) is being used, all **camera live streams** will be disabled, and flight will be limited to a zone of 100m diameter and 30m height to ensure the aircraft stays within line of sight.

 To learn how to implement this feature, please check this tutorial [Application Activation and Aircraft Binding](./ActivationAndBinding.md).

## Implementing the UI of the Application

### Importing SDK and Register Application

Now, let's create a new project in Xcode, choose the **App** template for your project and press "Next", enter "DJIGeoSample" for **Product Name** and make sure Interface is Storyboard and Language is Swift. 

Once the project is created, let's delete the **ViewController.swift file, which was created by Xcode when you created the project. Then create a UIView Controller named **RootViewController** and set the class of original ViewController object in the storyboard to "RootViewController".

Next, let's import the **MapKit.framework** and **DJISDK.framework** to the project and implement the registration process in the **RootViewController**. If you are not familiar with the process of importing and activating DJI SDK, please check this tutorial: [Importing and Activating DJI SDK in Xcode Project](../application-development-workflow/workflow-integrate.md#Xcode-Project-Integration) for details.

### Working on the UI of Application

#### Creating the UI of RootViewController 

Let's open the "Main.storyboard" and make the **RootViewController** embed in a Navigation Controller and set it as the Storyboard Entry Point. Next, drag and drop two UILabel objects to the RootViewController and named them as "Product Connection Status" and "Model: Not Available". Moreover, drag and drop a UIButton object and place under the two UILabels, named it as "Open", then set its background image as "btn.png" file, which you can get it from the tutorial's Github Sample Project. Lastly, setup the UI elements' auto layout to support multiple device screen size.

#### Creating the UI of GeoDemoViewController

Drag and drop another ViewController object from the Object Library to the right of **RootViewController** in the storyboard. Set its class name to GeoDemoViewController. Then create a swift file called "GeoDemoViewController.swift" where you'll define a UIViewController class called "GeoDemoViewController". 

Put a **Map View** in the ViewController and set its size to the ViewController view's size. 

Drag and drop 7 UIButtons to the upper left side of GeoDemoViewController. Name them "Login", "Logout", "Unlock", "GetUnlock", "Start Simulator", "Stop Simulator" and "EnableGEO". Then drag and drop two UILabels and place them on the right of the 7 UIButton objects and set their text to "LoginState" and "Unknown FlyZone Status". Furthermore, drag and drop a UITableView under the two UILabels and set its data source and delegate to **GeoDemoViewController**. Lastly, drag and drop a Picker View and two UIButtons inside a new UIView at the bottom. For more detail configurations of the storyboard, please check the Github sample project. Your storyboard should look like the following screenshot:

![](../images/tutorials-and-samples/iOS/GEODemo/GEODemoStoryboard.png)

## Working on RootViewController

Let's open RootViewController.swift and create IBOutlets to link the UI elements in the storyboard and an instance variable to hold the most recent DJIProduct. 

~~~swift
    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    var product : DJIBaseProduct?
~~~

Then add the following method to update the two UILabel objects' content when the product connection updates: 

~~~swift
    func updateStatusFor(_ product:DJIBaseProduct?) {
        if let product = product {
            self.connectStatusLabel.text = "Status: Product Connected"
            self.modelNameLabel.text = "Model: \(product.model ?? "Unknown")"
            self.modelNameLabel.isHidden = false
        } else {
            self.connectStatusLabel.text = "Status: Product Not Connected"
            self.modelNameLabel.text = "Model: Unknown"
        }
    }
~~~

Next, invoke the above method in `viewDidAppear` and `productConnected:` as shown below:

~~~swift
    override func viewDidAppear(_ animated: Bool) {
        if let product = self.product {
            self.updateStatusFor(product)
        }
    }
~~~

~~~swift
    func productConnected(_ product: DJIBaseProduct?) {
        
        ...

        self.updateStatusFor(product)
    }
~~~

For more details of the implementation of RootViewController, please check the tutorial's Github sample project.

## Implementing Annotation and Overlay on Map View

### Working on Aircraft Annotation

Let's add the aircraft annotation on the map to show its position when we are testing the GEO system.

First, create a subclass of NSObject called "AircraftAnnotation":

- AircraftAnnotation.swift

~~~swift
import Foundation
import MapKit

class AircraftAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var annotationView : AircraftAnnotationView?
    
    init(coordinate:CLLocationCoordinate2D, heading:Float) {
        self.coordinate = coordinate
        self.annotationView?.update(heading: heading)
        super.init()
    }
}
~~~

In the code above, we implement the **MKAnnotation** protocol and declare a property of CLLocationCoordinate2D object **coordinate**, which will be used to store the coordinate data. Then declare a CGFloat property **heading**, and use it to store the heading value of the aircraft.  

Then implement the `init(coordinate:, heading:)` method. 

Once you finish it, let's create a class named "AircraftAnnotationView", which is a subclass of **MKAnnotationView**, and replace the content with the following:

- AircraftAnnotationView.swift

~~~swift
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

In the code above, we first implement the `init(annotation:, reuseIdentifier:)` method for initialization and create the `updateHeading:` method to update the heading of the aircraft annotation view.

For the "aircraft.png" file, please get it from this tutorial's Github sample project and put it in the **Assets.xcassets**.

### Working on FlyZone Circle Overlay

Now, let's add circle overlay with different colors and polygon overlay to represent Fly Zones on the map view. 

Create an MKCircle class named "DJIFlyZoneCircle" and implement its header file as shown below:

- FlyZoneCircle.swift

~~~swift
import Foundation
import MapKit
import DJISDK

class FlyZoneCircle : MKCircle {
     public var flyZoneCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
     public var flyZoneRadius : CGFloat = 0.0
     public var category = DJIFlyZoneCategory.unknown
     public var flyZoneID : UInt = 0
     public var name : String?
     public var heightLimit : CGFloat = 0.0
}
~~~

In the code above, we declare the following variables:

1. **flyZoneCoordinate** property is used to store the coordinate data of the fly zone circle
2. **flyZoneRadius** property is used to store the radius of the fly zone circle in meters
3. **category** property is used to store the category of the fly zone circle
4. **flyZoneID** property is used to store the fly zone's identifier, which is required in the unlock process
5. **name** property is used to store the name of the fly zone.

We'll be using a variety of colors to indicate different fly zones. Let's define them all in one place:

- FlyZoneColorProvider.swift

~~~swift
import Foundation
import DJISDK

extension UIColor {
    convenience init(r: CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
}

//0x979797
fileprivate let heightLimitGrayColorClear = UIColor(r: 151, g: 151, b: 151, a: 0.1)
fileprivate let heightLimitGrayColorSolid = UIColor(r: 151, g: 151, b: 151, a: 1)

//0xDE4329
fileprivate let heightLimitRedColorClear = UIColor(r: 222, g: 67, b: 41, a: 0.1)
fileprivate let heightLimitRedColorSolid = UIColor(r: 222, g: 67, b: 41, a: 1)

//0x1088F2
fileprivate let heightLimitBlueColorClear = UIColor(r: 16, g: 136, b: 242, a: 0.1)
fileprivate let heightLimitBlueColorSolid = UIColor(r: 16, g: 136, b: 242, a: 1)

//0xFFCC00
fileprivate let flySafeWarningYellowColorClear = UIColor(r: 255, g: 204, b: 0, a: 0.1)
fileprivate let flySafeWarningYellowColorSolid = UIColor(r: 255, g: 204, b: 0, a: 1)

//0xEE8815
fileprivate let flysafeWarningColorYellowClear = UIColor(r: 238, g: 238, b: 136, a: 0.1)
fileprivate let flysafeWarningColorYellowSolid = UIColor(r: 238, g: 238, b: 136, a: 1)

class FlyZoneColorProvider {
    
    class func getFlyZoneOverlayColorFor(category: DJIFlyZoneCategory, isHeightLimit: Bool, isFill:Bool) -> UIColor {
        if isHeightLimit {
            return isFill ? heightLimitGrayColorClear : heightLimitGrayColorSolid
        }
        
        switch category {
        case .authorization:
            return isFill ? heightLimitBlueColorClear : heightLimitBlueColorSolid
        case .restricted:
            return isFill ? heightLimitRedColorClear : heightLimitRedColorSolid
        case .warning:
            return isFill ? flySafeWarningYellowColorClear : flySafeWarningYellowColorSolid
        case .enhancedWarning:
            return isFill ? flysafeWarningColorYellowClear : flysafeWarningColorYellowSolid
        case .unknown:
            return UIColor(r: 0, g: 0, b: 0, a: 0)
        @unknown default:
            fatalError()
        }
    }
    
}
~~~

Next, let's create the **FlyZoneCircleView** class, which is a subclass of MKCircleRenderer, and replace the code with the following:

- FlyZoneCircleView.swift

~~~swift
import Foundation
import MapKit

class FlyZoneCircleView : MKCircleRenderer {
    init(circle: FlyZoneCircle) {
        super.init(circle: circle as MKCircle)
        self.fillColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: circle.category,
                                                                        isHeightLimit: false,
                                                                        isFill: true)
        self.strokeColor = FlyZoneColorProvider.getFlyZoneOverlayColorFor(category: circle.category,
                                                                          isHeightLimit: false,
                                                                          isFill: false)
        self.lineWidth = 1.0
    }
}
~~~

In the code above, we implement the following feature:

**1.** In the header file, we declare the `initWithCircle:` method for initialization.

**2.** Then we implement the `initWithCircle:` method by setting the `fillColor` and `strokeColor` of **MKCircleRenderer** based on the `category` property value of "DJIFlyZoneCircle":

- Authorization Fly Zone (Yellow Color)
- Restricted Fly Zone (Red Color)
- Warning Fly Zone (Green Color)
- Enhanced Warning Fly Zone (Green Color)

**3.** Finally, assign the `lineWidth` property of **MKCircleRenderer** to "1.0f" to set the fly zone circle's width. 

So far, we have finished implementing the aircraft annotation and fly zone overlay.

You'll also need to copy these classes from this tutorial's Github sample project:
- FlyLimitPolygonView
- Polygon
- LimitSpaceOverlay
- MapOverlay
- Circle
- MapPolygon
- CustomUnlockOverlay

Now, let's continue to implement the MapController to add the fly zone overlays and subOverlays to the Map View.

## Implementing MapController

### Adding and Updating Aircraft Annotation on the Map View

  Here, we need to create a Map Controller to show the map and draw the fly zone circles and aircraft on it. Now create a new file called "MapController.swift" and implement "MapController" like so:

~~~swift
//
//  MapViewController.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 5/4/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import DJISDK

let kUpdateTimeStamp = 10.0


class MapController : NSObject, MKMapViewDelegate {
    
    var flyZones = [DJIFlyZoneInformation]()
    var aircraftCoordinate : CLLocationCoordinate2D
    var mapView : MKMapView
    var aircraftAnnotation : AircraftAnnotation?
    var mapOverlays = [MapOverlay]()
    var customUnlockOverlays = [MapOverlay]()
    var lastUpdateTime = Date.timeIntervalSinceReferenceDate
    
    public init(map: MKMapView) {
        self.aircraftCoordinate = CLLocationCoordinate2DMake(0.0, 0.0)
        self.mapView = map
        
        super.init()
        
        self.mapView.delegate = self
        self.updateFlyZonesInSurroundingArea()
    }
    
    deinit {
        self.aircraftAnnotation = nil
        self.mapView.delegate = nil
    }
    
    public func updateAircraft(coordinate:CLLocationCoordinate2D, heading:Float) {
        if CLLocationCoordinate2DIsValid(coordinate) {
            self.aircraftCoordinate = coordinate
            if let _ = self.aircraftAnnotation {
                self.aircraftAnnotation?.coordinate = coordinate
                let annotationView = (self.mapView.view(for: self.aircraftAnnotation!)) as? AircraftAnnotationView
                annotationView?.update(heading: heading)
            } else {
                let aircraftAnnotation = AircraftAnnotation(coordinate: coordinate, heading: heading)
                self.aircraftAnnotation = aircraftAnnotation
                self.mapView.addAnnotation(aircraftAnnotation)
                let viewRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                let adjustedRegion = self.mapView.regionThatFits(viewRegion)
                self.mapView.setRegion(adjustedRegion, animated: true)
            }
            self.updateFlyZones()
        }
    }
    
    //MARK: - MKMapViewDelegate Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) { return nil }
        if annotation.isKind(of: AircraftAnnotation.self) {
            let aircraftAnno = self.mapView.dequeueReusableAnnotationView(withIdentifier: "DJI_AIRCRAFT_ANNOTATION_VIEW")
            return aircraftAnno ?? AircraftAnnotationView(annotation: annotation, reuseIdentifier: "DJI_AIRCRAFT_ANNOTATION_VIEW")
            
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? FlyZoneCircle {
            return FlyZoneCircleView(circle: overlay)
        } else if let polygon = overlay as? Polygon {
            return FlyLimitPolygonView(polygon: polygon)
        } else if let polygon = overlay as? MapPolygon {
            let polygonRender = MKPolygonRenderer(polygon: polygon)
            polygonRender.strokeColor = polygon.strokeColor
            polygonRender.lineWidth = CGFloat(polygon.lineWidth)
            polygonRender.lineDashPattern = polygon.lineDashPattern
            if let polygonLineJoin = polygon.lineJoin {
                polygonRender.lineJoin = polygonLineJoin
            }
            if let polygonLineCap = polygon.lineCap {
                polygonRender.lineCap = polygonLineCap
            }
            polygonRender.fillColor = polygon.fillColor
            return polygonRender
        } else if let circle = overlay as? Circle {
            let circleRenderer = MKCircleRenderer(circle: circle)
            circleRenderer.strokeColor = circle.strokeColor
            circleRenderer.lineWidth = CGFloat(circle.lineWidth)
            circleRenderer.fillColor = circle.fillColor
            return circleRenderer;
        }
        fatalError("error generating overlay renderer")
    }

    //MARK: - Update Fly Zones in Surrounding Area
    func updateFlyZones() {
        if self.canUpdateLimitFlyZoneWithCoordinate() {
            self.updateFlyZonesInSurroundingArea()
            self.updateCustomUnlockZone()
        }
    }
    
    func canUpdateLimitFlyZoneWithCoordinate() -> Bool {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if (currentTime - self.lastUpdateTime) < kUpdateTimeStamp {
            return false
        }
        self.lastUpdateTime = currentTime
        return true
    }
    
    public func updateFlyZonesInSurroundingArea() {
        DJISDKManager.flyZoneManager()?.getFlyZonesInSurroundingArea(completion: { [weak self] (flyZones:[DJIFlyZoneInformation]?, error:Error?) in
            if let flyZones = flyZones, error == nil {
                self?.updateFlyZoneOverlayWith(flyZones)
            } else {
                if let mapOverlays = self?.mapOverlays {
                    if mapOverlays.count > 0 {
                        self?.remove(mapOverlays)
                    }
                }
                if let flyZones = self?.flyZones {
                    if flyZones.count > 0 {
                        self?.flyZones.removeAll()
                    }
                }
            }
        })
    }
    
    func updateFlyZoneOverlayWith(_ flyZones:[DJIFlyZoneInformation]?) {
        guard let flyZones = flyZones, flyZones.count > 0 else { return }
        let updateOverlaysClosure = {
            var overlays = [LimitSpaceOverlay]()
            var limitFlyZones = [DJIFlyZoneInformation]()
            
            for flyZone in flyZones {
                var anOverlay : LimitSpaceOverlay?
                for aMapOverlay in self.mapOverlays as! [LimitSpaceOverlay] {
                    if (aMapOverlay.limitSpaceInfo.flyZoneID == flyZone.flyZoneID) && (aMapOverlay.limitSpaceInfo.subFlyZones?.count == flyZone.subFlyZones?.count) {
                        anOverlay = aMapOverlay
                        break
                    }
                }
                overlays.append(anOverlay ?? LimitSpaceOverlay(limitSpaceInfo: flyZone))
                limitFlyZones.append(flyZone)
            }

            self.remove(self.mapOverlays)
            self.flyZones.removeAll()
            self.add(overlays)
            self.flyZones.append(contentsOf: limitFlyZones)
        }
        
        if Thread.current.isMainThread {
            updateOverlaysClosure()
        } else {
            DispatchQueue.main.sync {
                updateOverlaysClosure()
            }
        }
    }
    
    func updateCustomUnlockZone() {
        if let zones = DJISDKManager.flyZoneManager()?.getCustomUnlockZonesFromAircraft() {
            if zones.count > 0 {
                DJISDKManager.flyZoneManager()?.getEnabledCustomUnlockZone(completion: { [weak self] (zone:DJICustomUnlockZone?, error:Error?) in
                    if let zone = zone, error == nil {
                        self?.updateCustomUnlockWith(spaceInfos: [zone], enabledZone: zone)
                    }
                })
            } else {
                removeCustomUnlocks()
            }
        }
    }
    
    func removeCustomUnlocks() {
        if self.customUnlockOverlays.count > 0 {
            self.remove(self.customUnlockOverlays)
        }
    }
    
    func updateCustomUnlockWith(spaceInfos:[DJICustomUnlockZone]?, enabledZone:DJICustomUnlockZone) {
        guard let spaceInfos = spaceInfos, spaceInfos.count <= 0 else { return }
        var overlays = [CustomUnlockOverlay]()
        for spaceInfo in spaceInfos {
            var anOverlay : CustomUnlockOverlay?
            for aCustomUnlockOverlay in self.customUnlockOverlays {
                if let aCustomUnlockOverlay = aCustomUnlockOverlay as? CustomUnlockOverlay {
                    if aCustomUnlockOverlay.customUnlockInformation == spaceInfo {
                        anOverlay = aCustomUnlockOverlay
                        break
                    }
                }
                if let anOverlay = anOverlay {
                    overlays.append(anOverlay)
                } else {
                    let enabled = (spaceInfo === enabledZone)
                    overlays.append(CustomUnlockOverlay(customUnlockInformation: spaceInfo,
                                                        isEnabled: enabled))
                }
            }
            self.remove(customUnlockOverlays: self.customUnlockOverlays)
            self.add(customUnlockOverlays: overlays)
        }
    }
    
    func add(_ mapOverlays:[MapOverlay]) {
        if mapOverlays.count <= 0 { return }
        let overlays = self.subOverlaysFor(mapOverlays)
        self.performOnMainThread {
            self.mapOverlays.append(contentsOf: mapOverlays)
            self.mapView.addOverlays(overlays)
        }
    }
    
    func remove(_ mapOverlays:[MapOverlay]) {
        if mapOverlays.count <= 0 { return }
        
        self.performOnMainThread {
            self.mapOverlays.removeAll(where: { mapOverlays.contains($0) } )
            self.mapView.removeOverlays(self.subOverlaysFor(mapOverlays))
        }
    }
    
    func add(customUnlockOverlays:[MapOverlay]) {
        if customUnlockOverlays.count <= 0 { return }
        
        let overlays = self.subOverlaysFor(customUnlockOverlays)
        self.performOnMainThread {
            self.customUnlockOverlays.append(contentsOf: customUnlockOverlays)
            self.mapView.addOverlays(overlays)
        }
    }
    
    func remove(customUnlockOverlays:[MapOverlay]) {
        if customUnlockOverlays.count <= 0 { return }

        let overlays = self.subOverlaysFor(customUnlockOverlays)
        self.performOnMainThread {
            self.customUnlockOverlays.removeAll(where: { customUnlockOverlays.contains($0) })
            self.mapView.removeOverlays(overlays)
        }
    }
    
    func subOverlaysFor(_ overlays:[MapOverlay]) -> [MKOverlay] {
        var subOverlays = [MKOverlay]()
        for aMapOverlay in overlays {
            subOverlays.append(contentsOf: aMapOverlay.subOverlays)
        }
        return subOverlays
    }
    
    func performOnMainThread(closure: @escaping () -> ()) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }

    func refreshMapViewRegion() {
        let viewRegion = MKCoordinateRegion(center: self.aircraftCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        let adjustedRegion = self.mapView.regionThatFits(viewRegion)
        self.mapView.setRegion(adjustedRegion, animated: true)
    }
}

~~~

In the code above, we implement the following features:

1. Create an NSMutableArray property named `flyZones` to store `DJIFlyZoneInformation` objects.
2. Create a **CLLocationCoordinate2D** property, a **AircraftAnnotation** property and a **MKMapView** property, then implement the **MKMapViewDelegate** protocol
3. Create the initialization method `initWithMap:` for DJIMapViewController
4. Create the `updateAircraft(coordinate:CLLocationCoordinate2D, heading:Float)` method to update the aircraft's location and heading on the map view
5. Add the `refreshMapViewRegion` method to refresh the map view's region
6. Add the `updateFlyZonesInSurroundingArea` method to update the fly zones in the surrounding area of aircraft;
7. Add the `fetchUpdateFlyZoneInfo` method to fetch the updated fly zone info strings. 
8. In the `initWithMap:` method, we initialize the DJIMapViewController by passing the **MKMapView** object "mapView", then store it to the `mapView` property and set the `mapView`'s delegate to DJIMapViewController.
9. In the `updateAircraft(coordinate:CLLocationCoordinate2D, heading:Float)` method, we first check if the `coordinate` is valid, then update the `aircraftCoordinate` property. If the `aircraftAnnotation` property is nil, invoke the `initWithCoordinate:heading:` method of **AircraftAnnotation** to create it, then invoke the **MKMapView**'s `addAnnotation:` method to add the aircraft annotation on the map. Lastly, adjust the map view's region by invoking the `setRegion:animated:` method.
10. If the `aircraftAnnotation` property is not nil, then update its coordinate and the heading of the aircraft annotation view.
11. In the `updateFlyZonesInSurroundingArea()` method, we invoke the `getFlyZonesInSurroundingAreaWithCompletion:` method of **DJIFlyZoneManager** to get all the fly zones within 20km of the aircraft. Then in the completion method, if it gets the `flyZones` array successfully, we invoke the `updateFlyZoneOverlayWith(_ flyZones:)` method to update the fly zone overlays on the map view. Otherwise, remove the map overlays on the map view and clean up the `flyZones` array.
12. In the `updateFlyZoneOverlayWith(_ flyZones:)` method, we first create the `overlays` and `flyZones` arrays to store the `DJILimitSpaceOverlay` and `DJIFlyZoneInformation` objects. Next, use a **for** loop to get the `DJILimitSpaceOverlay` and `DJIFlyZoneInformation` objects and store in the arrays. 
13. Remove the fly zone overlays on the map by invoking the `remove(_ mapOverlays:)` method first and remove objects in the `flyZones` array. Then
invoke the `addMapOverlays` methods to new `DJILimitSpaceOverlay` fly zone overlays on the map and add new `DJIFlyZoneInformation` objects in the `flyZones` array.
14. Implement the `refreshMapViewRegion()` method.
15. Invoke the `setRegion:animated:` method of MKMapView to update the region on the map view when the aircraft coordinate changes.

For more details, please check the **MapController** class in this tutorial's Github sample code.

### Implementing DemoUtility

Before implementing the **GeoDemoViewController**, let's implement some common methods in **DemoUtility**. Create helper methods as shown below:

- DemoUtility.swift

~~~swift
import Foundation
import DJISDK

func showAlertWith(result:String) {
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    showAlertWith(title: nil, message: result, cancelAction: nil, defaultAction: okAction, presentingViewController: nil)
}

func showAlertWith(title: String?, message: String, cancelAction:UIAlertAction?, defaultAction:UIAlertAction?, presentingViewController:UIViewController?) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let defaultAction = defaultAction {
            alertController.addAction(defaultAction)
        }
        if let cancelAction = cancelAction {
            alertController.addAction(cancelAction)
        }
        if let presentingViewController = presentingViewController {
            presentingViewController.present(alertController, animated: true, completion: nil)
        } else {
            let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
            navController.present(alertController, animated: true, completion: nil)
        }
    }
}

func fetchAircraft () -> DJIAircraft? {
    return DJISDKManager.product() as? DJIAircraft
}

func fetchFlightController() -> DJIFlightController? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.flightController
}
~~~

In the code above, we mainly create the three methods to fetch the **DJIAircraft**, and **DJIFlightController** objects. Moreover, create global functions `showAlertWith(result:)` and `showAlertWith(title: message: cancelAction: defaultAction: presentingViewController:)` to present a UIAlertController for showing messages.

## Implementing GeoDemoViewController

### Implementing Login and Logout Features

  Now, let's open the GeoDemoViewController.swift file, import the following modules and create related IBOutlet properties and IBAction methods to link to the UI elements in the storyboard:
  
~~~swift
import Foundation
import MapKit
import DJISDK

class GeoDemoViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var loginStateLabel: UILabel!
    @IBOutlet weak var unlockBtn: UIButton!
    @IBOutlet weak var flyZoneStatusLabel: UILabel!
    @IBOutlet weak var getUnlockButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var customUnlockButton: UIButton!
    @IBOutlet weak var showFlyZoneMessageTableView: UITableView!

    var mapController: MapController?
    var updateLoginStateTimer : Timer?

    ...
}
~~~

In the code above, we also create a **MapController** property `mapController` and a **Timer?** property `updateLoginStateTimer` to update the `loginStateLabel`'s text content.

Next, let's implement the `onLoginButtonClicked:` and `onLogoutButtonClicked:` IBAction methods as shown below:

~~~swift
    //MARK: IBAction Methods
    @IBAction func onLoginButtonClicked(_ sender: Any) {
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: true) { (_:DJIUserAccountState, error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "GEO Login Error: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "GEO Login Success")
            }
        }
    }
    
    @IBAction func onLogoutButtonClicked(_ sender: Any) {
        DJISDKManager.userAccountManager().logOutOfDJIUserAccount { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Logout error: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Logout success")
            }
        }
    }
~~~

Here, we invoke the `logIntoDJIUserAccountWithCompletion:` method of DJIFlyZoneManager to present a login view controller for users to login to their DJI account. Next, we invoke the `logOutOfDJIUserAccountWithCompletion:` method of DJIFlyZoneManager to logout from a user's DJI account.

Lastly, in order to update the `loginStateLabel` with the user account status, we may need to initialize the `updateLoginStateTimer` in the `viewWillAppear:` method as shown below:

~~~swift
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateLoginStateTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                          target: self,
                                                          selector: #selector(onUpdateLoginState),
                                                          userInfo: nil,
                                                          repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.updateLoginStateTimer = nil
    }

    @objc func onUpdateLoginState() {
        let state = DJISDKManager.userAccountManager().userAccountState
        var stateString = "DJIUserAccountStatusUnknown"
        
        switch state {
        case .notLoggedIn:
            stateString = "DJIUserAccountStatusNotLoggedIn"
        case .notAuthorized:
            stateString = "DJIUserAccountStatusNotVerified"
        case .authorized:
            stateString = "DJIUserAccountStatusSuccessful"
        case .tokenOutOfDate:
            stateString = "DJIUserAccountStatusNotLoggedIn"
        case .unknown:
            fallthrough
        @unknown default:
            stateString = "DJIUserAccountStatusUnknown"
        }

        self.loginStateLabel.text = stateString
    }
~~~

In the code above, we implement the following features:

1. Initialize the `updateLoginStateTimer` to invoke the `onUpdateLoginState` selector method to update the `loginStateLabel` content in the `viewWillAppear:` method.

2. Set the `updateLoginStateTimer` to nil in the `viewWillDisappear:` method.

3. Invoke the `getUserAccountStatus` method of **DJIFlyZoneManager** and assign the value to a **DJIUserAccountStatus** object. Next, use a switch statement to check the value of `state` object and assign related string content to `stateString` variable. Lastly, update `loginStateLabel`'s text content with the `stateString` variable value.

### Working on DJISimulator Feature

With the help of **DJISimulator**, you can simulate the coordinate data of the aircraft to some No Fly Zone areas for testing without actually flying the aircraft. 

Moreover, you can also use the **DJISimulator** to control the aircraft in a simulated environment based on the virtual stick input, this would be helpful when you are testing if the authorization fly zone is unlocked successfully by trying to take off the aircraft.

Now let's implement the start and stop simulator buttons' IBAction methods as shown below:

~~~swift
    override func viewDidLoad() {
        self.title = "DJI GEO Demo"
        self.pickerContainerView.isHidden = true
        
        guard let aircraft = fetchAircraft() else { return }

        aircraft.flightController?.delegate = self
        DJISDKManager.flyZoneManager()?.delegate = self
        self.mapController = MapController(map: self.mapView)
    }

    @IBAction func onStartSimulatorButtonClicked(_ sender: Any) {
        guard let flightController = DJIGeoSample.fetchFlightController() else { return }

        let alertController = UIAlertController(title: "", message: "Input coordinate", preferredStyle: .alert)
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "latitude"
        }
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "longitude"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let startAction = UIAlertAction(title: "Start", style: .default) { (action:UIAlertAction) in
            guard let latitudeString = alertController.textFields?[0].text else { return }
            guard let longitudeString = alertController.textFields?[1].text else { return }
            guard let latitude = Double(latitudeString) else { return }
            guard let longitude = Double(longitudeString) else { return }

            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            flightController.simulator?.start(withLocation: location,
                                              updateFrequency: 20,
                                              gpsSatellitesNumber: 10,
                                              withCompletion: { [weak self] (error:Error?) in
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "Start simulator error: \(error.localizedDescription)")
                } else {
                    DJIGeoSample.showAlertWith(result: "Start simulator success")
                    self?.mapController?.refreshMapViewRegion()
                    self?.mapController?.aircraftAnnotation = nil
                }
            })
        }

        alertController.addAction(cancelAction)
        alertController.addAction(startAction)
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func onStopSimulatorButtonClicked(_ sender: Any) {
        guard let flightController = DJIGeoSample.fetchFlightController() else { return }
        
        flightController.simulator?.stop(completion: { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Stop simulator error:\(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Stop simulator success")
            }
        })
    }
~~~

In the code above, we implement the following features:

1. In the `onStartSimulatorButtonClicked:` method, we firstly fetch the DJIFlightController object and assign it to the `flightController` variable. Next, create a UIAlertController with the message of "Input Coordinate" and the style of "UIAlertController.Style.alert". Moreover, add two textFields and set their placeholder content as "latitude" and "longitude". We will use these two textFields to enter the simulated **latitude** and **longitude** data.

2. Then we implement the UIAlertAction handler of `startAction` and invoke the `startSimulatorWithLocation:updateFrequency:GPSSatellitesNumber:withCompletion:` method of DJISimulator to start the simulator by passing the `location` variable, which is made from the two textFields's content, and **20** as frequency, **10** as GPS Satellites number. If starting simulator successfully without error, invoke the `refreshMapViewRegion` method of **DJIMapViewController** to update the map view's region and zoom into the new coordinate we just set. Lastly, add the two UIAlertAction variables and present the UIAlertController.

3. In the `onStopSimulatorButtonClicked:` method, we firstly fetch the DJIFlightController object and then invoke the `stopWithCompletion:` method of DJISimulator to stop the simulator.

### Implementing GEO System Features

#### Update Fly Zone Info and Aircraft Location

If you want to unlock a fly zone, you may need to get the fly zone's ID first. Now let's update the fly zone info and update the aircraft's location when simulated coordinate data changes.

Implement the **DJIFlyZoneDelegate**, **DJIFlightControllerDelegate**, **UITableViewDelegate** and **UITableViewDataSource** protocols in GeoDemoViewController and declare the `updateFlyZoneDataTimer`, `unlockFlyZoneIDs`, `showFlyZoneMessageTableView` and `flyZoneInfoView` properties as shown below:

~~~swift

class GeoDemoViewController : UIViewController, DJIFlyZoneDelegate, DJIFlightControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var loginStateLabel: UILabel!
    @IBOutlet weak var unlockBtn: UIButton!
    @IBOutlet weak var flyZoneStatusLabel: UILabel!
    @IBOutlet weak var getUnlockButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var customUnlockButton: UIButton!
    @IBOutlet weak var showFlyZoneMessageTableView: UITableView!

    var mapController: MapController?
    var updateLoginStateTimer : Timer?
    var updateFlyZoneDataTimer : Timer?
    var unlockFlyZoneIDs = [NSNumber]()
    var unlockedFlyZones : [DJIFlyZoneInformation]?
    var selectedFlyZone : DJIFlyZoneInformation?
    var isUnlockEnable = false
    var flyZoneView : DJIScrollView?

    ...

}
~~~

Next, let's refactor the `viewDidLoad` method and implement the `initUI` method as shown below:

~~~swift

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerContainerView.isHidden = true
        
        guard let aircraft = fetchAircraft() else { return }

        aircraft.flightController?.delegate = self
        DJISDKManager.flyZoneManager()?.delegate = self
        self.initUI()
    }

    func initUI() {
        self.title = "DJI GEO Demo"
        
        self.mapController = MapController(map: self.mapView)
        self.unlockedFlyZones = [DJIFlyZoneInformation]()
        self.flyZoneView = DJIScrollView(parentViewController: self)
        self.flyZoneView?.isHidden = true
        self.flyZoneView?.setDefaultSize()
    }
~~~

In the code above, we set the `delegate` property of **DJIFlightController**, **DJIFlyZoneManager** and DJIFlightController's **simulator** to self and initialize the `isGEOSystemEnabled` and `flyZoneInfoView` properties. 

Let's add the following code at the bottom of `viewWillAppear:` to update the fly zones in the aircraft's surrounding area and initialize the `updateFlyZoneDataTimer` property:

~~~swift    
    override func viewWillAppear(_ animated: Bool) {

        ...

        self.updateFlyZoneDataTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                           target: self,
                                                           selector: #selector(onUpdateFlyZone),
                                                           userInfo: nil,
                                                           repeats: true)
        
        self.mapController?.updateFlyZonesInSurroundingArea()
    }
~~~
 
Then in the `viewWillDisappear:` method, set `updateFlyZoneDataTimer` to nil at the bottom:

~~~swift
    override func viewWillDisappear(_ animated: Bool) {

        ...

        self.updateFlyZoneDataTimer = nil
    }
~~~

Furthermore, implement the selector method of `onUpdateFlyZone` as shown below:

~~~swift
    @objc func onUpdateFlyZone() {
        self.showFlyZoneMessageTableView.reloadData()
    }
~~~

In the code above, we invoke the `reloadData` method of UITableView to update the fly zone info.

Moreover, let's implement the delegate methods of **DJIFlyZoneDelegate** and **DJIFlightControllerDelegate** as shown below:

~~~swift
    //MARK: - DJIFlyZoneDelegate Method
    func flyZoneManager(_ manager: DJIFlyZoneManager, didUpdate state: DJIFlyZoneState) {
        var flyZoneStatusString = "Unknown"
        switch state {
        case .clear:
            flyZoneStatusString = "NoRestriction"
        case .inWarningZone:
            fallthrough
        case .inWarningZoneWithHeightLimitation:
            flyZoneStatusString = "AlreadyInWarningArea"
        case .nearRestrictedZone:
            flyZoneStatusString = "ApproachingRestrictedArea"
        case .inRestrictedZone:
            flyZoneStatusString = "AlreadyInRestrictedArea"
        case .unknown:
            fallthrough
        @unknown default:
            flyZoneStatusString = "Unknown"
        }
        self.flyZoneStatusLabel.text = flyZoneStatusString
    }

    //MARK: - DJIFlightControllerDelegate Method
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        guard let aircraftCoordinate = state.aircraftLocation?.coordinate else { return }
        if CLLocationCoordinate2DIsValid(aircraftCoordinate) {
            // Convert degrees to radians
            let heading = Float(state.attitude.yaw * Double.pi / 180.0)
            self.mapController?.updateAircraft(coordinate: aircraftCoordinate,
                                               heading: heading)
        }
    }
~~~

In the code above, we implement the following features:

1. In the `flyZoneManager:didUpdateFlyZoneState:` delegate method, we use a switch statement to check the **DJIFlyZoneState** enum value and update the `flyZoneStatusLabel` content.
2. In the `flightController:didUpdateState:` delegate method, we get the updated aircraft location and heading data from the **DJIFlightControllerState** and invoke the `updateAircraftLocation:withHeading:` method of MapController to update the aircraft's location and fly zone overlays on the map view.

Lastly, let's implement the delegate methods of **UITableViewDelegate** and **UITableViewDataSource** as shown below:

~~~
    //MARK: - UITableViewDelgete
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mapController?.flyZones.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nullableCell = tableView.dequeueReusableCell(withIdentifier: "flyzone-id")
        let cell = nullableCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: "flyzone-id")

        if let flyZone = self.mapController?.flyZones[indexPath.row] {
            cell.textLabel?.text = "\(flyZone.flyZoneID):\(self.getFlyZoneStringFor(flyZone.category)):\(flyZone.name)"
            cell.textLabel?.adjustsFontSizeToFitWidth = true
        }
        return cell
    }

    func getFlyZoneStringFor(_ category: DJIFlyZoneCategory) -> String {
        switch category {
        case .warning:
            return "Warning"
        case .restricted:
            return "Restricted"
        case .authorization:
            return "Authorization"
        case .enhancedWarning:
            return "EnhancedWarning"
        case .unknown:
            fallthrough
        @unknown default:
            return "Unknown"
        }
    }


    func stringFor(_ subFlyZones: [DJISubFlyZoneInformation]?) -> String? {
        guard let subFlyZones = subFlyZones else { return nil }
        var subInfoString = ""
        for subZone in subFlyZones {
            subInfoString.append("-----------------\n")
            subInfoString.append("SubAreaID:\(subZone.areaID)")
            subInfoString.append("Graphic:\( subZone.shape == .cylinder ? "Circle": "Polygon")")
            subInfoString.append("MaximumFlightHeight:\(subZone.maximumFlightHeight)")
            subInfoString.append("Radius:\(subZone.radius)")
            subInfoString.append("Coordinate:\(subZone.center.latitude),\(subZone.center.longitude)")
            for point in subZone.vertices {
                if let coordinate = point as? CLLocationCoordinate2D {
                    subInfoString.append("     \(coordinate.latitude),\(coordinate.longitude)\n")
                }
            }
            subInfoString.append("-----------------\n")
        }
        return subInfoString;
    }

    func stringFor(_ flyZone:DJIFlyZoneInformation) -> String {
        var infoString = ""
        infoString.append("ID:\(flyZone.flyZoneID)n")
        infoString.append("Name:\(flyZone.name)\n")
        infoString.append("Coordinate:(\(flyZone.center.latitude),\(flyZone.center.longitude)\n")
        infoString.append("Radius:\(flyZone.radius)\n")
        infoString.append("StartTime:\(flyZone.startTime), EndTime:\(flyZone.endTime)\n")
        infoString.append("unlockStartTime:\(flyZone.unlockStartTime), unlockEndTime:\(flyZone.unlockEndTime)\n")
        infoString.append("GEOZoneType:\(flyZone.type)")
        infoString.append("FlyZoneType:\(flyZone.shape == .cylinder ? "Cylinder" : "Cone")")
        infoString.append("FlyZoneCategory:\(self.getFlyZoneStringFor(flyZone.category))\n")

        if flyZone.subFlyZones?.count ?? -1 > 0 {
            if let subInfoString = self.stringFor(flyZone.subFlyZones) {
                infoString.append(subInfoString)
            }
        }
        
        return infoString
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.flyZoneView?.isHidden = false
        self.flyZoneView?.show()
        if let selectedFlyZone = self.mapController?.flyZones[indexPath.row] {
            self.flyZoneView?.write(status:self.stringFor(selectedFlyZone))
        }
    }
~~~

In the code above, we implement the following features:

1. In the `tableView:numberOfRowsInSection:` delegate method, we return the count of the `flyZones` array of DJIMapViewController.
2. In the `tableView:cellForRowAtIndexPath:` delegate method, we initialize a UITableViewCell object and set its `textLabel` content as the NSString of **DJIFlyZoneInformation**'s related properties.
3. In the `tableView:didSelectRowAtIndexPath:` delegate method, when user select a specific tableView cell, we will show the `flyZoneInfoView` scroll view and update the related fly zone information on the `statusTextView` of the scroll view.

#### Unlock Fly Zones

Once you finish the above steps, let's implement the unlock fly zone feature. Create the `unlockFlyZoneIDs` property as shown below:

~~~swift
    var unlockFlyZoneIDs = [NSNumber]()
~~~

Now let's implement the `onUnlockButtonClicked` and `onGetUnlockButtonClicked` IBAction methods and the `showFlyZoneIDInputView` method as shown below:

~~~swift
    @IBAction func onUnlockButtonClicked(_ sender: Any) {
        self.showFlyZoneIDInputView()
    }

    func showFlyZoneIDInputView() {
        let alertController = UIAlertController(title: "", message: "Input ID", preferredStyle: .alert)
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "Input"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak self] (action:UIAlertAction) in
            if let flyZoneIdText = alertController.textFields?[0].text  {
                let flyZoneID = NSNumber(nonretainedObject: Int(flyZoneIdText))
                self?.unlockFlyZoneIDs.append(flyZoneID)
            }
            self?.showFlyZoneIDInputView()
        }

        let unlockAction = UIAlertAction(title: "Unlock", style: .default) { [weak self] (action:UIAlertAction) in
            guard let self = self else { return }
            if let content = alertController.textFields?[0].text {
                if let idToUnlock = Int(content) {
                    self.unlockFlyZoneIDs.append(NSNumber(value: idToUnlock))
                }
            }
            
            DJISDKManager.flyZoneManager()?.unlockFlyZones(self.unlockFlyZoneIDs, withCompletion: { (error:Error?) in
                self.unlockFlyZoneIDs.removeAll()
                
                if let error = error {
                    DJIGeoSample.showAlertWith(result: "unlock fly zones failed: \(error.localizedDescription)")
                    return
                }
                DJISDKManager.flyZoneManager()?.getUnlockedFlyZonesForAircraft(completion: { (infos:[DJIFlyZoneInformation]?, error:Error?) in
                    if let error = error {
                        DJIGeoSample.showAlertWith(result: "get unlocked fly zones failed: \(error.localizedDescription)")
                        return
                    }
                    guard let infos = infos else { fatalError() } //Should return at least an empty array if no error
                    var resultMessage = "Unlock Zones: \(infos.count)"
                    for info in infos {
                        resultMessage = resultMessage + "\n ID:\(info.flyZoneID) Name:\(info.name) Begin:\(info.unlockStartTime) End:\(info.unlockEndTime)\n"
                    }
                    DJIGeoSample.showAlertWith(result: resultMessage)
                })

            })
        }

        alertController.addAction(cancelAction)
        alertController.addAction(continueAction)
        alertController.addAction(unlockAction)
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func onGetUnlockButtonClicked(_ sender: Any) {
        DJISDKManager.flyZoneManager()?.getUnlockedFlyZonesForAircraft(completion: { [weak self] (infos:[DJIFlyZoneInformation]?, error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Get Unlock Error: \(error.localizedDescription)")
            } else {
                guard let infos = infos else { fatalError() }
                guard let self = self else { return }
                var unlockInfo = "unlock zone count = \(infos.count) \n"
                self.unlockedFlyZones?.removeAll()
                self.unlockedFlyZones?.append(contentsOf: infos)
                for info in infos {
                    unlockInfo = unlockInfo + "ID:\(info.flyZoneID) Name:\(info.name) Begin:\(info.unlockStartTime) end:\(info.unlockEndTime)\n"
                }
                DJIGeoSample.showAlertWith(result: unlockInfo)
            }
        })
    }
~~~

In the code above, we create a UIAlertController with the message of "Input ID", and add a textField with the placeholder of "Input". Then create three UIAlertAction objects for **cancel**, **continue**, and **unlock** actions:

- Cancel Action

  It will dismiss the UIAlertController.

- Continue Action

  It will add the current input fly zone ID to the `unlockFlyZoneIDs` array and present the UIAlertController again.

- Unlock Action

  It will add the current input fly zone ID to `unlockFlyZoneIDs` array and invoke the `unlockFlyZones:withCompletion:` method of **DJIFlyZoneManager** by passing the `unlockFlyZoneIDs` array to unlock fly zones. If unlock fly zone success, invoke the `getUnlockedFlyZonesWithCompletion` method of **DJIFlyZoneManager** to fetch the unlock fly zone info. Then, invoke the `ShowResult()` extern function to show a UIAlertViewController to inform the results to the users.
  
Furthermore, add the three UIAlertAction objects to the `alertController` and present it. Lastly, in the `onGetUnlockButtonClicked` method, we invoke the `getUnlockedFlyZonesWithCompletion` method of DJIFlyZoneManager to get the unlocked fly zones and show an alert view to inform the user. 

#### Enable Unlocked Fly Zone

After unlocking the fly zone, let's continue to implement the feature of enabling the unlocked fly zone. This is useful if the aircraft is shared between users.

Create and add the following properties in the class extension part as shown below:

~~~swift
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIView *pickerContainerView;
@property (nonatomic, strong) NSMutableArray<DJIFlyZoneInformation *> * unlockedFlyZoneInfos;
@property (nonatomic, strong) DJIFlyZoneInformation *selectedFlyZoneInfo;
@property (nonatomic) BOOL isUnlockEnable;
~~~

In the code above, we create IBOutlet properties to link the UI elements in the storyboard. Also create the `unlockedFlyZoneInfos` array property to store the unlocked `DJIFlyZoneInformation` object. Moreover, create the `selectedFlyZoneInfo` property to store the selected `DJIFlyZoneInformation` object. Lastly, create the `isUnlockEnable` bool property to store the fly zone enable unlocked state.

Once you finished the steps above, let's continue to implement the following methods:

~~~swift
    override func viewDidLoad() {
        
        ...

        self.pickerContainerView.isHidden = true
    }
~~~

Here, we hide the `pickerContainerView` in the `viewDidLoad` method first and initialize the `unlockedFlyZoneInfos` property in the `initUI` method.

Next, add the following code in the `onGetUnlockButtonClicked` method to add unlocked `DJIFlyZoneInformation` objects in the `unlockedFlyZoneInfos` array:

~~~swift
if ([target.unlockedFlyZoneInfos count] > 0) {
    [target.unlockedFlyZoneInfos removeAllObjects];
}
[target.unlockedFlyZoneInfos addObjectsFromArray:infos];
~~~

Lastly, implement the following methods:

~~~swift
    @IBAction func enableUnlocking(_ sender: Any) {
        self.pickerContainerView.isHidden = false
        self.pickerView.reloadAllComponents()
    }

    @IBAction func setSelectedUnlockEnabled(_ sender: Any) {
        guard let selectedInfo = self.selectedFlyZone else { return }
        
        selectedInfo.setUnlockingEnabled(self.isUnlockEnable) { (error:Error?) in
            if let error = error {
                DJIGeoSample.showAlertWith(result: "Set unlocking enabled failed: \(error.localizedDescription)")
            } else {
                DJIGeoSample.showAlertWith(result: "Set unlocking enabled success")
            }
        }
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.pickerContainerView.isHidden = true
    }

    //MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return self.unlockedFlyZones.count
        } else if component == 1 {
            return 2
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title = ""
        
        if component == 0 {
            title = "\(self.unlockedFlyZones[row].flyZoneID)"
        } else if component == 1 {
            title = row == 0 ? "YES" : "NO"
        }
        return title
    }

    //MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            if self.unlockedFlyZones.count > row {
                self.selectedFlyZone = self.unlockedFlyZones[row]
            }
        } else if component == 1 {
            self.isUnlockEnable = pickerView.selectedRow(inComponent: 1) == 0
        }
    }
~~~

In the code above, we implement the following feature:

1. In the `enableUnlocking(_ sender:)` method, show the `pickerContainerView` and reload the components of the `pickerView` when the button is pressed.

2. In the `setSelectedUnlockEnabled(_ sender:)` method, invoke the `setUnlockingEnabled:withCompletion:` method of `DJIFlyZoneInformation` to enable the unlocked fly zone.

3. In the `cancelButtonAction(_ sender:)` method, hide the `pickerContainerView` when the cancel button is pressed.

4. Implement the delegate methods of `UIPickerViewDataSource` and `UIPickerViewDelegate` define the data source and select row behaviour of the `pickerView`.

## Running the Sample Code 

We have gone through a long way so far, now, let's build and run the project, connect the demo application to your Mavic Pro (Please check the [Run Application](../application-development-workflow/workflow-run.md) for more details) and check all the features we have implemented so far. 

### Unlock Authorization Fly Zone Workflow

1. Login your DJI account, if it's a new account, you may need to complete the verification process.
2. Press **ENABLED GEO** button to enable the GEO system and restart the aircraft.
2. Press **Start Simulator** button and enter coordinate data to simulate the aircraft's coordinate to the authorization area around **Palo Alto Airport** (37.460484, -122.115312)
3. Wait for a while until the fly zone info updated in the textView on the right side.
4. Get the authorization fly zone ID you want to unlock from the textView, which should be **level 1**
5. Press **Unlock** button and enter the fly zone ID to unlock it
6. If you unlock the fly zone successfully, you may notice that the fly zone number and fly zone info are updated on the right textView, and one of the yellow circles will disappear from the map.
 

### Login and Logout DJI Account

#### 1. Login DJI Account

Press the **Login** button and a login view controller will pop up as shown below:

![login](../images/tutorials-and-samples/iOS/GEODemo/login.png)

If it's a new DJI account, it will show a verification view as shown below:

![verification](../images/tutorials-and-samples/iOS/GEODemo/verification.png)

#### 2. Logout DJI Account

Press the **Logout** button to logout your DJI account.

On the upper right corner of the screenshot, you can check the `loginStateLabel`'s info for the user account status as shown below:

![accountStatus](../images/tutorials-and-samples/iOS/GEODemo/accountStatus.png)

### Start and Stop Simulator

Instead of using [DJI Assistant 2 Simulator](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-testing.md#DJI-Assistant-2-Simulator) to simulate the test environment, we use the location simulation feature of `DJISimulator` to locate the aircraft to specific latitude and longitude coordinate. It's more convenient to test the GEO feature in the sample.  

#### 1. Start Simulator

Here is the screenshot of using **Start Simulator** feature in the sample:

![startSimulator](../images/tutorials-and-samples/iOS/GEODemo/startSimulator.png)

Once you locate the aircraft to the coordinate of (37.4613697, -122.1237315), you may see there are some color circles, which represent different types of fly zones. 

Also the textView on the right side will show the `DJIFlyZoneInformation` info, includes the fly zone number, fly zone id (required in the unlock process), fly zone category and name.

At the same time, the fly zone status label's info will be updated according to the aircraft's coordinate changes.

![flyzones](../images/tutorials-and-samples/iOS/GEODemo/flyZones.png)

- Yellow Circle

  It represents the authorization fly zone, which will restrict the flight by default, it can be unlocked by a GEO authorized user.
  
- Red Circle

  It represents the restricted fly zone, it will restrict the flight by default and cannot be unlocked by a GEO authorized user.
  
#### 2. Stop Simulator
  
Press the **Stop Simulator** button to stop the simulator, an alert view will show as shown below:

![stopSimulator](../images/tutorials-and-samples/iOS/GEODemo/stopSimulator.png)
  
### Unlock and Get Unlock Fly Zones

#### 1. Unlock Fly Zone

After you login with your DJI account and locate the aircraft to the coordinate of (37.4613697, -122.1237315), you can press the **Unlock** button and type in the fly zone ID to unlock it. 

If you unlock the fly zone successfully, you may see the yellow circle disappear and the right fly zone info are updated as shown in the following gif animation:

![unlockFlyZone](../images/tutorials-and-samples/iOS/GEODemo/unlockFlyZone.gif)

#### 2. Get Unlock Fly Zone list

You can press the **GetUnlock** button to get the fly zone you have unlocked before as shown below:

![getUnlockFlyZones](../images/tutorials-and-samples/iOS/GEODemo/getUnlockFlyZones.png)

### Enable Unlocked Fly Zone

You can press the **Enable Unlocking** button to enable the unlocked fly zone as shown below. This is useful if the aircraft is shared between users.

![enableUnlockedFlyZones](../images/tutorials-and-samples/iOS/GEODemo/enableUnlock.gif)

## Summary

In this tutorial, you've learned how to use the `DJIFlyZoneManager` and `DJIFlyZoneInformation` of DJI Mobile SDK to get the fly zone information, how to unlock authorization fly zones and how to add aircraft annotation and draw fly zone circle overlays on the map view to represent the fly zones. Moreover, you've learned how to use the DJISimulator feature to simulate the aircraft's coordinate and test the GEO System feature indoor without flying outside.

Hope this tutorial can help you integrate the GEO System feature in your DJI SDK based Application. Good luck, and hope you enjoyed this tutorial!

