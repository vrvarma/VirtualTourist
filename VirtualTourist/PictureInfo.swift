//
//  PictureInfo.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/19/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import CoreData

class PictureInfo:NSManagedObject {
    
    struct Keys {
        static let id = "id"
        static let height = "height_m"
        static let width = "width_m"
        static let ownerName    = "ownername"
    }
    
    @NSManaged var id: String?
    @NSManaged var height: String?
    @NSManaged var width: String?
    @NSManaged var ownerName: String?
    @NSManaged var photo: Photo?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("PictureInfo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = dictionary[Keys.id] as? String
        self.height = dictionary[Keys.height] as? String
        self.width = dictionary[Keys.width] as? String
        self.ownerName = dictionary[Keys.ownerName] as? String
    }
    
}