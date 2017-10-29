//
//  NotesViewController.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/28/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import CoreLocation

class NotesViewController: UIViewController {
    
    @IBOutlet weak var notesTableView: UITableView!
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var loading = true
    
    var notes: [Note]! {
        didSet {
            if !loading {
                notesTableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        requestUserLocation()
        loading = false
    }
    
    private func requestUserLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways{
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    static func getNoteDistance(noteLocation: CLLocationCoordinate2D?, userLocation: CLLocation?) -> Double {
        var meters = -1.0
        if let userLocation = userLocation {
            if let noteLocation = noteLocation {
                let noteLoc = CLLocation(latitude: noteLocation.latitude, longitude: noteLocation.longitude)
                meters = userLocation.distance(from: noteLoc)
            }
        }
        return meters
    }
    
    static func convertToMiles(meters: CLLocationDistance) -> Double {
        let miles = meters * DirectionsViewController.milesPerMeter
        let rounded = round(miles * 1000) / 1000
        return rounded
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapViewSegue" {
            guard let mapVC = segue.destination as? MapViewController else {
                return
            }
            guard let note = sender as? NoteCell else {
                return
            }
            guard let indexPath = notesTableView.indexPath(for: note) else {
                return
            }
            mapVC.note = notes[indexPath.row]
        }
    }
}

extension NotesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }
        let note = notes[indexPath.row]
        
        cell.usernameLabel.text = note.fromUser?.username
        let meters = NotesViewController.getNoteDistance(noteLocation: note.coordinate, userLocation: userLocation)
        cell.distanceLabel.text = String(NotesViewController.convertToMiles(meters: meters))
        cell.profileImageView.image = UIImage(named: "anonymous")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

extension NotesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("notes location update")
        userLocation = locations.last
        notesTableView.reloadData()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

