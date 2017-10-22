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
    var note: String
    var image: UIImage?
    var toUser: User?
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, eventType: EventType, note: String, image: UIImage?, toUser: User?) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.eventType = eventType
        self.note = note
        self.image = image
        self.toUser = toUser
    }
}
