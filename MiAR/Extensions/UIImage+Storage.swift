//
//  UIImage+Storage.swift
//  MiAR
//
//  Created by Harsh Mehta on 10/25/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import FirebaseStorage
import Foundation
import UIKit

extension UIImage {
    func saveToFBInBackground(with key: String, onComplete: @escaping ((StorageReference?)->())) {
        let storage = Storage.storage(url: "gs://praxis-zoo-521.appspot.com")
        let storageRef = storage.reference().child(key)
        
        let dataFromImage = UIImagePNGRepresentation(self)
        guard let data = dataFromImage else {
            return
        }
        
        // Upload the file to the path "images/rivers.jpg"
        let _ = storageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            
            print(metadata.description)
            print(metadata.storageReference)
            // Metadata contains file metadata such as size, content-type, and download URL.
            onComplete(metadata.storageReference)
        }
    }
}
