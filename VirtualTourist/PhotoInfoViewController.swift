//
//  PhotoInfoViewController.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/20/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PhotoInfoViewController:UIViewController, UITableViewDelegate, UITableViewDataSource,NSFetchedResultsControllerDelegate{
    
    var pin:Pin!
    
    @IBOutlet weak var imagesNotFoundLabel: UILabel!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBOutlet weak var activitityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItems = [self.editButtonItem()]
        tableView.delegate = self
        
        pin = VTClient.sharedInstance().pin
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        tableView.reloadData()
        
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
        
        }()
    
    //Table view Delegate methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            
            let id = "photoInfoCell"
            
            //print(indexPath)
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            let cell = tableView.dequeueReusableCellWithIdentifier(id) as! PhotoInfoTableViewCell
            
            // This is the new configureCell method
            configureCell(cell, photo: photo)
            
            return cell
    }
    
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
            switch (editingStyle) {
            case .Delete:
                
                // Here we get the actor, then delete it from core data
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
                
            default:
                break
            }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    // Step 4: This would be a great place to add the delegate methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            default:
                return
            }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                
            case .Update:
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! PhotoInfoTableViewCell
                let photo = controller.objectAtIndexPath(indexPath!) as! Photo
                self.configureCell(cell, photo: photo)
                
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoInfoTableViewCell, photo: Photo) {
        
        var posterImage = UIImage(named: "placeHolder")
        cell.startAnimating()
        cell.titleLabel!.text = photo.title
        cell.ownerLabel!.text = photo.info?.ownerName
        cell.heightLabel!.text = photo.info?.height
        cell.widthLabel!.text = photo.info?.width
        cell.cellImageView!.image = nil
        
        // Set the Photo Poster Image
        
        if photo.imagePath == nil || photo.imagePath == "" {
            posterImage = UIImage(named: "noImage")
            cell.stopAnimating()
        } else if photo.posterImage != nil {
            posterImage = photo.posterImage
            cell.stopAnimating()
        }
            
        else {
            
            let task = VTClient.sharedInstance().downloadImage(photo.imagePath!) { (imageData, error) -> Void in
                if let error = error {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        VTClient.alertDialog(self, errorTitle: "Error getting photos",action: "Ok", errorMsg:"Photo download error: \(error.localizedDescription)")
                        
                    })
                }
                if let data = imageData {
                    
                    self.sharedContext.performBlockAndWait({
                        photo.posterImage = UIImage(data: data)
                    })
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        cell.cellImageView!.image = photo.posterImage
                        cell.stopAnimating()
                    })
                }
                
            }
            cell.taskToCancelifCellIsReused = task
        }
        cell.cellImageView!.image = posterImage
        
    }
    @IBAction func newCollectionButtonPressed(sender: UIButton) {
        
        deleteAllPhotos()
        activitityIndicator.hidden = false
        activitityIndicator.startAnimating()
        fetchFlickrPhotos()
    }
    
    func fetchFlickrPhotos(){
        
        newCollectionButton.enabled = false
        self.activitityIndicator.startAnimating()
        
        if pin.prefetchedPhotos != nil {
            
            self.deleteAllPhotos()
            populatePhotos(pin.prefetchedPhotos)
            pin.prefetchedPhotos.removeAll()
            pin.prefetchedPhotos = nil
            
            
        } else if !pin.isFetchingImages && !pin.isImageDeleted  {
            
            if pin.photos.isEmpty {
                
                pin.isFetchingImages = true
                VTClient.sharedInstance().getFlickrImageList( pin.latitude,longitude:pin!.longitude){ result, error in
                    if let error = error  {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            VTClient.alertDialog(self, errorTitle: "Error retrieving flickr pictures", action: "Ok",errorMsg: "\(error)")
                        })
                        self.enableDisableComponents(true)
                        
                    }
                    else {
                        self.populatePhotos(result as? [[String: AnyObject]])
                    }
                    
                }
                pin.isFetchingImages = false
            }else{
                enableDisableComponents(false)
            }
        }else{
            
            enableDisableComponents(false)
        }
        
    }
    private func populatePhotos(photos: [[String: AnyObject]]!)-> Void{
        
        if let photoList = photos {
            
            if(photoList.isEmpty){
                
                self.enableDisableComponents(true)
            }else{
                self.sharedContext.performBlockAndWait(
                    {
                        for photoObj in photoList{
                            
                            let photo = Photo(dictionary: photoObj, context: self.sharedContext)
                            photo.pin = self.pin
                            
                        }
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                )
                
                self.enableDisableComponents(false)
            }
        }
    }
    
    
    //Enable disable the components based on the errorFlag
    func enableDisableComponents(errorFlag:Bool){
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.tableView.hidden = errorFlag
            self.imagesNotFoundLabel.hidden = !errorFlag
            self.activitityIndicator.stopAnimating()
            self.newCollectionButton.enabled = true
        })
        
        
    }
    
    //Delete all photos from the sharedContext
    private func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        pin.isImageDeleted = false
        CoreDataStackManager.sharedInstance().saveContext()
    }
}