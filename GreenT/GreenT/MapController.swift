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
    
    override func viewDidAppear(animated: Bool) {
        let center = CLLocationCoordinate2D(latitude: 42.350570, longitude: -71.130660)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let startingRegion = MKCoordinateRegion(center: center, span: span)
        
        mapView!.setRegion(startingRegion, animated: true)
    }
    

// MARK: - <MKMapViewDelegate>
    
//    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
//        <#code#>
//    }
}
