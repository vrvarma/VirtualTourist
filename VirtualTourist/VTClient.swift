//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/13/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

//
//  OTMVTClient.swift
//  OnTheMap
//
//  Created by Vikas Varma on 8/21/15.
//  Copyright (c) 2015 Vikas Varma. All rights reserved.
//

import Foundation


class VTClient {
    
    
    var session: NSURLSession
    
    var pin:Pin!
    
    init() {
        session = NSURLSession.sharedSession()
    }
    
    class func sharedInstance() -> VTClient {
        struct Static {
            static let instance = VTClient()
        }
        
        return Static.instance
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            //println(parsedResult)
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    //Implement GET Method
    func taskForGETMethod(urlString: String, parameters: [String : AnyObject],headers:[String:String],completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let urlString = urlString + VTClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        if !headers.isEmpty {
            for (key,value) in headers{
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        //println(request)
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if let _ = downloadError {
                completionHandler(result:nil,  error:downloadError)
            } else {
                completionHandler(result: data,  error:nil)
            }
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    func taskForPUTMethod(urlString: String, parameters: [String : AnyObject], headers:[String:String], jsonBody: AnyObject, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let url = NSURL(string: urlString + VTClient.escapedParameters(mutableParameters))!
        
        let request = NSMutableURLRequest(URL: url)
        //var jsonifyError: NSError? = nil
        request.HTTPMethod = "PUT"
        
        if !headers.isEmpty{
            for (key,value) in headers{
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        //println(jsonBody)
        request.HTTPBody = jsonBody as? NSData
        
        //print(request)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if let _ = downloadError {
                
                completionHandler(result: nil, error: downloadError)
            } else {
                
                completionHandler(result:data, error:nil)
            }
        }
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    
    func taskForPOSTMethod(urlString: String, parameters: [String : AnyObject], headers:[String:String], jsonBody: AnyObject, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let url = NSURL(string: urlString + VTClient.escapedParameters(mutableParameters))!
        
        let request = NSMutableURLRequest(URL: url)
        //var jsonifyError: NSError? = nil
        request.HTTPMethod = "POST"
        
        if !headers.isEmpty{
            for (key,value) in headers{
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        //println(jsonBody)
        request.HTTPBody = jsonBody as? NSData
        
        //println(request)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if let _ = downloadError {
                
                completionHandler(result: nil, error: downloadError)
            } else {
                
                completionHandler(result:data, error:nil)
            }
        }
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    func downloadImage(imagePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: imagePath)!
        
        //print("imageUrl \(url)")
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = VTClient.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    
    // MARK: - Helpers
    
    
    // Try to make a better error, based on the status_message from VTClient. If we cant then return the previous error
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult["message"] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "VT Client Error", code: 1, userInfo: userInfo)
            }
            
        } catch _ {}
        
        return error

    }

}
