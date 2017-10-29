//
//  MapViewController.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/25/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var directionsMapView: MKMapView!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var directionView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var destination: MKMapItem?
    var note: Note!
    var userLocation: CLLocation?
    let locationManager = CLLocationManager()
    var routeSteps: [MKRouteStep] = []
    var expanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        directionsMapView.delegate = self
        directionsMapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        requestUserLocation()
        
        let barButtonImage = UIImage(named: "list")
        let barButton = UIBarButtonItem(image: barButtonImage , style: .plain, target: self, action: #selector(showRouteSteps(sender:)))
        navigationItem.rightBarButtonItem = barButton
        
        // remove this once destination is passed in
        if let location = note.coordinate {
            let placemark = MKPlacemark(coordinate: location)
            destination = MKMapItem(placemark: placemark)
        }
    }
    
    private func requestUserLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways{
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func getDirections() {
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination!
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {(response, error) in
            if error != nil {
                print("Error getting directions")
            } else {
                self.showRoute(response!)
                self.routeSteps = response?.routes[0].steps ?? []
                self.directionLabel.text = self.routeSteps[0].instructions
                self.distanceLabel.text = DirectionsViewController.convertToMiles(meters: self.routeSteps[0].distance)
                
                if self.routeSteps.count <= 1 {
                    self.goToAR()
                }
            }
        })
    }
    
    func showRoute(_ response: MKDirectionsResponse) {
        for route in response.routes {
            directionsMapView.add(route.polyline,
                         level: MKOverlayLevel.aboveRoads)
            
            for step in route.steps {
                print(step.instructions)
            }
        }
        
        let region = MKCoordinateRegionMakeWithDistance(userLocation!.coordinate, 2000, 2000)
        
        directionsMapView.setRegion(region, animated: true)
    }
    
    @objc func showRouteSteps(sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let directionsNC = storyboard.instantiateViewController(withIdentifier: "DirectionsNavigationController") as? UINavigationController else {
            return
        }
        guard let directionVC = directionsNC.topViewController as? DirectionsViewController else {
            return
        }
        directionVC.routeSteps = routeSteps
        directionsNC.modalTransitionStyle = .flipHorizontal
        present(directionsNC, animated: true, completion: nil)
    }
    
    func goToAR() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let arVC =  storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ARViewController else {
            return
        }
        present(arVC, animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor
        overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        self.getDirections()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

