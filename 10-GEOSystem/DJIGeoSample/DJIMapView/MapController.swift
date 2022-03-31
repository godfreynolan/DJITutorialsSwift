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
