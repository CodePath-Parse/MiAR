//
//  Fox.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/14/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import Foundation
import SceneKit
import simd

class Fox: NSObject {
    static private let initialPosition = float3(0, -0.2, -0.5)
    static private let modelOffset = float3(0, 0, 0)
    static private let speedFactor: CGFloat = 2.0



    // fox handle
    private var foxNode: SCNNode? // top level node
    private var foxOrientation: SCNNode? // the node to rotate to orient the fox
    private var model: SCNNode? // the model loaded from the fox file
    var scene: SCNScene?

    override init() {
        super.init()
        loadModel()
        loadAnimations()
    }

    private func loadModel() {
        scene = SCNScene(named: "art.scnassets/fox/max.scn")
        model = scene?.rootNode.childNode(withName: "Max_rootNode", recursively: true)
        guard model != nil else {return}
        model?.simdPosition = Fox.modelOffset

        foxNode = SCNNode()
        foxNode?.name = "fox"
        foxNode?.simdPosition = Fox.initialPosition
        foxNode?.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
        foxOrientation = SCNNode()
        foxNode?.addChildNode(foxOrientation!)
        foxOrientation?.addChildNode(model!)
    }

    private func loadAnimations() {
        let idleAnimation = Fox.loadAnimation(fromSceneNamed: "art.scnassets/fox/max_idle.scn")
        model?.addAnimationPlayer(idleAnimation, forKey: "idle")
        idleAnimation.play()

        let walkAnimation = Fox.loadAnimation(fromSceneNamed: "art.scnassets/fox/max_walk.scn")
        walkAnimation.speed = Fox.speedFactor
        walkAnimation.stop()
        model?.addAnimationPlayer(walkAnimation, forKey: "walk")
    }

    var node: SCNNode! {
        return foxNode
    }

    var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                if isWalking {
                    model?.animationPlayer(forKey: "walk")?.play()
                } else {
                    model?.animationPlayer(forKey: "walk")?.stop(withBlendOutDuration: 0.2)
                }
            }
        }
    }

    // MARK: utils

    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene(named: sceneName)!
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
}
