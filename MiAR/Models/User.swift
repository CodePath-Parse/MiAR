//
//  User.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/15/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit

class User: NSObject {
    var username: String
    var email: String

    init(username: String, email: String) {
        self.username = username
        self.email = email
    }
}
