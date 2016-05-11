//
//  MainViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/6/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Icomoon
import SwiftyUserDefaults
import Result

class SwipeViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    var scrollView: UIScrollView!
    var tabView = TabView()
    let leftViewController: NavigationController
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    let isThetaImage = MutableProperty<Bool>(false)
    
    var delegate: TabControlDelegate?
    
    required init() {
        leftViewController = FeedNavViewController()
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = UIColor.blackColor()
        let scrollWidth: CGFloat  = 3 * self.view.frame.width
        let scrollHeight: CGFloat  = self.view.frame.size.height
        self.scrollView!.contentSize = CGSizeMake(scrollWidth, scrollHeight);
        self.scrollView!.pagingEnabled = true;
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blueColor()
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.greenColor()
        
        self.addChildViewController(leftViewController)
        self.scrollView!.addSubview(leftViewController.view)
        leftViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(blueVC)
        self.scrollView!.addSubview(blueVC.view)
        blueVC.didMoveToParentViewController(self)
        
        self.addChildViewController(greenVC)
        self.scrollView!.addSubview(greenVC.view)
        greenVC.didMoveToParentViewController(self)
        
        var adminFrame :CGRect = leftViewController.view.frame
        adminFrame.origin.x = adminFrame.width
        blueVC.view.frame = adminFrame
        
        var BFrame :CGRect = blueVC.view.frame
        BFrame.origin.x = 2*BFrame.width
        greenVC.view.frame = BFrame
        
        view.addSubview(scrollView)
        
        tabView.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(tabView)
        
        isThetaImage.producer
            .filter(isTrue)
            .startWithNext{ _ in
                let alert = UIAlertController(title: "Ooops!", message: "Not a Theta Image, Please choose another photo", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{ _ in
                    self.isThetaImage.value = false
                }))
                self.presentViewController(alert, animated: true, completion: nil)
        }
        
        tabView.cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.tapCameraButton)))
        //tabView.cameraButton.addTarget(self, action: #selector(SwipeViewController.touchStartCameraButton), forControlEvents: [.TouchDown])
        //tabView.cameraButton.addTarget(self, action: #selector(SwipeViewController.touchEndCameraButton), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        
        tabView.leftButton.addTarget(self, action: #selector(SwipeViewController.tapLeftButton), forControlEvents: [.TouchDown])
        tabView.rightButton.addTarget(self, action: #selector(SwipeViewController.tapRightButton), forControlEvents: [.TouchDown])
        
        imagePicker.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openGallary(){
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.barTintColor = UIColor(hex:0x343434)
        imagePicker.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        imagePicker.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        imagePicker.setNavigationBarHidden(false, animated: false)
        imagePicker.interactivePopGestureRecognizer?.enabled = false
        
        leftViewController.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func uploadTheta(thetaImage:UIImage) {
        
        let createOptographViewController = SaveThetaViewController(thetaImage:thetaImage)
        
        createOptographViewController.hidesBottomBarWhenPushed = true
        leftViewController.pushViewController(createOptographViewController, animated: false)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if pickedImage.size.height == 2688 && pickedImage.size.width == 5376 {
                uploadTheta(pickedImage)
            } else {
                isThetaImage.value = true
            }
        }
        
        leftViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        leftViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    func hideUI() {
        tabView.hidden = true
    }
    
    dynamic private func tapLeftButton() {
        //delegate?.didTapLeftButton()
        self.openGallary()

    }
    
    dynamic private func tapRightButton() {
        delegate?.didTapRightButton()
    }
    
    dynamic private func tapCameraButton() {
        delegate?.didTapCameraButton()
    }
    
//    dynamic private func touchStartCameraButton() {
//        delegate?.didTouchStartCameraButton()
//    }
//    dynamic private func touchEndCameraButton() {
//        delegate?.didTouchEndCameraButton()
//    }
    
}

class TButton: UIButton {
    
    enum Color { case Light, Dark }
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    var icon: UIImage = UIImage(named:"photo_library_icn")! {
        didSet {
            setImage(icon, forState: .Normal)
        }
    }
    
    var color: Color = .Dark {
        didSet {
            let actualColor = color == .Dark ? .whiteColor() : UIColor(0x919293)
            setTitleColor(actualColor, forState: .Normal)
            text.textColor = actualColor
            loadingView.color = actualColor
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
    
    private let text = UILabel()
    private let loadingView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(28)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .whiteColor()
        text.textAlignment = .Center
        addSubview(text)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textWidth: CGFloat = 50
        text.frame = CGRect(x: (frame.width - textWidth) / 2, y: frame.height + 10, width: textWidth, height: 11)
        
        loadingView.fillSuperview()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 10
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
    
}


class RecButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var icon: UIImage = UIImage(named:"camera_icn")! {
        didSet {
            setImage(icon, forState: .Normal)
        }
    }
    
    var iconColor: UIColor = .whiteColor() {
        didSet {
            setTitleColor(iconColor.alpha(loading ? 0 : 1), forState: .Normal)
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
    var progressLocked = false {
        didSet {
            if !progressLocked {
                // reapply last progress value
                let tmp = progress
                progress = tmp
            }
        }
    }
    
    var progress: CGFloat? = nil {
        didSet {
            if !progressLocked {
                if let progress = progress {
                    backgroundColor = UIColor.Accent.mixWithColor(.blackColor(), amount: 0.3).alpha(0.5)
                    loading = progress != 1
                    
                    //                    if progress == 0 {
                    //                        icon = .Camera
                    //                    } else if progress == 1 {
                    //                        icon = .Next
                    //                    }
                } else {
                    backgroundColor = UIColor.Accent
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        progressLayer.backgroundColor = UIColor.Accent.CGColor
        layer.addSublayer(progressLayer)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        backgroundColor = UIColor.clearColor()
        clipsToBounds = true
        
        layer.cornerRadius = 12
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(33)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * (progress ?? 0), height: frame.height)
        loadingView.fillSuperview()
    }
}

protocol TabControlDelegate {
    var tabControllers: SwipeViewController? { get }
    func didJumpToTop()
    //func didScrollToOptograph(optographID: UUID)
    //func didTouchStartCameraButton()
    //func didTouchEndCameraButton()
    func didTapCameraButton()
    func didTapLeftButton()
    func didTapRightButton()
}

extension TabControlDelegate {
    func didJumpToTop() {}
    //func didScrollToOptograph(optographID: UUID) {}
    //func didTouchStartCameraButton() {}
    //func didTouchEndCameraButton() {}
    func didTapCameraButton() {}
    func didTapLeftButton() {}
    func didTapRightButton() {}
}

protocol DTControllerDelegate: TabControlDelegate {}


extension DTControllerDelegate {
    
    func didTapCameraButton() {
        switch PipelineService.stitchingStatus.value {
        case .Idle:
          self.tabControllers!.navigationController!.pushViewController(CameraViewController(), animated: false)
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        //tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optographID):
            //didScrollToOptograph(optographID)
            PipelineService.stitchingStatus.value = .Idle
        case .Uninitialized: ()
        }
    }
    
    func didTapLeftButton() {
        print("onTapLeftButton")
        self.tabControllers!.openGallary()
    }
    
    func didTapRightButton() {
        print("ontaprightbutton")
    }
}
extension UIViewController {
    var tabControl: SwipeViewController? {
        return navigationController?.parentViewController as? SwipeViewController
    }
    
    func viewUpdateTabs() {
        tabControl!.tabView.leftButton.title = "HOME"
        //tabControl!.tabView.leftButton.icon = .Home
        tabControl!.tabView.leftButton.hidden = false
        tabControl!.tabView.leftButton.color = .Dark
        
        tabControl!.tabView.rightButton.title = "PROFILE"
        //tabControl!.tabView.rightButton.icon = .User
        tabControl!.tabView.rightButton.hidden = false
        tabControl!.tabView.rightButton.color = .Dark
        
        //tabControl!.tabView.cameraButton.icon = .Camera
        tabControl!.tabView.cameraButton.iconColor = .whiteColor()
        tabControl!.tabView.cameraButton.backgroundColor = .Accent
        
        tabController!.bottomGradientOffset.value = 126
    }
    
    func cleanup() {}
}

extension UINavigationController {
    
    override func cleanup() {
        for vc in viewControllers ?? [] {
            vc.cleanup()
        }
    }
}
