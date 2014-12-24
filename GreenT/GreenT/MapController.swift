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
        if let statuses = MbtaApi.greenLineBTrainStatuses() {

            // flag all trains for removal unless we see them in the updated data
            for annotation in mapView.annotations {
                if let trainAnnotation = annotation as? TrainMapAnnotation {
                    trainAnnotation.toBeRemoved = true
                }
            }
            
            for status in statuses {
                if let trainAnnotation = trainAnnotations[status.vehicleId] {
//                    NSLog("Moving \(status.vehicleId) from (\(trainAnnotation.coordinate.latitude as Double), " +
//                        "\(trainAnnotation.coordinate.longitude as Double)) to (\(status.location.latitude as Double), " +
//                        "\(status.location.longitude as Double))")
                    
                    trainAnnotation.toBeRemoved = false
                    
                    UIView.animateWithDuration(1.0, animations: { () -> Void in
                        trainAnnotation.coordinate = status.location
                    })
                }
                else {
//                    NSLog("Adding \(status.vehicleId)")
                    let annotation = TrainMapAnnotation(trainStatus: status)
                    mapView.addAnnotation(annotation)
                    
                    trainAnnotations[status.vehicleId] = annotation
                }
            }
            
            // remove trains that no longer exist
            for annotation in mapView.annotations {
                if let trainAnnotation = annotation as? TrainMapAnnotation {
                    if trainAnnotation.toBeRemoved {
//                        NSLog("Removing \(trainAnnotation.subtitle)")
                        mapView.removeAnnotation(trainAnnotation)
                    }
                }
            }
        }
        
        scheduleNextUpdate()
    }
    
    func scheduleNextUpdate() {
        
        // FIXME: timer must be invalidated when map controller/view goes away or when app goes to background, etc.;
        // must be restarted when the app and map resume
        
        timer = NSTimer.scheduledTimerWithTimeInterval(Settings.updateInterval, target: self,
            selector: "updateTrains", userInfo: nil, repeats: false)
    }
    
    
// MARK: - Annotation helper classes
    
    class TrainMapAnnotation: NSObject, MKAnnotation {
        
        dynamic var coordinate: CLLocationCoordinate2D      // dynamic enables KVO
        private(set) var direction: MbtaApi.Direction
        private(set) var title: String!
        private(set) var subtitle: String!
        var toBeRemoved: Bool
        
        init(trainStatus: MbtaApi.TrainStatus) {
            self.coordinate = trainStatus.location
            self.direction = trainStatus.direction
            self.title = trainStatus.headsign
            self.subtitle = "(" + String(trainStatus.vehicleId) + ") " + trainStatus.tripName
            self.toBeRemoved = false
        }
    }
    
    class TrainMapAnnotationView: MKAnnotationView {

        override var annotation: MKAnnotation! {
            set {
                super.annotation = newValue
                if (newValue != nil) {
                    updateImage()
                }
            }
            get {
                return super.annotation
            }
        }
        
        required init(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        override init(annotation: MKAnnotation, reuseIdentifier: String) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            canShowCallout = true
        }
        
        func updateImage() {
            let greenLineAnnotation = annotation as TrainMapAnnotation
            var imageName: String?
            
            switch (greenLineAnnotation.direction) {
            case .Eastbound:
                imageName = "greenEastbound"
                centerOffset = CGPoint(x: CGFloat(0), y: CGFloat(5))
            case .Westbound:
                imageName = "greenWestbound"
                centerOffset = CGPoint(x: CGFloat(0), y: CGFloat(-5))
            default:
                imageName = nil
            }
            
            if (imageName != nil) {
                image = UIImage(named: imageName!)
            }
        }
    }
    
    class StationAnnotationView: MKAnnotationView {
        required init(coder: NSCoder) {
            super.init(coder: coder)
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
        static let updateInterval: NSTimeInterval = 15
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
