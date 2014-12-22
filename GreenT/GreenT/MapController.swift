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

class MapController: UIViewController {
    
    @IBOutlet var mapView: MKMapView?

    required init(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = MbtaApi.predictionsByRoutes(["810_", "813_", "823_"])
        println(data!.debugDescription)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
