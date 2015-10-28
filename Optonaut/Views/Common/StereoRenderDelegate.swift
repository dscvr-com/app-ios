//
//  StereoRenderDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit
import CardboardParams

class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {
    
    let scene = SCNScene()
    var image: UIImage? {
        didSet {
            sphereNode.geometry?.firstMaterial?.diffuse.contents = image
        }
    }

    private var cameraNode: SCNNode!
    private let sphereNode: SCNNode
    private let rotationMatrixSource: RotationMatrixSource
    private var _fov: FieldOfView!
    
    var fov: FieldOfView {
        get {
            return _fov
        }
        set {
            _fov = fov
            cameraNode.camera = StereoRenderDelegate.setupCamera(fov)
        }
    }

    init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: FieldOfView) {
        self.rotationMatrixSource = rotationMatrixSource
        
        cameraNode = SCNNode()
        
        cameraNode.camera = StereoRenderDelegate.setupCamera(fov)
        _fov = fov
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        sphereNode = StereoRenderDelegate.createSphere()
        scene.rootNode.addChildNode(sphereNode)
        
        super.init()
    }
    
    private static func setupCamera(fov: FieldOfView) -> SCNCamera {
        let zNear = Float(0.01)
        let zFar = Float(10000)
        let fovLeft = sin(DistortionProgram.toRadians(fov.left)) * zNear
        let fovRight = sin(DistortionProgram.toRadians(fov.right)) * zNear
        let fovTop = sin(DistortionProgram.toRadians(fov.top)) * zNear
        let fovBottom = sin(DistortionProgram.toRadians(fov.bottom)) * zNear
        
        let projection = GLKMatrix4MakeFrustum(-fovLeft, fovRight, -fovBottom, fovTop, zNear, zFar)
        
        let camera = SCNCamera()
        camera.setProjectionTransform(SCNMatrix4FromGLKMatrix4(projection))
        
        return camera
    }
    
    convenience init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: Double) {
        let xFov = Float(fov)
        let yFov = xFov * Float(height / width)
        let angles: [Float] = [xFov / Float(2.0), xFov / Float(2.0), yFov / Float(2.0), yFov / Float(2.0)]
        let newFov = FieldOfView(angles: angles)
        
        self.init(rotationMatrixSource: rotationMatrixSource, width: width, height: height, fov: newFov)
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(rotationMatrixSource.getRotationMatrix())
    }
    
    private static func createSphere() -> SCNNode {
        // rotate sphere to correctly display texture
        let transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        
        let geometry = SCNSphere(radius: 5.0)
        geometry.segmentCount = 128
        geometry.firstMaterial?.doubleSided = true
        geometry.firstMaterial?.diffuse.contents = UIColor.clearColor()
        
        let node = SCNNode(geometry: geometry)
        node.transform = transform
        
        return node
    }
    
}