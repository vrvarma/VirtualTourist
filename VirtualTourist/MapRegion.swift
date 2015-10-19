//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/17/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import MapKit
private let _documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
private let _fileURL: NSURL = _documentsDirectoryURL.URLByAppendingPathComponent("VirtualTourist-Context")


//Using NSCoding to save the MapRegion
class MapRegion: NSObject, NSCoding {
    
    var currentRegion: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        currentRegion = region
    }
    
    required init(coder aDecoder: NSCoder) {
        
        let latitude = aDecoder.decodeObjectForKey("latitude") as! CLLocationDegrees
        let longitude = aDecoder.decodeObjectForKey("longitude") as! CLLocationDegrees
        let latitudeDelta = aDecoder.decodeObjectForKey("latitudeSpan") as! CLLocationDegrees
        let longitudeDelta = aDecoder.decodeObjectForKey("longitudeSpan") as! CLLocationDegrees
        currentRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitude, longitude), span: MKCoordinateSpanMake(latitudeDelta, longitudeDelta))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeObject(currentRegion.center.latitude, forKey: "latitude")
        aCoder.encodeObject(currentRegion.center.longitude, forKey: "longitude")
        aCoder.encodeObject(currentRegion.span.latitudeDelta, forKey: "latitudeSpan")
        aCoder.encodeObject(currentRegion.span.longitudeDelta, forKey: "longitudeSpan")
    }
    
    //Method to save the MapRegion
    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: _fileURL.path!)
    }
    
    //Method to retrieve the MapRegion from the Archive file
    class func unarchivedInstance() -> MapRegion? {
        
        if NSFileManager.defaultManager().fileExistsAtPath(_fileURL.path!) {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(_fileURL.path!) as? MapRegion
        } else {
            return nil
        }
    }
    
}