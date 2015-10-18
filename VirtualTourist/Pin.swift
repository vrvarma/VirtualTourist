//
//  Pin.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/12/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject,MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var title: String?
    @NSManaged var subtitle: String?
    @NSManaged var imageDeleted:NSNumber?
    @NSManaged var photos: [Photo]
    
    //coordinate field implemented to support drag & drop
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }        
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    //In case the user deletes all the images in the pin
    //on coming back, disable image being downloaded
    var isImageDeleted: Bool {
        get {
            return imageDeleted == NSNumber(bool: true)
        }
        set {
            imageDeleted = NSNumber(bool: newValue)
        }
    }
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, title: String, subtitle: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.subtitle = subtitle
        self.imageDeleted = false
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var annotation: MKPointAnnotation {
        get {
            let annotation = MKPointAnnotation()
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            annotation.coordinate = location
            annotation.title = self.title
            annotation.subtitle = self.subtitle
            return annotation
        }
    }

}