//: Playground - noun: a place where people can play


import SceneKit
import PlaygroundSupport

struct Angle {
    static func rad(_ angle: Float) -> CGFloat {
        return CGFloat(angle)
    }
    static func deg(_ angle: Float) -> CGFloat {
        return CGFloat(Float.pi * angle / 180)
    }
}

extension SCNVector3 {
    func four(_ value: CGFloat) -> SCNVector4 {
        return SCNVector4Make(self.x, self.y, self.z, Float(value))
    }
}

extension SCNVector4 {
    func three() -> SCNVector3 {
        return SCNVector3Make(self.x, self.y, self.z)
    }
}

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

class Responder {
    init(node: SCNNode) {
        self.node = node
    }

    var node: SCNNode

    // Create the rotation
    let x = SCNVector3Make(1, 0, 0)
    let y = SCNVector3Make(0, 1, 0)
    let z = SCNVector3Make(0, 0, 1)

    @objc func rotateX() {
        rotate(node, around: x, by: Angle.deg(5), duration: 0.5)
    }

    @objc func rotateY() {
        rotate(node, around: y, by: Angle.deg(5), duration: 0.5)
    }

    @objc func rotateZ() {
        rotate(node, around: z, by: Angle.deg(5), duration: 0.5)
    }

    func rotate(_ node: SCNNode, around axis: SCNVector3, by angle: CGFloat, duration: TimeInterval, completionBlock: (()->())?) {
        let rotation = SCNMatrix4MakeRotation(Float(angle), axis.x, axis.y, axis.z)
        let newTransform = node.worldTransform * rotation

        // Animate the transaction
        SCNTransaction.begin()
        // Set the duration and the completion block
        SCNTransaction.animationDuration = duration
        SCNTransaction.completionBlock = completionBlock

        // Set the new transform
        if let parent = node.parent {
            node.transform = parent.convertTransform(newTransform, from: nil)
        } else {
            node.transform = newTransform
        }

        SCNTransaction.commit()
    }

    func rotate(_ node: SCNNode, around axis: SCNVector3, by angle: CGFloat, duration: TimeInterval) {
        rotate(node, around: axis, by: angle, duration: duration, completionBlock: nil)
    }
}

// Create a view, a scene and enable live view
let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 600))
let view = SCNView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
containerView.addSubview(view)
let scene = SCNScene()
view.scene = scene
view.autoenablesDefaultLighting = true
PlaygroundPage.current.liveView = containerView



// Create the box
let box = SCNBox(width: 50, height: 50, length: 50, chamferRadius: 5)
let boxNode = SCNNode(geometry: box)

let subnode = SCNNode()
subnode.transform = SCNMatrix4MakeRotation(Float(Angle.deg(30)), 1, 1, 0)

boxNode.rotation = SCNVector4Make(1, 0, 0, Float(Angle.deg(30)))

scene.rootNode.addChildNode(subnode)
subnode.addChildNode(boxNode)

let responder = Responder(node: boxNode)
let buttonX = UIButton()
buttonX.titleLabel?.text = "Rotate X"
buttonX.addTarget(responder, action: #selector(Responder.rotateX), for: .touchUpInside)

let buttonY = UIButton()
buttonY.titleLabel?.text = "Rotate Y"
buttonY.addTarget(responder, action: #selector(Responder.rotateY), for: .touchUpInside)

let stackView = UIStackView(arrangedSubviews: [buttonX, buttonY])
stackView.distribution = .equalSpacing
stackView.axis = .horizontal
containerView.addSubview(stackView)
