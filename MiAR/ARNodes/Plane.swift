//
//  Plane.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/14/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class Plane: SCNNode {
    var anchor: ARPlaneAnchor?
    var plane: SCNPlane?

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(withAnchor anchor: ARPlaneAnchor) {
        self.init()
        self.anchor = anchor
        self.plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        let material = SCNMaterial()
        material.diffuse.contents = #imageLiteral(resourceName: "tron_grid")
        self.plane?.materials = [material]
        let planeNode = SCNNode(geometry: self.plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)

        // planes in SCNKit default to vertical, so we need to rotate -π/2 to make it horizontal
        planeNode.transform = SCNMatrix4MakeRotation(-.pi/2.0, 1.0, 0.0, 0.0)
        setTextureScale()
        addChildNode(planeNode)
    }

    func setTextureScale() {
        guard let plane = plane else { return }
        let width  = Float(plane.width)
        let height = Float(plane.height)
        let material = plane.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
        material?.diffuse.wrapS = .repeat
        material?.diffuse.wrapT = .repeat
    }

    func update(anchor: ARPlaneAnchor) {
        plane?.width = CGFloat(anchor.extent.x)
        plane?.height = CGFloat(anchor.extent.z)
        position = SCNVector3Make(anchor.center.x, 0.0, anchor.center.z)
        setTextureScale()
    }
}

