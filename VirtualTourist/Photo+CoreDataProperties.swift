//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/19/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var imagePath: String?
    @NSManaged var title: String?
    @NSManaged var pin: Pin?

}
