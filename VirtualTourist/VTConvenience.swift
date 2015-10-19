//
//  VTConvenience.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/13/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import UIKit

extension VTClient{
    
    static func alertDialog(viewController:UIViewController, errorTitle: String, action: String, errorMsg:String) -> Void{
        
        let alertController = UIAlertController(title: errorTitle, message: errorMsg, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: action, style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(alertAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    static func alertDialogWithHandler(viewController: UIViewController, errorTitle: String, action:String, errorMsg: String, handler: UIAlertAction! -> Void) {
        
        let alertController = UIAlertController(title: errorTitle, message: errorMsg, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: action, style: UIAlertActionStyle.Cancel, handler: handler)
        alertController.addAction(alertAction)
        dispatch_async(dispatch_get_main_queue(), {
            viewController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    //Given the latitude and longitude  fetch the images from flickr
    func getFlickrImageList(latitude:Double!,longitude:Double!,completionHandler:(result:AnyObject!,errorString: String?) ->Void){
        
        if IJReachability.isConnectedToNetwork(){
            getRandomPage(latitude,longtitude: longitude){ randomPage, error in
                
                if(randomPage != nil){
                    //print("Random Page \(randomPage)")
                    
                    let headers = [String: String]()
                    //Set the parameters
                    let parameters =
                    [Parameters.method: Methods.photoSearch,
                        Parameters.apiKey:Constants.api_key,
                        
                        Parameters.safeSearch:Constants.safe_search,
                        Parameters.dataFormat:Constants.data_format,
                        Parameters.extra :Constants.extra,
                        Parameters.longitude: (longitude),
                        Parameters.latitude :(latitude),
                        Parameters.jsonCallback :Constants.nojsoncallback,
                        Parameters.perPage :Constants.max_pic_per_page,
                        Parameters.page :randomPage]
                    
                    //Invoke the task
                    _ = self.taskForGETMethod( Constants.baseSecuredFlickrURL, parameters: parameters as! [String : AnyObject],headers:headers) { data, error in
                        
                        /* Send the desired value(s) to completion handler */
                        if  error != nil {
                            
                            completionHandler(result: nil, errorString: error!.localizedFailureReason!)
                        }else{
                            VTClient.parseJSONWithCompletionHandler(data as! NSData) { (JSONData, parseError) in
                                //If we failed to parse the data return the reason why
                                if parseError != nil{
                                    completionHandler(result: nil, errorString: parseError!.localizedDescription)
                                    //We seem to have gotten the info, so extract and save it
                                }else{
                                    
                                    //print(JSONData)
                                    if let resultArray = JSONData["photos"] as? [String: AnyObject] {
                                        
                                        if let photoList = resultArray["photo"] as? [[String: AnyObject]] {
                                            //print(resultArray)
                                            completionHandler(result: photoList, errorString: nil)
                                        }
                                        else {
                                            completionHandler(result: nil, errorString: "Error")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }else{
                    completionHandler(result: nil, errorString: error)
                }
                
            }
        }else{
            
            completionHandler(result: nil, errorString: "Unable to connect to Internet!")
        }
    }
    //Method
    //Gets the total number of pictures for that given location
    //And calculates the number of pages (given the max photos per page)
    //returns the random page
    func getRandomPage(latitude:Double!,longtitude:Double!,completionHandler:(result:Int!,errorString: String?) ->Void){
        
        let headers = [String: String]()
        //Set the parameters
        let parameters =
        [Parameters.method: Methods.photoSearch,
            Parameters.apiKey:Constants.api_key,
            Parameters.safeSearch:Constants.safe_search,
            Parameters.dataFormat:Constants.data_format,
            Parameters.longitude: (longtitude),
            Parameters.latitude :(latitude),
            Parameters.jsonCallback :Constants.nojsoncallback,
            Parameters.perPage :1]
        
        //Invoke the task
        _ = taskForGETMethod( Constants.baseSecuredFlickrURL, parameters: parameters as! [String : AnyObject],headers:headers) { data, error in
            
            /* Send the desired value(s) to completion handler */
            if  error != nil {
                
                completionHandler(result: 0, errorString: error!.localizedFailureReason!)
            }else{
                VTClient.parseJSONWithCompletionHandler(data as! NSData) { (JSONData, parseError) in
                    //If we failed to parse the data return the reason why
                    if parseError != nil{
                        completionHandler(result: nil, errorString: parseError!.localizedDescription)
                        //We seem to have gotten the info, so extract and save it
                    }else{
                        
                        
                        if let resultArray = JSONData["photos"] as? [String: AnyObject] {
                            //print("random count \(resultArray)")
                            let total = Int((resultArray["total"] as? String)!)
                            //print(total)
                            
                            if let randomPage = self.genRandomPage(total!) {
                                
                                completionHandler(result: randomPage, errorString: nil)
                            }else{
                                
                                completionHandler(result: nil, errorString: "Error Getting random page")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //Generate the random page given the total number of images for a given location
    private func genRandomPage(total: Int) -> Int? {
        
        let total = min(total, Constants.max_flickr_photos)
        
        if total <= Constants.max_pic_per_page{
            
            return 1
        }else{
            
            let noOfPages = total / Constants.max_pic_per_page
            
            if noOfPages > 1{
                
                return Int (arc4random_uniform(UInt32(noOfPages))) + 1
            }else{
                
                return 1
            }
        }
    }
}
