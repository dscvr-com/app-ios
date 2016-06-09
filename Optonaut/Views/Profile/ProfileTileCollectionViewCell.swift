//
//  TileCollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import SpriteKit
import ReactiveCocoa
import SceneKit
import Kingfisher

class ProfileTileCollectionViewCell: UICollectionViewCell {
    
//    private let renderDelegate: CubeRenderDelegate
//    private let scnView: SCNView
    private let iconView = UILabel()
    private let loadingView = UIActivityIndicatorView()
    private let imageView = PlaceholderImageView()
    
    private let viewModel = ProfileTileCollectionViewModel()
    
    private let uploadButton = UIButton()
    
    private let whiteBackground = UIView()
    private let deleteButton = UIButton()
    
//    private let glView: OpenGLView
    
    override init(frame: CGRect) {
        
//        glView = OpenGLView(frame: CGRect(origin: CGPointZero, size: frame.size))
        
//        if #available(iOS 9.0, *) {
//            scnView = SCNView(frame: CGRect(origin: CGPointZero, size: frame.size), options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
//        } else {
//            scnView = SCNView(frame: frame)
//        }
//        scnView = SCNView(frame: CGRect(origin: CGPointZero, size: frame.size), options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        
//        renderDelegate = CubeRenderDelegate(rotationMatrixSource: CoreMotionRotationSource.Instance, width: scnView.frame.width, height: scnView.frame.height, fov: Double(HorizontalFieldOfView))
        
        super.init(frame: frame)
        
        imageView.frame = CGRect(origin: CGPointZero, size: frame.size)
        imageView.rac_hidden <~ viewModel.isStitched.producer.map(negate)
        viewModel.uploadStatus.producer.equalsTo(.Uploaded)
            .combineLatestWith(viewModel.optographID.producer)
            .delayLatestUntil(viewModel.isStitched.producer)
            .skipRepeats { $0.0 == $1.0 && $0.1 == $1.1 }
            .startWithNext { [weak self] (isUploaded, optographID) in
                if isUploaded {
                    let url = TextureURL(optographID, side: .Left, size: frame.width, face: 0, x: 0, y: 0, d: 1)
                    self?.imageView.kf_setImageWithURL(NSURL(string: url)!)
                } else {
                    let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
                    if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.imageView.image = originalImage.resized(.Width, value: frame.width)
                        }
                    } else {
                        // TODO this should never be possible
                    }
                }
            }
        contentView.addSubview(imageView)
        
        iconView.frame = CGRect(x: frame.width - 32, y: 14, width: 18, height: 18)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(18)
        iconView.rac_hidden <~ viewModel.isStitched.producer.map(negate)
//        iconView.rac_text <~ viewModel.isPrivate.producer.skipRepeats()
//            .combineLatestWith(viewModel.uploadStatus.producer.skipRepeats())
//            .map { isPrivate, uploadStatus in
//                if isPrivate {
//                    return String.iconWithName(.Safe)
//                } else if uploadStatus == .Uploading {
//                    return String.iconWithName(.Loading)
//                } else if uploadStatus == .Offline {
//                    return String.iconWithName(.Upload)
//                } else {
//                    return ""
//                }
//            }
        contentView.addSubview(iconView)
        
        loadingView.frame = CGRect(origin: CGPointZero, size: frame.size)
        loadingView.backgroundColor = UIColor.blackColor().alpha(0.7)
        loadingView.hidesWhenStopped = true
        loadingView.rac_animating <~ viewModel.isStitched.producer.map(negate)
        contentView.addSubview(loadingView)
        
        contentView.backgroundColor = UIColor(0xcacaca)
        
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        contentView.addSubview(whiteBackground)
        
        
        whiteBackground.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 66)
        
        deleteButton.setBackgroundImage(UIImage(named: "profile_delete_icn"), forState: .Normal)
        uploadButton.setBackgroundImage(UIImage(named:"profile_upload_icn"), forState: .Normal)
        
        let deleteImageSize = UIImage(named:"profile_delete_icn")?.size
        let uploadImageSize = UIImage(named:"profile_upload_icn")?.size
        
        whiteBackground.addSubview(deleteButton)
        whiteBackground.addSubview(uploadButton)
        
        deleteButton.anchorToEdge(.Right, padding: 20, width: (deleteImageSize?.width)!, height: (deleteImageSize?.height)!)
        uploadButton.align(.ToTheLeftCentered, relativeTo: deleteButton, padding: 30, width: (uploadImageSize?.width)!, height: (uploadImageSize?.height)!)
        uploadButton.addTarget(self, action: #selector(upload), forControlEvents: .TouchUpInside)
        
        uploadButton.hidden = true
        
        viewModel.isPrivate.producer
            .skipRepeats()
            .combineLatestWith(viewModel.uploadStatus.producer.skipRepeats())
            .startWithNext{ isPrivate, uploadStatus in
                if isPrivate {
                    return self.iconView.text = String.iconWithName(.Safe)
                } else if uploadStatus == .Uploading {
                    self.uploadButton.hidden = true
                    return self.iconView.text = String.iconWithName(.Loading)
                } else if uploadStatus == .Offline {
                    return self.uploadButton.hidden = false
                } else if uploadStatus == .Uploaded {
                    return self.uploadButton.hidden = true
                } else {
                    return
                }
        }
    }
    func upload() {
        viewModel.goUpload()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func bind(optographID: UUID) {
        viewModel.bind(optographID)
    }
    
}