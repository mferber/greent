//
//  MbtaApi.swift
//  GreenT
//
//  Created by Matthias Ferber on 12/20/14.
//  Copyright (c) 2014 Robot Pie. All rights reserved.
//

import Foundation
import MapKit

class MbtaApi {
    
    // MARK: - Types
    
    enum Direction: Printable {
        case None
        case Northbound
        case Eastbound
        case Southbound
        case Westbound
        
        var description: String {
            get {
                switch(self) {
                case None:
                    return "None"
                case .Northbound:
                    return "Northbound"
                case .Eastbound:
                    return "Eastbound"
                case .Southbound:
                    return "Southbound"
                case .Westbound:
                    return "Westbound"
                }
            }
        }

        static func forGreenLineDirectionId(id: Int) -> Direction {
            return (id == 0 ? Westbound : id == 1 ? Eastbound : None)
        }
    }
    
    struct TrainStatus: Printable {
        let vehicleId: Int
        let headsign: String
        let tripName: String
        let direction: Direction
        let location: CLLocationCoordinate2D
        
        var description: String {
            get {
                return "Train-\(vehicleId) \(direction) [\(tripName): \"\(headsign)\"] (\(location.latitude), \(location.longitude)))"
            }
        }
    }
    
    // MARK: - High-level API
    
    class func greenLineBTrainStatuses() -> [TrainStatus]? {
        if let data = vehiclesByRoutes(["810_", "813_", "823_"]) {
            var statuses = [TrainStatus]()
            
            if let modes = data["mode"] as? [[String: AnyObject]] {
                for mode in modes {
                    if let routes = mode["route"] as? [[String: AnyObject]] {
                        for route in routes {
                            if let directions = route["direction"] as? [[String: AnyObject]] {
                                for direction in directions {
                                    let directionIdStr = direction["direction_id"]! as String
                                    let directionEnum = Direction.forGreenLineDirectionId(directionIdStr.toInt()!)
                                    
                                    if let trips = direction["trip"] as? [[String: AnyObject]] {
                                        for trip in trips {
                                            let headsign = trip["trip_headsign"]! as String
                                            let trip_name = trip["trip_name"]! as String
                                            
                                            let vehicle = trip["vehicle"]! as [String: AnyObject]
                                            let vehicleId = (vehicle["vehicle_id"]! as String).toInt()!
                                            let lat = (vehicle["vehicle_lat"]! as NSString).doubleValue
                                            let long = (vehicle["vehicle_lon"]! as NSString).doubleValue
                                            
                                            statuses.append(TrainStatus(vehicleId: vehicleId, headsign: headsign, tripName: trip_name,
                                                direction: directionEnum, location: CLLocationCoordinate2D(latitude: lat,
                                                    longitude: long)))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            return statuses
        }
        return nil;
    }
    
    
    // MARK: - Low-level API (wrappers for published API)
    
    class func vehiclesByRoutes(routes: [String]) -> [String: AnyObject]? {
        let rawData: Dictionary? = getJSONDictionary("vehiclesbyroutes", params:["routes": ",".join(routes)])
        if rawData == nil {
            println("vehiclesbyroutes: No data retrieved from MBTA API")
        }
        return rawData;
    }
    
    
    // MARK: - URI requests
    
    class func getJSONDictionary(url: NSURL) -> [String: AnyObject]? {
        let request = NSURLRequest(URL: url)
        var response: NSURLResponse?
        var error: NSError?
        let dataOpt: NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error: &error)
        
        if let data = dataOpt {
//            println(NSString(data:data, encoding: NSASCIIStringEncoding))
            
            var error: NSError?
            let jsonObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
            if let dict = jsonObj as? [String: AnyObject] {
                return dict
            }
            else {
                let errDesc = error == nil ? "n/a": error!
                println("Unexpected problem in JSON: error = \(errDesc)\nMESSAGE: \(NSString(data: data, encoding: NSASCIIStringEncoding))")
                return nil
            }
        }
        else {
            println("No data in response to \(url)")
            return nil
        }
    }
    
    class func getJSONDictionary(var relativeUrl: String, params: [String: String]?) -> [String: AnyObject]? {
        var query: String = "?api_key=\(Private.apiKey)"
        if let paramsReal = params {
            for (header, value) in paramsReal {
                query += "&\(header)=\(value)"
            }
        }
        relativeUrl += query
        
        let urlOpt = NSURL(string: relativeUrl, relativeToURL: Private.baseUrl)
        if let url = urlOpt {
            return getJSONDictionary(url)
        }
        else {
            println("Couldn't form full URL from relative URL: \(relativeUrl)")
            return nil;
        }
    }
    
    
    // MARK: - Private settings
    
    private struct Private {
        static let baseUrl: NSURL! = NSURL(string: "http://realtime.mbta.com/developer/api/v2/")
        static let apiKey = "_eE_PLk80kuL1No3kuSazg"
    }
}