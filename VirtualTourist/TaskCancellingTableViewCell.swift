//
//  TaskCancellingTableViewCell.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/20/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import UIKit

class TaskCancelingTableViewCell : UITableViewCell {
    
    // The property uses a property observer. Any time its
    // value is set it canceles the previous NSURLSessionTask
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
