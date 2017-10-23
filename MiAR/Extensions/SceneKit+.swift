//
//  SceneKit+.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/21/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import SceneKit

extension SCNMatrix4 {
    static public func *(left: SCNMatrix4, right: SCNMatrix4) -> SCNMatrix4 {
        return SCNMatrix4Mult(left, right)
    }
    static public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
        let x = left.m11*right.x + left.m21*right.y + left.m31*right.z
        let y = left.m12*right.x + left.m22*right.y + left.m32*right.z
        let z = left.m13*right.x + left.m23*right.y + left.m33*right.z

        return SCNVector4(x: x, y: y, z: z, w: right.w * left.m44)
    }

    func inverted() -> SCNMatrix4 {
        return SCNMatrix4Invert(self)
    }
}

