//
//  PhotoInfoTableViewCell.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/20/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import UIKit

class PhotoInfoTableViewCell : TaskCancelingTableViewCell {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    
    func startAnimating()
    {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
    }
    
    func stopAnimating()
    {
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        
    }
}
