//
//  UIView+.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/20/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit

extension UIView {
    /**
     * Take a snapshot of a UIView
     */
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        self.layer.render(in: context)
        guard let snapshot = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return snapshot
    }
}
