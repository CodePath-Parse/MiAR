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

class ARViewController: UIViewController {

    @IBOutlet var sceneView: CustomARView!
    private var debugging: Bool = false
    var isRestartAvailable = true
    var focusSquare = FocusSquare()


    var note: Note?
    var noteNode: SCNNode?

    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()

    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.miar.queue")

    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private var fox: Fox?
//    private var scene: SCNScene!
    private var planes: [UUID:Plane] = [UUID:Plane]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)

        setupScene()

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }

        setupRecognizers()
        setupDebugging()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        guard ARWorldTrackingConfiguration.isSupported else {
//            return
//        }

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal

        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        UIApplication.shared.isIdleTimerDisabled = true


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

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
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

    private func addPostman(_ position: float3) {
        print("Adding Fox")
        guard let fox = self.fox else {
            self.fox = Fox()
            self.fox?.node.position = SCNVector3(position)
            sceneView.scene.rootNode.addChildNode(self.fox!.node)
            return
        }
        // move the fox
        let destination = SCNVector3(position)
        fox.moveTo(destination)
        fox.disappear()
    }

    @objc func handleTapFrom(recognizer: UIGestureRecognizer) {
        print("Handling TAP")
        guard let _ = sceneView.session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }

//        fox?.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)

        updateQueue.async {
            self.addPostman(focusSquarePosition)
        }
//        let tapPoint = recognizer.location(in: sceneView)
//        let hits = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
//        guard hits.count > 0 else {
//            return
//        }
//        let hitResult = hits.first!
//        addPostman(hitResult)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController,
            let vc = nc.childViewControllers.first as? NewNoteViewController {
            if noteNode != nil {
                noteNode?.removeFromParentNode()
                noteNode = nil
            }
            vc.completion = { (note) in
                // Send by postman
                // triggering a cool postman animation goes here...
                print("Got Note from NewNoteViewController: \(note)")
                self.note = note
                self.note!.save()
                self.displayNote()
                self.statusViewController.scheduleMessage("TAP TO SEND NOTE", inSeconds: 1, messageType: .planeEstimation)
            }
        }
    }

    func displayNote() {
        let noteGeometry = SCNBox(width: 10, height: 10, length: 1.0, chamferRadius: 1.0)
        let mat = SCNMaterial()
        mat.locksAmbientWithDiffuse = true
        mat.diffuse.contents = note!.image!
        mat.specular.contents = UIColor.white
        let white = SCNMaterial()
        white.diffuse.contents = UIColor.white
        white.locksAmbientWithDiffuse = true
        noteGeometry.materials = [mat, white, white, white, white, white]
        let noteNode = SCNNode(geometry: noteGeometry)
        noteNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 2)))
        noteNode.position = SCNVector3Make(0, 0, -20)
        sceneView.scene.rootNode.addChildNode(noteNode)
        self.noteNode = noteNode
    }
}

extension ARViewController {
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }

    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        statusViewController.cancelAllScheduledMessages()
        resetTracking()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }


}

extension ARViewController : ARSCNViewDelegate {

    func updateFocusSquare() {
        if fox != nil {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }

        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
//            addObjectButton.isHidden = true
            return
        }

        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.sceneView.session.currentFrame?.camera

            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
//        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
    }


    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
//            self.fox?.update(atTime: time, with: renderer)
            self.updateFocusSquare()
        }

        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            self.statusViewController.showMessage("SURFACE DETECTED")
            if self.fox == nil && self.note == nil {
                self.statusViewController.scheduleMessage("TAP + TO SEND A NOTE", inSeconds: 7.5, messageType: .contentPlacement)
            }
        }
        updateQueue.async {
                self.fox?.adjustOntoPlaneAnchor(planeAnchor, using: node)
        }
        if debugging {
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
    
}
