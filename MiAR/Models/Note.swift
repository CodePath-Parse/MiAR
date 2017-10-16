//
//  Note.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/15/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import CoreLocation

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}

class Note: NSObject {

    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var eventType: EventType
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, eventType: EventType) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.eventType = eventType
    }
}
