//
//  DirectionsViewController.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/28/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import MapKit

class DirectionsViewController: UIViewController {

    @IBOutlet weak var directionsTableView: UITableView!
    var routeSteps: [MKRouteStep]!
    static let milesPerMeter = 0.000621371
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func showMap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    static func convertToMiles(meters: Double) -> String {
        let miles = meters * DirectionsViewController.milesPerMeter
        let rounded = round(miles * 100) / 100
        return String(rounded)
    }
}

extension DirectionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeSteps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DirectionsCell", for: indexPath) as? DirectionsCell else {
            return UITableViewCell()
        }
        cell.directionLabel.text = routeSteps[indexPath.row].instructions
        cell.distanceLabel.text = DirectionsViewController.convertToMiles(meters: routeSteps[indexPath.row].distance)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

