//
//  MapController.swift
//  GreenT
//
//  Created by Matthias Ferber on 12/20/14.
//  Copyright (c) 2014 Robot Pie. All rights reserved.
//

import UIKit

import CoreLocation
import MapKit

class MapController: UIViewController, MKMapViewDelegate {
    
// MARK: - Properties
    
    @IBOutlet var mapView: MKMapView!
    
    private var trainAnnotations = [Int: TrainMapAnnotation]()
    
    private var timer: NSTimer?

    
// MARK: - Initialization & lifecycle
    
    required init(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable map rotation: a cheap and dirty way to avoid having to rotate the train markers relative
        // to the map, which looks like it's going to be more difficult than expected
        mapView.rotateEnabled = false
        
        mapView.showsPointsOfInterest = false
        placeGreenLineOverlay()
        placeStations()
        
        updateTrains()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        let center = CLLocationCoordinate2D(latitude: 42.350570, longitude: -71.130660)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let startingRegion = MKCoordinateRegion(center: center, span: span)
        
        mapView!.setRegion(startingRegion, animated: false)
    }


// MARK: - Populating map
    
    func placeGreenLineOverlay() {
        let routeFileUrl: NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("greenline_b_aboveground_route", ofType: "csv")!)!
        var error: NSError?
        let csv = NSString(contentsOfURL: routeFileUrl, encoding: NSUTF8StringEncoding, error: &error)
        if let csvReal = csv {
            let lines = csvReal.componentsSeparatedByString("\n")
            var points = [CLLocationCoordinate2D]()
            for line in lines {
                let coords = line.componentsSeparatedByString(",")
                if (coords.count == 2) {
                    let lat = (coords[0] as NSString).doubleValue
                    let lon = (coords[1] as NSString).doubleValue
                    var point = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    points.append(point)
                }
            }
            
            var polyline = MKPolyline(coordinates: &points, count: points.count)
            mapView.addOverlay(polyline, level: .AboveRoads)
        }
    }
    
    func placeStations() {
        if let stations = MbtaApi.greenLineBStations() {
            for (name, info) in stations {
                let annotation = MKPointAnnotation()
                annotation.title = name
                annotation.coordinate = info.location
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func updateTrains() {
        DDLogSwift.logDebug("--- UPDATE: \(NSDate()) ---")
        
        if let statuses = MbtaApi.greenLineBTrainStatuses() {

            DDLogSwift.logDebug("\(statuses.count) train(s)")
            
            // flag all trains for removal unless we see them in the updated data
            for annotation in mapView.annotations {
                if let trainAnnotation = annotation as? TrainMapAnnotation {
                    trainAnnotation.toBeRemoved = true
                }
            }
            
            for status in statuses {
                if let trainAnnotation = trainAnnotations[status.vehicleId] {
                    DDLogSwift.logDebug("\(status.vehicleId): moving from \(coordsString(trainAnnotation.coordinate)) to \(coordsString(status.location))")
                    
                    trainAnnotation.toBeRemoved = false
                    
                    let theMapView = mapView!
                    UIView.animateWithDuration(1.0, animations: { [unowned theMapView] () -> Void in
                        trainAnnotation.coordinate = status.location
                        trainAnnotation.bearingInDegreesClockwiseFromNorth = status.bearingInDegreesClockwiseFromNorth
                        
                        let annotationView = theMapView.viewForAnnotation(trainAnnotation)
                        if (annotationView != nil) {
                            if let trainAnnotationView = annotationView as? TrainMapAnnotationView {
                                trainAnnotationView.update()
                            }
                        }
                    })
                }
                else {
                    DDLogSwift.logDebug("\(status.vehicleId): adding at \(coordsString(status.location))")
                    
                    let annotation = TrainMapAnnotation(trainStatus: status)
                    mapView.addAnnotation(annotation)
                    
                    trainAnnotations[status.vehicleId] = annotation
                }
            }
            
            // remove trains that no longer exist
            for annotation in mapView.annotations {
                if let trainAnnotation = annotation as? TrainMapAnnotation {
                    if trainAnnotation.toBeRemoved {
                        DDLogSwift.logDebug("\(trainAnnotation.vehicleId): removing")
                        
                        mapView.removeAnnotation(trainAnnotation)
                        trainAnnotations.removeValueForKey(trainAnnotation.vehicleId)
                    }
                }
            }
        }
        
        let trainMapAnnotations = mapView.annotations.filter { $0 is TrainMapAnnotation }
        DDLogSwift.logDebug("--- AFTER update: \(trainAnnotations.count) annotation(s), \(trainMapAnnotations.count) on map")
        
        scheduleNextUpdate()
    }
    
    func scheduleNextUpdate() {
        
        // FIXME: timer must be invalidated when map controller/view goes away or when app goes to background, etc.;
        // must be restarted when the app and map resume
        
        timer = NSTimer.scheduledTimerWithTimeInterval(Settings.updateInterval, target: self,
            selector: "updateTrains", userInfo: nil, repeats: false)
    }
    
    
    // MARK: - Helpers
    
    func coordsString(coordinate: CLLocationCoordinate2D) -> String {
        return "(\(coordinate.latitude as Double), \(coordinate.longitude as Double))"
    }
    
// MARK: - Annotation helper classes
    
    class TrainMapAnnotation: NSObject, MKAnnotation {
        
        dynamic var coordinate: CLLocationCoordinate2D      // dynamic enables KVO, for map updating
        var bearingInDegreesClockwiseFromNorth: CLLocationDegrees
        var toBeRemoved: Bool
        
        private(set) var vehicleId: Int
        private(set) var direction: MbtaApi.Direction
        private(set) var title: String!
        private(set) var subtitle: String!
        
        init(trainStatus: MbtaApi.TrainStatus) {
            self.vehicleId = trainStatus.vehicleId
            self.direction = trainStatus.direction
            self.title = trainStatus.headsign
            self.subtitle = "(" + String(trainStatus.vehicleId) + ") " + trainStatus.tripName
            self.coordinate = trainStatus.location
            self.bearingInDegreesClockwiseFromNorth = trainStatus.bearingInDegreesClockwiseFromNorth
            self.toBeRemoved = false
        }
    }
    
    class TrainMapAnnotationView: MKAnnotationView {
        var markerView: UIImageView!
        
        override var annotation: MKAnnotation! {
            set {
                super.annotation = newValue
                if (newValue != nil) {
                    update()
                }
            }
            get {
                return super.annotation
            }
        }
        
        override var image: UIImage! {
            set {
                if (self.markerView != nil) {
                    self.markerView.image = newValue
                }
            }
            get {
                return self.markerView?.image
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("NSCoding not supported")
        }
        
        // unclear why this initializer is needed; it gets called from MKAnnotationView.init(annotation, reuseIdentifier)
        override init(frame: CGRect) {
            markerView = nil
            super.init(frame: frame)
        }
        
        override init(annotation: MKAnnotation, reuseIdentifier: String) {
            markerView = nil
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            markerView = UIImageView()
            addSubview(markerView)
            markerView.center = self.center

            canShowCallout = true
        }
        
        func update() {
            let greenLineAnnotation = annotation as TrainMapAnnotation
            var imageName: String?
            
            if markerView == nil {
                return
            }
            
            switch (greenLineAnnotation.direction) {
            case .Eastbound:
                imageName = "direction0Marker"
            case .Westbound:
                imageName = "direction1Marker"
            default:
                imageName = nil
            }
            
            if (imageName != nil) {
                image = UIImage(named: imageName!)

                // API bearing is deg clockwise (GTFS standard).
                // Transform uses radians clockwise (doc says counterclockwise for iOS; doc is WRONG).
                let degrees = greenLineAnnotation.bearingInDegreesClockwiseFromNorth
                let radians = degrees * M_PI / 180.0
                
                // println("Deg: \(degrees) -> rad: \(radians)")
                
                markerView.transform = CGAffineTransformMakeRotation(CGFloat(radians))
                
                markerView.sizeToFit()
                self.bounds = markerView.frame
                
                // offset from the path to the "right" by half the marker's width (so two markers can pass and just
                // fit alongside each other), where "right" is orthogonal to direction of travel
                let offsetMagnitude = Double(markerView.image!.size.width) * 0.5
                let offsetDirectionRadians = radians + M_PI / 2
                let offsetX = offsetMagnitude * sin(offsetDirectionRadians)
                let offsetY = -offsetMagnitude * cos(offsetDirectionRadians)    // y is flipped on iOS
                centerOffset = CGPoint(x: CGFloat(offsetX), y: CGFloat(offsetY))
            }
        }
    }
    
    class StationAnnotationView: MKAnnotationView {
        required init(coder: NSCoder) {
            fatalError("NSCoding not supported")
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        override init(annotation: MKAnnotation, reuseIdentifier: String) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            canShowCallout = true
            image = UIImage(named: "station")
        }
    }
    
// MARK: - Constants
    
    private struct Settings {
        static let reuseIdentifier = "GreenLineTrainLocation"
        static let updateInterval: NSTimeInterval = 10.5
    }
}


// MARK: - <MKMapViewDelegate>

extension MapController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let greenLineAnnotation = annotation as? TrainMapAnnotation {
            var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Settings.reuseIdentifier)
            if (view != nil) {
                return view!
            }
            return TrainMapAnnotationView(annotation: greenLineAnnotation, reuseIdentifier: Settings.reuseIdentifier)
        }
        
        if let stationAnnotation = annotation as? MKPointAnnotation {
            return StationAnnotationView(annotation: stationAnnotation, reuseIdentifier: "")
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor(red: 0.06, green: 0.5, blue: 0.32, alpha: 1)
            polylineRenderer.lineWidth = 8
            return polylineRenderer
        }
        return nil
    }
}
