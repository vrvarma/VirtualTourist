//
//  VTMKAnnotationView.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/18/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import MapKit

class VTMKAnnotationView:MKAnnotationView{
    
    required init(coder:NSCoder)
    {
        super.init(coder: coder)!
    }
    init()
    {
        super.dragState = .Starting
        super.draggable = true
    }
}