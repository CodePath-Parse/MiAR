//
//  Note.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/15/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}

class Note: NSObject {
    let dispatch = DispatchGroup()

    var noteId: String
    
    var coordinate: CLLocationCoordinate2D?
    var radius: CLLocationDistance?
    var eventType: EventType?
    var note: String?
    var image: UIImage?
    var fromUser: User?
    var toUser: User?
    
    init(noteId: String) {
        self.noteId = noteId
        self.fromUser = User.currentUser
    }

    convenience init(to: User, text: String, image: UIImage?, location: CLLocationCoordinate2D?) {
        let noteId = Note.makeNewNoteId()
        self.init(noteId: noteId)
        self.note = text
        self.image = image
        self.fromUser = User.currentUser
        self.toUser = to
        self.coordinate = location
    }
    
    func save() {
        let ref = Database.database().reference()
        
        if let note = note {
            ref.child("notes/\(self.noteId)/note").setValue(note)
        }
        if let toUser = toUser {
            ref.child("notes/\(self.noteId)/to_uid").setValue(toUser.uid)
        }
        if let fromUser = fromUser {
            ref.child("notes/\(self.noteId)/from_uid").setValue(fromUser.uid)
        }
    }
    
    static func makeNewNoteId() -> String {
        let ref = Database.database().reference()
        return ref.child("notes").childByAutoId().key
    }
    
    static func get(withNoteId noteId: String, onSuccess: @escaping (Note)->(), onFailure: @escaping (Error)->()) {
        let ref = Database.database().reference()
        ref.child("notes").child(noteId).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let noteText = value?["note"] as? String ?? ""
            guard let toUid = value?["to_uid"] as? String else {
                return
            }
            guard let fromUid = value?["from_uid"] as? String else {
                return
            }
            let note = Note(noteId: noteId)
            note.note = noteText
            
            note.dispatch.enter()
            User.get(withUid: toUid, onSuccess: { (user) in
                note.toUser = user
                note.dispatch.leave()
            }, onFailure: { (error) in
                print("Couldn't get toUser")
                note.dispatch.leave()
            })
            
            note.dispatch.enter()
            User.get(withUid: fromUid, onSuccess: { (user) in
                note.fromUser = user
                note.dispatch.leave()
            }, onFailure: { (error) in
                print("Couldn't get toUser")
                note.dispatch.leave()
            })
            
            note.dispatch.notify(queue: .main, execute: {
                onSuccess(note)
            })
            
        }) { (error) in
            print(error.localizedDescription)
            onFailure(error)
        }
    }
}
