//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/10/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate,NSFetchedResultsControllerDelegate,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var editDeleteButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var deleteDisplayLabel: UILabel!
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    
    var deleteFlag :Bool = false
    
    var savedRegion :MapRegion!
    
    var isInitialLoad = true
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        deleteDisplayLabel.hidden = true
        mapView.delegate = self
        
        longPressGesture.delegate = self
        savedRegion = MapRegion.unarchivedInstance()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
    }
    override func viewDidAppear(animated: Bool) {
        
        reloadAnnotationsToMapViewFromFetchedResults()
        
        if savedRegion != nil{
            
            mapView.region = savedRegion.currentRegion
        }
        isInitialLoad = false
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func editOrDelete(sender: UIBarButtonItem) {
        
        deleteFlag = !deleteFlag
        if deleteFlag {
            
            editDeleteButtonItem.title =  "Done"
            deleteDisplayLabel.hidden = false
            deleteDisplayLabel.alpha = 1
        }
        else{
            
            editDeleteButtonItem.title = "Edit"
            deleteDisplayLabel.hidden = true
            deleteDisplayLabel.alpha = 0
        }
    }
    
    @IBAction func tapAction(sender: UILongPressGestureRecognizer) {
        
        let touchPoint = sender.locationInView(self.mapView)
        //print(touchPoint)
        switch(sender.state){
        case .Began:
            
            let newCoordinate: CLLocationCoordinate2D = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let newLocation: CLLocation = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            addLocation(newLocation)
            break
        default:
            break
        }
    }
    
    func addLocation(location: CLLocation) {
        let geoCoder: CLGeocoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Error getting locations", action: "Ok",errorMsg: "\(error)")
                })
            } else if placemarks!.count > 0 {
                
                let placemark = placemarks!.first as CLPlacemark?
                let mkPlacemark = MKPlacemark(placemark: placemark!)
                
                //print(mkPlacemark)
                
                let title = mkPlacemark.description ?? "Untitled location"
                let subtitle = mkPlacemark.administrativeArea ?? ""
                
                let pin = Pin(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: title, subtitle: subtitle, context: self.sharedContext)
                pin.title = title
                
                self.prefetchFlickrImages(pin)
                CoreDataStackManager.sharedInstance().saveContext()
            } else{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Info",action: "Ok", errorMsg:"No locations found." )
                })
            }
        })
    }
    
    //UIMapView Delegate Methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            //pinView!.image = UIImage(named: "pin")
            pinView!.draggable = true
            pinView!.selected = true
            pinView!.dragState = .Starting
            pinView!.setDragState (.Starting,animated: true)
            
        }
        else {
            
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let annotation = view.annotation
        let latitude = annotation?.coordinate.latitude
        let longitude = annotation?.coordinate.longitude
        
        if deleteFlag {
            // Return a Pin object corresponding to selected coordinate from mapView
            let pins = fetchedResultsController.fetchedObjects as! [Pin]
            for pin in pins{
                //print("\(pin.latitude)  \(pin.longitude) \(index)")
                
                if pin.longitude == longitude && pin.latitude == latitude {
                    
                    sharedContext.deleteObject(pin)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }else{
            //print("reached in didSelectAnnotationView")
            dispatch_async(dispatch_get_main_queue()){
                
                let controller =
                self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
                    as! PhotoAlbumViewController
                
                // Similar to the method above
                controller.pin = annotation as! Pin
                self.navigationController!.pushViewController(controller, animated: true)
            }
        }
        
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        
        print("Hey its starting")
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
        case .Ending, .Canceling:
            view.dragState = .None
            let geoCoder: CLGeocoder = CLGeocoder()
            let location :CLLocation = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
            geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                if let error = error {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        VTClient.alertDialog(self, errorTitle: "Error getting locations", action: "Ok",errorMsg: "\(error)")
                    })
                } else if placemarks!.count > 0 {
                    
                    let placemark = placemarks!.first as CLPlacemark?
                    let mkPlacemark = MKPlacemark(placemark: placemark!)
                    
                    //print(mkPlacemark)
                    
                    let title = mkPlacemark.description ?? "Untitled location"
                    let subtitle = mkPlacemark.administrativeArea ?? ""
                    
                    let ann = view.annotation as! Pin?
                    ann!.coordinate = placemark!.location!.coordinate
                    ann!.title = title
                    ann!.subtitle = subtitle
                    
                    self.prefetchFlickrImages(ann!)
                    CoreDataStackManager.sharedInstance().saveContext()
                } else{
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        VTClient.alertDialog(self, errorTitle: "Info",action: "Ok", errorMsg:"No locations found." )
                    })
                }
            })
            
        default: break
        }
    }
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if isInitialLoad{
            return
        }
        
        if(savedRegion == nil){
            savedRegion = MapRegion(region: mapView.region)
        }
        savedRegion.currentRegion = mapView.region
        savedRegion.save()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController! = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
        
        }()
    
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    //CoreData Delegate Methods
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        //print("Object \(anObject) \(type) \(indexPath)")
        if anObject is MKAnnotation {
            
            let annotation = anObject as! MKAnnotation
            switch type {
            case .Insert:
                //print("insert")
                mapView.addAnnotation(annotation)
                break
            case .Delete:
                //print("delete")
                mapView.removeAnnotation(annotation)
                break
            case .Update:
                mapView.removeAnnotation(annotation)
                mapView.addAnnotation(annotation)
                break
            case .Move:
                
                break
            }
        }
        
    }
    
    func reloadAnnotationsToMapViewFromFetchedResults() {
        
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [MKAnnotation])
    }
    
    //Prefetch the Photos from Flickr
    func prefetchFlickrImages(pin:Pin){
        
        if(!pin.photos.isEmpty){
            
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                
                sharedContext.deleteObject(photo)
            }
            pin.isImageDeleted = false

        }
        VTClient.sharedInstance().getFlickrImageList( pin.latitude,longtitude:pin.longitude){ result, error in
            
            //print(error)
            if error == nil  {
                
                if let photoList = result as? [[String: AnyObject]] {
                    
                    for photoObj in photoList{
                        //print(photoObj)
                        let photo = Photo(dictionary: photoObj, context: self.sharedContext)
                        photo.pin = pin
                        
                    }
                }
            }
            
        }
    }
}

