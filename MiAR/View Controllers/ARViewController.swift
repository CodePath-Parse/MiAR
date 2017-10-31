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

let noteDeliveredMessageKey = "noteDeliveredMessageKey"

class ARViewController: UIViewController {

    @IBOutlet var sceneView: CustomARView!
    private var debugging: Bool = false
    var isRestartAvailable = true
    var focusSquare = FocusSquare()

    var deliverNote: Note?
    var delivered = false

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
        
        let backBarButton = UIBarButtonItem(title: "Notes near you", style: .plain, target: self, action: #selector(self.goBackToNotes))
        navigationItem.leftBarButtonItem = backBarButton
    }

    @objc func goBackToNotes() {
        navigationController?.popToRootViewController(animated: true)
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
        sceneView.automaticallyUpdatesLighting = true

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


    @objc func handleTapFrom(recognizer: UIGestureRecognizer) {
        print("Handling TAP")
        guard let _ = sceneView.session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }

        if delivered && noteNode != nil {
            // XXX: animate dismissal...
            noteNode?.removeFromParentNode()
            fox?.node.removeFromParentNode()
            noteNode = nil
            fox = nil
            // remove me
            note = nil
        }

        if note == nil && deliverNote == nil {
            statusViewController.scheduleMessage("TAP + TO CREATE A NOTE", inSeconds: 0.1, messageType: .contentPlacement)
            return
        }

        guard fox == nil else {
            return
        }

        if deliverNote != nil && !delivered {
            receiveNote(focusSquarePosition)
            return
        }
        if note != nil {
            sendNote(focusSquarePosition)
        }
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
                print("Got Note from NewNoteViewController: \(note)")
                self.note = note
                self.statusViewController.scheduleMessage("TAP TO SEND NOTE", inSeconds: 1, messageType: .planeEstimation)
            }
        }
    }
}

// Animations
extension ARViewController {

    private func addFox(_ position: float3) {
        let fox = Fox()
        fox.node.position = SCNVector3(position)
        sceneView.scene.rootNode.addChildNode(fox.node)
        self.fox = fox
    }

    private func addNote(_ position: float3) -> SCNNode {
        let noteGeometry = SCNBox(width: 10, height: 10, length: 1.0, chamferRadius: 1.0)
        let mat = SCNMaterial()
        mat.locksAmbientWithDiffuse = true
        mat.diffuse.contents = note!.image!
        mat.specular.contents = UIColor.white
        let page = SCNMaterial()
        page.diffuse.contents = #imageLiteral(resourceName: "parchment-page")
        noteGeometry.materials = [mat, page, page, page, page, page]
        let noteNode = SCNNode(geometry: noteGeometry)
        //        noteNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 2)))
        //SCNVector3(node.simdWorldFront + simd_float3(0, 0, -20))
        noteNode.position = SCNVector3(position)
        return noteNode
    }

    private func addSmallNote(_ position: float3) -> SCNNode {
        let noteGeometry = SCNBox(width: 2, height: 2, length: 0.2, chamferRadius: 1.0)
        let mat = SCNMaterial()
        mat.locksAmbientWithDiffuse = true
        mat.diffuse.contents = deliverNote!.image!
        mat.specular.contents = UIColor.white
        let page = SCNMaterial()
        page.diffuse.contents = #imageLiteral(resourceName: "parchment-page")
        noteGeometry.materials = [mat, page, page, page, page, page]
        let noteNode = SCNNode(geometry: noteGeometry)
        noteNode.position = SCNVector3(position)
        return noteNode
    }

    private func makeFoxRunAway() {
        fox?.spin()
        let pos = float3(sceneView.pointOfView!.position) + float3(0, 0, -50)
        // move the fox
        fox?.moveTo(SCNVector3(pos), duration: 10, completionHandler: {
            self.fox?.disappear()
        })
    }

    private func sendNote(_ position: float3) {
        addFox(position)

        noteNode = addNote(float3(0, 1.5, 0))
        fox?.node.addChildNode(noteNode!)
        noteNode?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 1)))
        let duration:TimeInterval = 3
        noteNode?.runAction(SCNAction.move(to: SCNVector3(position), duration: duration))
        noteNode?.runAction(SCNAction.scale(to: 0.01, duration: duration), completionHandler: {
            self.fox?.spin()
            let pos = float3(self.sceneView.pointOfView!.position) + float3(0, 0, -20)
            self.fox?.moveTo(SCNVector3(pos), duration: 10, completionHandler: {
                self.noteNode?.removeFromParentNode()
                self.fox?.node.removeFromParentNode()
                self.noteNode = nil
                self.fox = nil
                self.note?.save()
                print("Note sent!")
                DispatchQueue.main.async { self.statusViewController.showMessage("NOTE SENT!") }
                self.note = nil
            })
        })
    }

    private func receiveNote(_ position: float3) {
        let posAway = position + float3(0, 0, -30)
        addFox(posAway)
        fox?.node.look(at: sceneView.pointOfView!.position)
        fox?.node.runAction(SCNAction.rotate(by: .pi, around: SCNVector3Make(0, 1, 0), duration: 0))
        fox?.isWalking = true
        fox?.node.runAction(SCNAction.move(to: SCNVector3(position), duration: 2), completionHandler: {
            self.fox?.spin()
            self.fox?.isWalking = false
//            self.fox?.node.constraints = [
//                SCNLookAtConstraint(target: self.sceneView.pointOfView!),
//                SCNBillboardConstraint(),
//            ]
            let startPosition = float3(self.fox!.node.position)
            let finalPosition = startPosition + float3(0, 1.5, 0)
            self.noteNode = self.addSmallNote(startPosition)
            self.fox?.node.addChildNode(self.noteNode!)
            self.noteNode?.runAction(SCNAction.repeat(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 0.1), count: 10))
            self.noteNode?.runAction(SCNAction.scale(to: 1, duration: 1))
            self.noteNode?.runAction(SCNAction.fadeIn(duration: 1))
            self.noteNode?.runAction(SCNAction.move(to: SCNVector3(finalPosition), duration: 1))
            self.delivered = true
            
            if let deliverNote = self.deliverNote {
                let noteInfo: [String: Note] = ["note": deliverNote]
                NotificationCenter.default.post(name: Notification.Name(noteDeliveredMessageKey), object: nil, userInfo: noteInfo)
            }
        })
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
        if fox != nil {
            fox?.node.removeFromParentNode()
        }
        fox = nil
        noteNode?.removeFromParentNode()
        noteNode = nil
        note = nil
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
            if self.fox == nil {
                if self.note == nil && self.deliverNote == nil {
                    self.statusViewController.scheduleMessage("TAP + TO SEND A NOTE", inSeconds: 7.5, messageType: .contentPlacement)
                } else if self.deliverNote == nil {
                    self.statusViewController.scheduleMessage("TAP TO RECEIVE YOUR NOTE", inSeconds: 1, messageType: .contentPlacement)
                }
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
