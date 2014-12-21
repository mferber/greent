//
//  MbtaApi.swift
//  GreenT
//
//  Created by Matthias Ferber on 12/20/14.
//  Copyright (c) 2014 Robot Pie. All rights reserved.
//

import Foundation

class MbtaApi {
    
    private struct Private {
        static var baseUrl: NSURL! = NSURL(string: "http://realtime.mbta.com/developer/api/v2/")
        static var apiKey = "_eE_PLk80kuL1No3kuSazg"
    }
    
    class func predictionsByRoutes(routes: [String]) -> [String: AnyObject]? {
        return getJSONDictionary("predictionsbyroutes", params:["routes": ",".join(routes)])
    }
    
    class func getJSONDictionary(url: NSURL) -> [String: AnyObject]? {
        let request = NSURLRequest(URL: url)
        var response: NSURLResponse?
        var error: NSError?
        let dataOpt: NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error: &error)
        
        if let data = dataOpt {
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
            println(url)
            return getJSONDictionary(url)
        }
        else {
            println("Couldn't form full URL from relative URL: \(relativeUrl)")
            return nil;
        }
    }
}