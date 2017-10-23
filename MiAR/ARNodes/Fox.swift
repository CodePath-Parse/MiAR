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

    static private let gravity = Float(0.004)

    static private let initialPosition = float3(0, -0.2, -0.5)
    static private let modelOffset = float3(0, 0, 0)
    static private let speedFactor: CGFloat = 2.0

    // Direction
    var direction = float2()
    private var previousUpdateTime: TimeInterval = 0
    private var controllerDirection = float2.zero

    private var downwardAcceleration: Float = 0

    private var isMoving = false


    // fox handle
    private var foxNode: SCNNode // top level node
    private var foxOrientation: SCNNode // the node to rotate to orient the fox
    private var model: SCNNode // the model loaded from the fox file
    var scene: SCNScene

    override init() {
        // load model
        scene = SCNScene(named: "art.scnassets/fox/max.scn")!
        model = scene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
        model.simdPosition = Fox.modelOffset
        foxNode = SCNNode()
        foxNode.name = "fox"
        foxNode.simdPosition = Fox.initialPosition
        // This makes the fox smaller
         foxNode.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
        foxOrientation = SCNNode()
        foxNode.addChildNode(foxOrientation)
        foxOrientation.addChildNode(model)

        // load animations
        let idleAnimation = Fox.loadAnimation(fromSceneNamed: "art.scnassets/fox/max_idle.scn")
        model.addAnimationPlayer(idleAnimation, forKey: "idle")
        idleAnimation.play()

        let walkAnimation = Fox.loadAnimation(fromSceneNamed: "art.scnassets/fox/max_walk.scn")
        walkAnimation.speed = Fox.speedFactor
        walkAnimation.stop()
        model.addAnimationPlayer(walkAnimation, forKey: "walk")

        super.init()
    }

    var node: SCNNode! {
        return foxNode
    }

    var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                if isWalking {
                    model.animationPlayer(forKey: "walk")?.play()
                } else {
                    model.animationPlayer(forKey: "walk")?.stop(withBlendOutDuration: 0.2)
                }
            }
        }
    }

    var walkSpeed: CGFloat = 1.0 {
        didSet {
            model.animationPlayer(forKey: "walk")?.speed = Fox.speedFactor * walkSpeed
        }
    }

    private var directionAngle: CGFloat = 0.0 {
        didSet {
            foxOrientation.runAction(
                SCNAction.rotateTo(x: 0.0, y: directionAngle, z: 0.0, duration: 0.1, usesShortestUnitArc:true))
        }
    }

    func update(atTime time: TimeInterval, with renderer: SCNSceneRenderer) {
        guard isMoving else { return }

    }

    func moveTo(_ destination: SCNVector3) {
        print("Current position: \(self.node.position)")
        print("Destination: \(destination)")
        // this is super lame but I couldn't figure out quaternions :-(
        foxNode.look(at: destination)
        foxNode.runAction(SCNAction.rotate(by: .pi, around: SCNVector3Make(0, 1, 0), duration: 0))
        isWalking = true
        foxNode.runAction(SCNAction.move(to: destination, duration: 2)) {
            self.isWalking = false
        }
    }

    func disappear() {
        foxNode.runAction(SCNAction.fadeOut(duration: 3), completionHandler: nil)
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
