//
//  Note.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/15/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}

class Note: NSObject {
    let dispatch = DispatchGroup()
    
    var noteId: String
    
    var coordinate: CLLocationCoordinate2D?
    var eventType: EventType?
    var note: String?
    var image: UIImage?
    var fromUser: User?
    var toUser: User?
    var delivered: Bool?
    
    init(noteId: String) {
        self.noteId = noteId
        self.fromUser = User.currentUser
    }
    
    convenience init(to: User?, text: String, image: UIImage?, location: CLLocationCoordinate2D?) {
        let noteId = Note.makeNewNoteId()
        // let noteId = UUID().uuidString
        self.init(noteId: noteId)
        self.note = text
        self.image = image
        self.fromUser = User.currentUser
        self.toUser = to
        self.coordinate = location
        self.delivered = false
    }
    
    func deliveryStatus(_ status: Bool) {
        delivered = status
        save()
    }
    
    func save() {
        let ref = Database.database().reference()

        if let toUser = toUser {
            ref.child("notes/\(self.noteId)/to_uid").setValue(toUser.uid)
        } else {
            // Empty to_uid is interpreted as public message.
            ref.child("notes/\(self.noteId)/to_uid").setValue("")
        }
        if let note = note {
            ref.child("notes/\(self.noteId)/note").setValue(note)
        }
        if let fromUser = fromUser {
            ref.child("notes/\(self.noteId)/from_uid").setValue(fromUser.uid)
        }
        if let image = image {
            image.saveToFBInBackground(with: noteId, onComplete: { (firebaseUrl) in
                if let url = firebaseUrl {
                    ref.child("notes/\(self.noteId)/firebase_url").setValue(url)
                }
            })
		}
		if let coordinate = coordinate {
            ref.child("notes/\(self.noteId)/longitude").setValue(coordinate.longitude)
            ref.child("notes/\(self.noteId)/latitude").setValue(coordinate.latitude)
        }
        if let delivered = delivered {
            ref.child("notes/\(self.noteId)/delivered").setValue(delivered)
        }
    }
    
    static func makeNewNoteId() -> String {
        let ref = Database.database().reference()
        return ref.child("notes").childByAutoId().key
    }
    
    static func initFromSnapshot(snapshot: DataSnapshot, onSuccess: @escaping (Note)->(), onFailure: @escaping ()->()) {
        // Get user value
        let value = snapshot.value as? NSDictionary
        let noteText = value?["note"] as? String ?? ""
        guard let toUid = value?["to_uid"] as? String else {
            onFailure()
            return
        }
        guard let fromUid = value?["from_uid"] as? String else {
            onFailure()
            return
        }
        guard let lat = value?["latitude"] as? Double else {
            onFailure()
            return
        }
        guard let lng = value?["longitude"] as? Double else {
            onFailure()
            return
        }
        let note = Note(noteId: snapshot.key)
        note.note = noteText
        
        if let dataUrl = value?["firebase_url"] as? String {
            let storage = Storage.storage()
            let ref = storage.reference(withPath: dataUrl)
            
            note.dispatch.enter()
            // Download in memory with a maximum allowed size of 10MB (10 * 1024 * 1024 bytes)
            ref.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let _ = error {
                    // Uh-oh, an error occurred!
                } else {
                    // Data for "images/island.jpg" is returned
                    note.image = UIImage(data: data!)
                }
                note.dispatch.leave()
            }
        }
        
        // Make sure its not a public message.
        if toUid != "" {
            note.dispatch.enter()
            User.get(withUid: toUid, onSuccess: { (user) in
                note.toUser = user
                note.dispatch.leave()
            }, onFailure: { (error) in
                print("Couldn't get toUser")
                note.dispatch.leave()
            })
        }
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
        
        note.coordinate = CLLocationCoordinate2DMake(lat, lng)
    }
    
    static func get(withNoteId noteId: String, onSuccess: @escaping (Note)->(), onFailure: @escaping (Error)->()) {
        let ref = Database.database().reference()
        ref.child("notes").child(noteId).observeSingleEvent(of: .value, with: { (snapshot) in
            Note.initFromSnapshot(snapshot: snapshot, onSuccess: onSuccess, onFailure: {
                return
            })
        }) { (error) in
            print(error.localizedDescription)
            onFailure(error)
        }
    }
    
    static func getAllNotes(onSuccess: @escaping ([Note])->(), onFailure: @escaping (Error)->()) {
        let ref = Database.database().reference()
        ref.child("notes").observeSingleEvent(of: .value, with: { (snapshot) in
            //print(snapshot)
            let dispatchGroup = DispatchGroup()
            var notes: [Note] = []
            for child in snapshot.children {
                print(child)
                if let childSnapshot = child as? DataSnapshot {
                    dispatchGroup.enter()
                    Note.initFromSnapshot(snapshot: childSnapshot, onSuccess: { (note) in
                        dispatchGroup.leave()
                        notes.append(note)
                    }, onFailure: {
                        dispatchGroup.leave()
                    })
                }
            }
            dispatchGroup.notify(queue: .main, execute: {
                onSuccess(notes)
            })
        }) { (error) in
            print(error.localizedDescription)
            onFailure(error)
        }
        //let query = ref.child("notes").queryOrderedByKey()
        
    }

    static func listen(onSuccess: @escaping (Note)->(), onFailure: @escaping (Error)->()) {
        let ref = Database.database().reference()
        ref.child("notes").observe(.childAdded, with: { (snapshot) in
            Note.get(withNoteId: snapshot.key, onSuccess: { (note) in
                guard let currentUser = User.currentUser else {
                    return
                }
                if note.toUser?.uid == currentUser.uid {
                    onSuccess(note)
                }
            }, onFailure: { (error) in
                onFailure(error)
            })
        }) { (error) in
            print(error.localizedDescription)
            onFailure(error)
        }
    }
}
