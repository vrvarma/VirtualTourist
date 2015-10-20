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
    
    //UIMapView Delegate Methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            //pinView!.image = UIImage(named: "pin")
            pinView!.draggable = true
            pinView!.animatesDrop = true
            pinView!.selected = true
            pinView!.dragState = .Starting
        }
        else {
            pinView!.animatesDrop = false
            pinView!.annotation = annotation
            pinView!.selected = true
            pinView!.dragState = .Starting
        }
        return pinView
    }
    //this delegate method will be invoked when the pin is selected.
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
                    VTClient.sharedInstance().pin = nil
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }else{
            
            //print("reached in didSelectAnnotationView")
            dispatch_async(dispatch_get_main_queue()){
                
                let pin = annotation as! Pin
                if !pin.isFetchingImages{
                    
                    self.performSegueWithIdentifier("showPhotos", sender: pin)
VTClient.sharedInstance().pin = pin
                }
            }
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get AlbumViewController and pass the selected location
        if let identifier = segue.identifier {
            
            if identifier == "showPhotos" {
                
                segue.destinationViewController as! UITabBarController
            }
            
        }
        
    }

    
    //This delegate method will be invoked when the pin is dragged and dropped
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
        case .Ending, .Canceling:
            
            view.dragState = .None
            
            let pin = view.annotation as! Pin?
            pin?.isFetchingImages = true
            updateLocationInfo(pin!)
            break
        default: break
        }
    }
    
    //this delegate method will be called when the region changes
    //will persist the region in NS
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
            case .Update,.Move:
                //print("Move")
                mapView.removeAnnotation(annotation)
                mapView.addAnnotation(annotation)
                break
                
            }
        }
    }
    
    //Helper Methods
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
    
    //Tapping and holding the map drops a new pin
    //Helper method to place the pin in the mapView
    func addLocation(location: CLLocation) {
        let geoCoder: CLGeocoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Error getting locations", action: "Ok",errorMsg: "\(error.localizedDescription)")
                })
            } else if placemarks!.count > 0 {
                
                let placemark = placemarks!.first as CLPlacemark?
                let mkPlacemark = MKPlacemark(placemark: placemark!)
                
                //print(mkPlacemark)
                
                let title = mkPlacemark.description ?? "Untitled location"
                let subtitle = mkPlacemark.administrativeArea ?? ""
                self.sharedContext.performBlockAndWait(
                    {
                        
                        let pin = Pin(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: title, subtitle: subtitle, context: self.sharedContext)
                        pin.title = title
                        self.prefetchFlickrImages(pin)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                )
                
            } else{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Info",action: "Ok", errorMsg:"No locations found." )
                })
            }
        })
    }
    
    //On dragging and dropping the pin, this method will update the title, subtitle and
    //Prefetches the images
    private func updateLocationInfo(pin:Pin){
        
        let geoCoder: CLGeocoder = CLGeocoder()
        let location :CLLocation = CLLocation(latitude: (pin.coordinate.latitude), longitude: (pin.coordinate.longitude))
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Error getting locations", action: "Ok",errorMsg: "\(error)")
                    pin.isFetchingImages = false
                })
            } else if placemarks!.count > 0 {
                
                let placemark = placemarks!.first as CLPlacemark?
                let mkPlacemark = MKPlacemark(placemark: placemark!)
                
                //print(mkPlacemark)
                
                let title = mkPlacemark.description ?? "Untitled location"
                let subtitle = mkPlacemark.administrativeArea ?? ""
                
                pin.coordinate = location.coordinate
                pin.title = title
                pin.subtitle = subtitle
                self.prefetchFlickrImages(pin)
                
            } else{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    VTClient.alertDialog(self, errorTitle: "Info",action: "Ok", errorMsg:"No locations found." )
                    pin.isFetchingImages = false
                })
            }
        })
    }
    
    //Reload annotations and display
    func reloadAnnotationsToMapViewFromFetchedResults() {
        
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [MKAnnotation])
    }
    
    //Prefetch the Photos from Flickr
    func prefetchFlickrImages(pin:Pin){
        
        pin.isFetchingImages = true
        if pin.prefetchedPhotos != nil {
            
            pin.prefetchedPhotos.removeAll()
        }
        VTClient.sharedInstance().getFlickrImageList( pin.latitude,longitude:pin.longitude){ result, error in
            
            if error == nil  {
                
                pin.prefetchedPhotos = result as? [[String: AnyObject]]
            }else{
                
                pin.prefetchedPhotos = [[String:AnyObject]]()
            }
        }
        pin.isFetchingImages = false
    }
    
}

