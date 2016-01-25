//
//  CollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SceneKit
import SpriteKit
import Async

class TouchRotationSource: RotationMatrixSource {
    
    var isTouching = false
    
    // Take care, compared to the webviewer implementation,
    // phi and theta are switched since native apps and the browser use
    // different reference frames.
    var phi: Float = 0
    var theta: Float = Float(-M_PI_2)
    
    // FOV of the scene
    private let vfov: Float
    private let hfov: Float
    
    // Damping
    private var phiDiff: Float = 0
    private var thetaDiff: Float = 0
    var phiDamp: Float = 0
    var thetaDamp: Float = 0
    var dampFactor: Float = 0.9
    
    private var touchStartPoint: CGPoint?
    
    private let sceneWidth: Int
    private let sceneHeight: Int
    
    // Dependent on optograph format. This values are suitable for
    // Stitcher version <= 7.
    private let border = Float(M_PI) / Float(6.45)
    private let minTheta: Float
    private let maxTheta: Float
    
    init(sceneSize: CGSize, hfov: Float) {
        self.hfov = hfov
        
        sceneWidth = Int(sceneSize.width)
        sceneHeight = Int(sceneSize.height)
            
        vfov = hfov * Float(sceneHeight) / Float(sceneWidth)
        
        maxTheta = -border - (vfov * Float(M_PI) / 180) / 2
        minTheta = Float(-M_PI) - maxTheta
    }
    
    func touchStart(point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(point: CGPoint) {
        let x0 = Float(sceneWidth / 2)
        let y0 = Float(sceneHeight / 2)
        let flen = y0 / tan(vfov / 2 * Float(M_PI) / 180)
        
        let startPhi = atan((Float(touchStartPoint!.x) - x0) / flen)
        let startTheta = atan((Float(touchStartPoint!.y) - y0) / flen)
        let endPhi = atan((Float(point.x) - x0) / flen)
        let endTheta = atan((Float(point.y) - y0) / flen)
        
        phiDiff += Float(startPhi - endPhi)
        thetaDiff += Float(startTheta - endTheta)
        
        touchStartPoint = point
    }
    
    func touchEnd() {
        touchStartPoint = nil
        isTouching = false
    }
    
    func reset() {
        phiDiff = 0
        thetaDiff = 0
        phi = 0
        theta = 0
        phiDamp = 0
        thetaDamp = 0
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        if !isTouching {
            // Update from motion and damping
            phiDamp *= dampFactor
            thetaDamp *= dampFactor
            phi += phiDamp
            theta += thetaDamp
        } else {
            // Update from touch
            phi += phiDiff
            theta += thetaDiff
            phiDamp = phiDiff
            thetaDamp = thetaDiff
            phiDiff = 0
            thetaDiff = 0
        }
        
        theta = max(minTheta, min(theta, maxTheta))
        
        return GLKMatrix4Multiply(GLKMatrix4MakeZRotation(-phi), GLKMatrix4MakeXRotation(-theta))
    }
}

class CombinedMotionManager: RotationMatrixSource {
    private let coreMotionRotationSource: CoreMotionRotationSource
    private let touchRotationSource: TouchRotationSource
    
    private var lastCoreMotionRotationMatrix: GLKMatrix4?
    
    init(sceneSize: CGSize, hfov: Float) {
        self.coreMotionRotationSource = CoreMotionRotationSource.Instance
        self.touchRotationSource = TouchRotationSource(sceneSize: sceneSize, hfov: hfov)
    }
    
    init(coreMotionRotationSource: CoreMotionRotationSource, touchRotationSource: TouchRotationSource) {
        self.coreMotionRotationSource = coreMotionRotationSource
        self.touchRotationSource = touchRotationSource
    }
    
    func touchStart(point: CGPoint) {
        touchRotationSource.touchStart(point)
    }
    
    func touchMove(point: CGPoint) {
        touchRotationSource.touchMove(point)
    }
    
    func touchEnd() {
        touchRotationSource.touchEnd()
    }
    
    func reset() {
        touchRotationSource.reset()
    }
    
    func align(direction: (phi: Float, theta: Float)) {
        touchRotationSource.phi = direction.phi
        touchRotationSource.theta = direction.theta
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        let coreMotionRotationMatrix = coreMotionRotationSource.getRotationMatrix()
        
        if !touchRotationSource.isTouching {
            // Update from motion and damping
            if let lastCoreMotionRotationMatrix = lastCoreMotionRotationMatrix {
                let diffRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(lastCoreMotionRotationMatrix, nil), coreMotionRotationMatrix)
                
                let diffRotationTheta = atan2(diffRotationMatrix.m21, diffRotationMatrix.m22)
                let diffRotationPhi = atan2(-diffRotationMatrix.m20,
                                            sqrt(diffRotationMatrix.m21 * diffRotationMatrix.m21 +
                                                diffRotationMatrix.m22 * diffRotationMatrix.m22))
                
                touchRotationSource.phi += diffRotationPhi
                touchRotationSource.theta += diffRotationTheta
            }
        }
        
        lastCoreMotionRotationMatrix = coreMotionRotationMatrix
        
        return touchRotationSource.getRotationMatrix()
    }
}

class CollectionViewCell: UICollectionViewCell {
    
    weak var uiHidden: MutableProperty<Bool>!
    
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackgroundView = UIView()
    private let loadingOverlayView = UIView()
    
    private var combinedMotionManager: CombinedMotionManager!
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    private var touchStart: CGPoint?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .blackColor()
        
        scnView = SCNView(frame: contentView.frame)
    
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: HorizontalFieldOfView)
    
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(HorizontalFieldOfView))
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        contentView.addSubview(scnView)
        
        loadingOverlayView.backgroundColor = .blackColor()
        loadingOverlayView.frame = contentView.frame
        loadingOverlayView.rac_hidden <~ loadingStatus.producer.equalsTo(.Nothing).map(negate)
        contentView.addSubview(loadingOverlayView)
        
        loadingIndicatorView.frame = contentView.frame
        loadingIndicatorView.rac_animating <~ loadingStatus.producer.equalsTo(.Loaded).map(negate)
        contentView.addSubview(loadingIndicatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        var point = touches.first!.locationInView(contentView)
        touchStart = point
        
        if !uiHidden.value {
            point.y = 0
        }
        
        if touches.count == 1 {
            combinedMotionManager.touchStart(point)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        var point = touches.first!.locationInView(contentView)
        
        if !uiHidden.value {
            if abs(point.x - touchStart!.x) > 20 {
                uiHidden.value = true
                combinedMotionManager.touchStart(point)
                return
            }
            
            point.y = 0
        }
        
        combinedMotionManager.touchMove(point)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let distance = touchStart!.distanceTo(touches.first!.locationInView(self))
        if distance < 10 {
            uiHidden.value = !uiHidden.value
        }
        super.touchesEnded(touches, withEvent: event)
        if touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        if let touches = touches where touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    private func reset() {
        combinedMotionManager.reset()
        loadingStatus.value = .Nothing
        renderDelegate.reset()
        scnView.prepareObject(renderDelegate!.scene, shouldAbortBlock: nil)
    }
    
    func setImage(texture: SKTexture, forIndex index: CubeImageCache.Index) {
        renderDelegate.setTexture(texture, forIndex: index)
      //  scnView.prepareObject(renderDelegate!.planes[index]!, shouldAbortBlock: nil)
        Async.main { [weak self] in
////            self?.loadingStatus.value = isPreview ? .Preview : .Loaded
            self?.loadingStatus.value = .Loaded
        }
    }
    
    func willDisplay(direction: (phi: Float, theta: Float)) {
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
        combinedMotionManager.align(direction)
    }
    
    func didEndDisplay() {
//        renderDelegate.image = nil
        reset()
        scnView.playing = false
    }
    
}