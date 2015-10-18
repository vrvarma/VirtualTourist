//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/12/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - removing images
    
    func removeImage(withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        //print(path)
        inMemoryCache.removeObjectForKey(path)
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        } catch _ {}
        return
        
    }
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        // If the image is nil, remove images from the cache
        if image == nil {
            removeImage(withIdentifier: path)
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path)
        
        // And in documents directory
        let data = UIImageJPEGRepresentation(image!,1)
        data!.writeToFile(path, atomically: false)
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        //Replace "/" with "_" so that it will be saved in the filesystem
        let convertedId  = String(identifier.characters.map {
            
            $0 == "/" ? "_" : $0
            })
        
        //print(documentsDirectoryURL)
        //print(identifier.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()))
        
        do {
            // This will throw if the directory cannot be successfully created, or does not already exist.
            try NSFileManager.defaultManager().createDirectoryAtURL(documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
        }
        catch let error as NSError {
            fatalError("The shared application group documents directory doesn't exist and could not be created. Error: \(error.localizedDescription)")
        }
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(convertedId)
        
        return fullURL.path!
    }
}