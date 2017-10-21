//
//  ViewController.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/9/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    private var debugging: Bool = false

    private var fox: Fox?
//    private var scene: SCNScene!
    private var planes: [UUID:Plane] = [UUID:Plane]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupRecognizers()
        setupDebugging()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal


        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    private func setupScene() {
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true

        let scene = SCNScene()
        sceneView.scene = scene
    }

    private func setupDebugging() {
        if debugging {
            // Show statistics such as fps and timing information
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ ARSCNDebugOptions.showWorldOrigin,
                                       ARSCNDebugOptions.showFeaturePoints]
            planes.forEach({ (_,plane) in
                plane.isHidden = false
            })
        } else {
            sceneView.showsStatistics = false
            sceneView.debugOptions = []
            planes.forEach({ (_,plane) in
                plane.isHidden = true
            })
        }
    }

    private func setupRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapFrom(recognizer:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        // long press with two fingers will enable debugging
        let debuggingRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressFrom(recognizer:)))
        debuggingRecognizer.minimumPressDuration = 1
        debuggingRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(debuggingRecognizer)
    }

    private func addPostman(_ hitPoint: ARHitTestResult) {
        fox = Fox()
        fox?.node.position = SCNVector3Make(hitPoint.worldTransform.columns.3.x, hitPoint.worldTransform.columns.3.y, hitPoint.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(fox!.node)
        print("Added fox")
    }

    @objc func handleTapFrom(recognizer: UIGestureRecognizer) {
        let tapPoint = recognizer.location(in: sceneView)
        let hits = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        guard hits.count > 0 else {
            print("No plane were hit")
            return
        }
        let hitResult = hits.first!
        addPostman(hitResult)
    }

    @objc func handleLongPressFrom(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            debugging = !debugging
            setupDebugging()
            print("Debugging set to \(debugging)")
        default:
            break
        }
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        guard let lightEstimate = sceneView.session.currentFrame?.lightEstimate else {
//            return
//        }
//
//        let intensity = lightEstimate.ambientIntensity / 1000.0
//        sceneView.scene.lightingEnvironment.intensity = intensity
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if debugging,
            let planeAnchor = anchor as? ARPlaneAnchor {
                // show planes
                let plane = Plane(withAnchor: planeAnchor)
                planes[anchor.identifier] = plane
                node.addChildNode(plane)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if debugging,
            let plane = planes[anchor.identifier],
            let planeAnchor = anchor as? ARPlaneAnchor {
            plane.update(anchor: planeAnchor)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if debugging {
            planes.removeValue(forKey: anchor.identifier)
        }
    }
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()

        return node
    }
*/

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
}
