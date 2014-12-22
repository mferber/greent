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
    
    @IBOutlet var mapView: MKMapView!

    required init(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeGreenLineOverlay()
        
        let statuses = MbtaApi.greenLineBTrainStatuses()
        if let statusesReal = statuses {
            for status in statusesReal {
                let annotation = MKPointAnnotation()
                annotation.coordinate = status.location
                annotation.title = status.headsign
                annotation.subtitle = status.tripName
                self.mapView.addAnnotation(annotation)
            }
        }
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
            mapView.addOverlay(polyline)
        }
    }
    

// MARK: - <MKMapViewDelegate>
    
//    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
//        <#code#>
//    }
    
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
