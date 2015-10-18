//
//  PhotoAlbumCell.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/14/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import UIKit

class PhotoAlbumViewCell: TaskCancelingCollectionViewCell{
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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