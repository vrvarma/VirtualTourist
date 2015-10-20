//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/14/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController,NSFetchedResultsControllerDelegate,UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var imagesNotFoundLabel: UILabel!
    @IBOutlet weak var collectionActivityIndicator: UIActivityIndicatorView!
    
    var pin:Pin!
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        pin = VTClient.sharedInstance().pin
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        collectionView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        
        addPin()
        collectionView.hidden = true
        fetchFlickrPhotos()
        updateBottomButton()
        
    }
    
    //MapView Delegate methods
    
    //set up the Pin view
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.animatesDrop = true
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    //collectionView delegate methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photoCell = collectionView.dequeueReusableCellWithReuseIdentifier("photoAlbumCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
        
        photoCell.layer.cornerRadius = 10
        photoCell.layer.borderWidth = 1
        photoCell.layer.borderColor = UIColor.whiteColor().CGColor
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(photoCell, photo: photo)
        return photoCell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.imageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
        
        // And update the buttom button
        updateBottomButton()
    }
    //Helper methods
    
    //Add pin on the MapView
    private func addPin(){
        
        if let pin = pin {
            
            let span = MKCoordinateSpanMake(0.2, 0.2)
            let region = MKCoordinateRegion(center: pin.coordinate, span: span)
            
            mapView.region = region
            mapView.zoomEnabled = false
            mapView.scrollEnabled = false
            mapView.userInteractionEnabled = false
            mapView.addAnnotation(pin)
        }
    }
    
    //Method to fetch photos from flickr.
    //
    //Download the images from web if the imagePath is already prefetched.
    //
    //On pressing the New Collection button, fetch a new batch of pictures
    func fetchFlickrPhotos(){
        
        newCollectionButton.enabled = false
        self.collectionActivityIndicator.startAnimating()
        
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
    
    //Populate the Photo object, which will initiate an update.
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
            
            self.collectionView.hidden = errorFlag
            self.imagesNotFoundLabel.hidden = !errorFlag
            self.collectionActivityIndicator.stopAnimating()
            self.newCollectionButton.enabled = true
        })
        
        
    }
    
    //Update the bottom button's title based on whether an image is selected.
    func updateBottomButton() {
        
        if selectedIndexes.count > 0 {
            self.newCollectionButton.setTitle( "Remove Selected Pictures", forState: .Normal)
        } else {
            self.newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    //Configure the imageView in the PhotoAlbumViewCell
    func configureCell(cell: PhotoAlbumViewCell, photo: Photo) {
        
        var posterImage = UIImage(named: "placeHolder")
        cell.startAnimating()
        cell.imageView.image = nil
        cell.imageView.alpha = 1
        if photo.imagePath == nil || photo.imagePath == "" {
            posterImage = UIImage(named: "noImage")
            cell.stopAnimating()
        } else if photo.posterImage != nil {
            
            posterImage = photo.posterImage
            cell.stopAnimating()
            
        } else {
            
            let task = VTClient.sharedInstance().downloadImage(photo.imagePath!) { (imageData, error) -> Void in
                if let error = error {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        VTClient.alertDialog(self, errorTitle: "Error getting photos",action: "Ok", errorMsg:"Poster download error: \(error.localizedDescription)")
                        
                    })
                }
                if let data = imageData {
                    
                    self.sharedContext.performBlockAndWait({
                        photo.posterImage = UIImage(data: data)
                    })
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        cell.imageView.image = photo.posterImage
                        cell.stopAnimating()
                    })
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        cell.imageView.image = posterImage
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
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates ({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
        
    }
    //Action method which will be called when the button is clicked.
    @IBAction func newCollectionButtonPressed(sender: UIButton) {
        if selectedIndexes.isEmpty {
            
            deleteAllPhotos()
            collectionActivityIndicator.hidden = false
            collectionActivityIndicator.startAnimating()
            fetchFlickrPhotos()
            updateBottomButton()
        } else {
            deleteSelectedPhotos()
        }
    }
    
    //Delete all photos from the sharedContext
    private func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        pin.isImageDeleted = false
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //Delete selected photos from the sharedContext.
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        if pin.photos.count == selectedIndexes.count{
            
            pin.isImageDeleted = true
        }
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
        updateBottomButton()
    }
    
    
}