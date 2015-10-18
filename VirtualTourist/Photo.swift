//
//  Photo.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/12/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo:NSManagedObject {
    
    struct Keys {
        static let Url = "url_m"
        static let Title = "title"
    }
    
    @NSManaged var title: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = dictionary[Keys.Url] as? String
        self.title = dictionary[Keys.Title] as? String
    }
    
    //this method is invoked by CoreData api when the object is deleted
    override func prepareForDeletion() {
        
        VTClient.Caches.imageCache.removeImage(withIdentifier: self.imagePath!)
    }
    
    var posterImage: UIImage? {
        
        get {
            return VTClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            if imagePath != nil{
                
                VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
            }
        }
    }
}
