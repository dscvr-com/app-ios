//
//  TabViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
//import Icomoon
import SwiftyUserDefaults
import Result

class TabViewController: UIViewController,UIGestureRecognizerDelegate,UIScrollViewDelegate{
    
    var scrollView: UIScrollView!
    let centerViewController: NavigationController
    let rightViewController: NavigationController
    let leftViewController: NavigationController
    //let fourthViewController: NavigationController
    
    var thisView = UIView()
    var isSettingsViewOpen = MutableProperty<Bool>(false)
    var panGestureRecognizer:UIPanGestureRecognizer!
    var navBarTapGestureRecognizer:UITapGestureRecognizer!
    var inVr:Bool = false
    
    private var motorButton = SettingsButton()
    private var manualButton = SettingsButton()
    private var oneRingButton = SettingsButton()
    private var threeRingButton = SettingsButton()
    private var vrButton = SettingsButton()
    private var pullButton = SettingsButton()
    private var gyroButton = SettingsButton()
    private var littlePlanet = SettingsButton()
    
    enum PageStatus { case Profile, Share, Feed }
    let pageStatus = MutableProperty<PageStatus>(.Feed)
    
    var delegate: TabControllerDelegate?
    
    var BFrame:CGRect   = CGRect (
        origin: CGPoint(x: 0, y: 0),
        size: UIScreen.mainScreen().bounds.size
    )
    var adminFrame :CGRect = CGRect (
        origin: CGPoint(x: 0, y: 0),
        size: UIScreen.mainScreen().bounds.size
    )
    
    var fourthFrame:CGRect   = CGRect (
        origin: CGPoint(x: 0, y: 0),
        size: UIScreen.mainScreen().bounds.size
    )
    
    let labelRing1 = UILabel()
    let labelRing3 = UILabel()
    let labelManual = UILabel()
    let labelMotor = UILabel()
    let labelGyro = UILabel()
    let planet = UILabel()
//    let motor1 = UILabel()
//    let mButtonUp = UIButton()
//    let mButtonDown = UIButton()
    
    var lastContentOffset:CGFloat = 0
//    var motor1Val:CGFloat = 0
//    var motor2Val:CGFloat = 0
//    
//    let motor2 = UILabel()
//    let m2ButtonUp = UIButton()
//    let m2ButtonDown = UIButton()
    
    let shareData = ShareData.sharedInstance
    
    required init() {
        
        centerViewController = FeedNavViewController()
        rightViewController =  ProfileNavViewController()
        leftViewController = SharingNavViewController()
        //fourthViewController = StNavViewController()
    
        
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
        self.scrollView!.contentSize = CGSizeMake(scrollWidth, scrollHeight)
        self.scrollView!.pagingEnabled = true;
        
        self.addChildViewController(centerViewController)
        self.scrollView!.addSubview(centerViewController.view)
        centerViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(leftViewController)
        self.scrollView!.addSubview(leftViewController.view)
        leftViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(rightViewController)
        self.scrollView!.addSubview(rightViewController.view)
        rightViewController.didMoveToParentViewController(self)
        
//        self.addChildViewController(fourthViewController)
//        self.scrollView!.addSubview(fourthViewController.view)
//        fourthViewController.didMoveToParentViewController(self)
        
        adminFrame = leftViewController.view.frame
        adminFrame.origin.x = adminFrame.width
        centerViewController.view.frame = adminFrame
        
        BFrame = centerViewController.view.frame
        BFrame.origin.x = 2*BFrame.width
        rightViewController.view.frame = BFrame
        
//        fourthFrame = centerViewController.view.frame
//        fourthFrame.origin.x =  3 * BFrame.width
//        fourthViewController.view.frame = fourthFrame
        
        view.addSubview(scrollView)
        
        scrollView.scrollRectToVisible(adminFrame,animated: false)
        
        self.settingsView()
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TabViewController.handlePan(_:)))
        self.centerViewController.navigationBar.addGestureRecognizer(panGestureRecognizer)
        
        navBarTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TabViewController.tapNavBarTitle(_:)))
        self.centerViewController.navigationBar.addGestureRecognizer(navBarTapGestureRecognizer)
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        
        if (!Defaults[.SessionUserDidFirstLogin]) {
            scrollView.contentOffset.x = self.view.frame.width * 2
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    func disableNavBarGesture(){
        panGestureRecognizer.enabled = false
        navBarTapGestureRecognizer.enabled = false
    }
    func enableNavBarGesture(){
        panGestureRecognizer.enabled = true
        navBarTapGestureRecognizer.enabled = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func scrollViewDidScroll(scrollView:UIScrollView) {
        
        if (!Defaults[.SessionUserDidFirstLogin]) {
            
            if (scrollView.contentOffset.x <= (self.view.frame.width * 2)) {
                scrollView.contentOffset.x = self.view.frame.width * 2
            }
        } else {
            if (scrollView.contentOffset.x < self.view.frame.width && !shareData.isSharePageOpen.value) {
                scrollView.contentOffset.x = self.view.frame.width
            } else if (scrollView.contentOffset.x >= self.view.frame.width && shareData.isSharePageOpen.value) {
                shareData.isSharePageOpen.value = false
            }
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (scrollView.contentOffset.x >= self.view.frame.width && scrollView.contentOffset.x < (self.view.frame.width * 2)) {
            scrollView.contentOffset.x = self.view.frame.width
        }
        
        if scrollView.contentOffset.x == self.view.frame.width {
            print("nasa feed ka")
            pageStatus.value = .Feed
        } else if scrollView.contentOffset.x == 0 {
            print("nasa share ka")
            pageStatus.value = .Share
        } else {
            print("nasa profile ka")
            pageStatus.value = .Profile
        }
    }
    
    func rightButtonAction() {
        UIView.animateWithDuration(0.5, animations: {
            self.scrollView.scrollRectToVisible(self.BFrame,animated: false)
            }, completion:{ _ in
                print("nasa profile ka")
                self.pageStatus.value = .Profile
        })
    }
    
    func leftButtonAction() {
        UIView.animateWithDuration(0.5, animations: {
            self.scrollView.scrollRectToVisible(self.adminFrame,animated: false)
            }, completion:{ _ in
                print("nasa feed ka")
                self.pageStatus.value = .Feed
        })
    }
    
    func disableScrollView() {
        scrollView.scrollEnabled = false;
    }
    
    func enableScrollView() {
        scrollView.scrollEnabled = true;
    }
    
    func swipeLeftView(xPoint:CGFloat) {
        
        self.scrollView.scrollRectToVisible(CGRect(x: self.view.frame.width - xPoint,y: 0,width:xPoint,height: self.view.frame.height),animated: false)
    }
    
    func swipeRightView() {
        scrollView.scrollRectToVisible(BFrame,animated: false)
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
    
    func settingsView() {
        
        thisView.frame = CGRectMake(0, -(view.frame.height), view.frame.width, view.frame.height)
        thisView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(thisView)
        
        let titleSettings = UILabel()
        titleSettings.text = "Settings"
        titleSettings.textAlignment = .Center
        titleSettings.textColor = UIColor(hex:0x3E3D3D)
        titleSettings.font = .fontDisplay(25, withType: .Light)
        thisView.addSubview(titleSettings)
        titleSettings.anchorToEdge(.Top, padding: 30, width: calcTextWidth(titleSettings.text!, withFont: .fontDisplay(25, withType: .Light)), height: 30)
        
        let image: UIImage = UIImage(named: "logo_settings")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        thisView.addSubview(bgImage!)
        bgImage!.align(.UnderCentered, relativeTo: titleSettings,padding: 25, width: image.size.width, height: image.size.height)
        
        let textHeight = calcTextHeight("VR IMAGE VIEW STYLE", withWidth: calcTextWidth("VR IMAGE VIEW STYLE", withFont: .fontDisplay(12, withType: .Light)), andFont: .fontDisplay(12, withType: .Semibold))
        	
        let vrImageLabel = UILabel()
        vrImageLabel.frame = CGRect(x: 70,y: bgImage!.frame.origin.y + (bgImage?.frame.height)! + 20 ,width: calcTextWidth("VR IMAGE VIEW STYLE", withFont: .fontDisplay(12, withType: .Semibold)),height: textHeight)
        vrImageLabel.text = "VR IMAGE VIEW STYLE"
        vrImageLabel.textAlignment = .Center
        vrImageLabel.textColor = UIColor.blackColor()
        vrImageLabel.font = .fontDisplay(12, withType: .Semibold)
        thisView.addSubview(vrImageLabel)
        
        let dividerFour = UILabel()
        dividerFour.backgroundColor = UIColor(hex:0xa5a5a5)
        thisView.addSubview(dividerFour)
        dividerFour.frame = CGRect(x: 70 + gyroButton.icon.size.width + 12 ,y: vrImageLabel.frame.origin.y + vrImageLabel.frame.height+2,width: 1,height: 12)
        
        let vrText = UILabel()
//        vrText.frame = CGRect(x: 38,y: titleSettings.frame.origin.y + 30+50,width: calcTextWidth("VIEW IAM360 IN", withFont: .fontDisplay(18, withType: .Semibold)),height: 30)
        vrText.text = "VIEW 360 IMAGE IN"
        vrText.textAlignment = .Center
        vrText.textColor = UIColor.grayColor()
        vrText.font = .fontDisplay(18, withType: .Semibold)
        thisView.addSubview(vrText)
        vrText.align(.UnderMatchingLeft, relativeTo: vrImageLabel, padding: 16, width: calcTextWidth("VIEW 360 IMAGE IN", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        
        let dividerFive = UILabel()
        dividerFive.backgroundColor = UIColor(hex:0xa5a5a5)
        thisView.addSubview(dividerFive)
        dividerFive.align(.UnderCentered, relativeTo: dividerFour, padding: 29, width:1, height: 12)
        
        thisView.addSubview(vrButton)
        vrButton.addTarget(self, action: #selector(TabViewController.inVrMode), forControlEvents:.TouchUpInside)
        vrButton.align(.ToTheRightCentered, relativeTo: vrText, padding: 8, width: vrButton.icon.size.width, height: vrButton.icon.size.width)
        
        let labelCamera = UILabel()
        labelCamera.textAlignment = NSTextAlignment.Center
        labelCamera.text = "FEED DEFAULT DISPLAY"
        labelCamera.font = .fontDisplay(12, withType: .Semibold)
        labelCamera.textColor = UIColor.blackColor()
        thisView.addSubview(labelCamera)
        labelCamera.align(.UnderMatchingLeft, relativeTo: vrText, padding: 14, width: calcTextWidth("FEED DEFAULT DISPLAY", withFont: .fontDisplay(12, withType: .Semibold)), height: textHeight)
        
        let dividerOneHeight:CGFloat = 100
        
        let dividerOne = UILabel()
        dividerOne.backgroundColor = UIColor(hex:0xa5a5a5)
        thisView.addSubview(dividerOne)
        dividerOne.align(.UnderCentered, relativeTo: dividerFive, padding: textHeight+4, width:1, height: 50)
        
        gyroButton.addTarget(self, action: #selector(TabViewController.inGyroMode), forControlEvents:.TouchUpInside)
        thisView.addSubview(gyroButton)
        gyroButton.align(.UnderMatchingLeft, relativeTo: labelCamera, padding: 2, width: gyroButton.icon.size.width, height: gyroButton.icon.size.height)
        
        
        labelGyro.textAlignment = NSTextAlignment.Center
        labelGyro.textColor = UIColor.blackColor()
        labelGyro.text = "GYRO"
        labelGyro.font = .fontDisplay(18, withType: .Semibold)
        thisView.addSubview(labelGyro)
        labelGyro.align(.ToTheRightCentered, relativeTo: gyroButton, padding: 24, width: calcTextWidth("GYRO", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        
        littlePlanet.addTarget(self, action: #selector(TabViewController.littlePlanetButtonTouched), forControlEvents:.TouchUpInside)
        //thisView.addSubview(littlePlanet)
        littlePlanet.align(.UnderCentered, relativeTo: gyroButton, padding: 7, width: littlePlanet.icon.size.width, height: littlePlanet.icon.size.height)
        
        planet.textAlignment = NSTextAlignment.Center
        planet.textColor = UIColor.blackColor()
        planet.text = "LITTLE PLANET"
        planet.font = .fontDisplay(18, withType: .Semibold)
        //thisView.addSubview(planet)
        planet.align(.ToTheRightCentered, relativeTo: littlePlanet, padding: 24, width: calcTextWidth("LITTLE PLANET", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        
        let labelMode = UILabel()
        labelMode.textAlignment = NSTextAlignment.Center
        labelMode.textColor = UIColor.blackColor()
        labelMode.text = "CAPTURE MODE"
        labelMode.font = .fontDisplay(12, withType: .Semibold)
        thisView.addSubview(labelMode)
//        labelMode.align(.UnderMatchingLeft, relativeTo: littlePlanet, padding: 4, width: calcTextWidth("CAPTURE MODE", withFont: .fontDisplay(12, withType: .Semibold)), height: textHeight)
         labelMode.align(.UnderMatchingLeft, relativeTo: gyroButton, padding: 4, width: calcTextWidth("CAPTURE MODE", withFont: .fontDisplay(12, withType: .Semibold)), height: textHeight)
        
        let dividerTwo = UILabel()
        dividerTwo.backgroundColor = UIColor(hex:0xa5a5a5)
        thisView.addSubview(dividerTwo)
        dividerTwo.align(.UnderCentered, relativeTo: dividerOne, padding: textHeight+2, width:1, height: dividerOneHeight)
        
        oneRingButton.addTarget(self, action: #selector(TabViewController.oneRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(oneRingButton)
        oneRingButton.align(.ToTheLeftMatchingTop, relativeTo: dividerTwo, padding: 12, width: oneRingButton.icon.size.width, height: oneRingButton.icon.size.height)
        
        labelRing1.textAlignment = NSTextAlignment.Center
        labelRing1.text = "ONE RING"
        labelRing1.font = .fontDisplay(18, withType: .Semibold)
        thisView.addSubview(labelRing1)
        labelRing1.align(.ToTheRightCentered, relativeTo: oneRingButton, padding: 24, width: calcTextWidth("ONE RING", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        
        threeRingButton.align(.UnderCentered, relativeTo: oneRingButton, padding: 7, width: threeRingButton.icon.size.width, height: threeRingButton.icon.size.height)
        threeRingButton.addTarget(self, action: #selector(TabViewController.threeRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(threeRingButton)
        
        labelRing3.textAlignment = NSTextAlignment.Center
        labelRing3.text = "THREE RING"
        labelRing3.font = .fontDisplay(18, withType: .Semibold)
        labelRing3.align(.ToTheRightCentered, relativeTo: threeRingButton, padding: 24, width: calcTextWidth("THREE RING", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        thisView.addSubview(labelRing3)
        
        let labelCapture = UILabel()
        labelCapture.textAlignment = NSTextAlignment.Center
        labelCapture.text = "CAPTURE TYPE"
        labelCapture.textColor = UIColor.blackColor()
        labelCapture.font = .fontDisplay(12, withType: .Semibold)
        thisView.addSubview(labelCapture)
        labelCapture.align(.UnderMatchingLeft, relativeTo: threeRingButton, padding: 4, width: calcTextWidth("CAPTURE TYPE", withFont: .fontDisplay(12, withType: .Semibold)), height: textHeight)
        
        let dividerThree = UILabel()
        dividerThree.backgroundColor = UIColor(hex:0xa5a5a5)
        thisView.addSubview(dividerThree)
        dividerThree.align(.UnderCentered, relativeTo: dividerTwo, padding: textHeight+4, width:1, height: dividerOneHeight)
        
        manualButton.addTarget(self, action: #selector(TabViewController.manualButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(manualButton)
        manualButton.align(.ToTheLeftMatchingTop, relativeTo: dividerThree, padding: 12, width: manualButton.icon.size.width, height: manualButton.icon.size.height)
        
        labelManual.textAlignment = NSTextAlignment.Center
        labelManual.text = "MANUAL"
        labelManual.textColor = UIColor(hex:0xFF5E00)
        labelManual.font = .fontDisplay(18, withType: .Semibold)
        thisView.addSubview(labelManual)
        labelManual.align(.ToTheRightCentered, relativeTo: manualButton, padding: 24, width: calcTextWidth("MANUAL", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        
        motorButton.addTarget(self, action: #selector(TabViewController.motorButtonTouched), forControlEvents:.TouchUpInside)
        motorButton.align(.UnderCentered, relativeTo: manualButton, padding: 7, width: motorButton.icon.size.width, height: motorButton.icon.size.height)
        thisView.addSubview(motorButton)
        
        labelMotor.textAlignment = NSTextAlignment.Center
        labelMotor.text = "MOTOR"
        labelMotor.textColor = UIColor(hex:0xFF5E00)
        labelMotor.font = .fontDisplay(18, withType: .Semibold)
        labelMotor.align(.ToTheRightCentered, relativeTo: motorButton, padding: 24, width: calcTextWidth("MOTOR", withFont: .fontDisplay(18, withType: .Semibold)), height: 25)
        thisView.addSubview(labelMotor)
        
        isSettingsViewOpen.producer.startWithNext{ val in
            if val {
                self.activeRingButtons(Defaults[.SessionUseMultiRing])
                self.activeModeButtons(Defaults[.SessionMotor])
                self.activeVrMode()
                self.activeDisplayButtons(Defaults[.SessionGyro])
            }
        }

        pullButton.icon = UIImage(named:"arrow_pull")!
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TabViewController.handlePan(_:)))
        
        thisView.addGestureRecognizer(panGestureRecognizer)
        
        thisView.addSubview(pullButton)
        pullButton.anchorToEdge(.Bottom, padding: 5, width: 20, height: 15)
        
        let pullView = UIView()
        pullView.backgroundColor = UIColor.clearColor()
        thisView.addSubview(pullView)
        pullView.anchorToEdge(.Bottom, padding: 0, width: 60, height: 35)
        
        pullView.addGestureRecognizer(panGestureRecognizer)
        pullView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pullButtonTap(_:))))
        
//        for family: String in UIFont.familyNames()
//        {
//            print("\(family)")
//            for names: String in UIFont.fontNamesForFamilyName(family)
//            {
//                print("== \(names)")
//            }
//        }
        labelCapture.hidden = true
        labelManual.hidden = true
        labelMotor.hidden = true
        manualButton.hidden = true
        motorButton.hidden = true
        dividerThree.hidden = true
        
        let versionLabel = UILabel()
        versionLabel.text = "v0.95"
        versionLabel.textAlignment = .Center
        versionLabel.font = .fontDisplay(10, withType: .Semibold)
        versionLabel.align(.UnderMatchingRight, relativeTo: bgImage!, padding: 2, width: 40, height: 10)
        thisView.addSubview(versionLabel)
        
//        motor1.text = "value"
//        motor1.backgroundColor = UIColor.lightGrayColor()
//        thisView.addSubview(motor1)
//        
//        mButtonUp.backgroundColor = UIColor.yellowColor()
//        mButtonUp.addTarget(self, action: #selector(TabViewController.motorButtonUp), forControlEvents:.TouchUpInside)
//        thisView.addSubview(mButtonUp)
//        
//        mButtonDown.backgroundColor = UIColor.redColor()
//        mButtonDown.addTarget(self, action: #selector(TabViewController.motorButtonDown), forControlEvents:.TouchUpInside)
//        thisView.addSubview(mButtonDown)
//        
//        motor1.align(.UnderMatchingLeft, relativeTo: threeRingButton, padding: 40, width: (view.frame.width * 0.5), height: 40)
//        mButtonUp.align(.ToTheRightMatchingTop, relativeTo: motor1, padding: 2, width: 30, height: 19)
//        mButtonDown.align(.ToTheRightMatchingBottom, relativeTo: motor1, padding: 2, width: 30, height: 19)
//        
//        motor2.text = "value"
//        motor2.backgroundColor = UIColor.lightGrayColor()
//        thisView.addSubview(motor2)
//        
//        m2ButtonUp.backgroundColor = UIColor.yellowColor()
//        m2ButtonUp.addTarget(self, action: #selector(TabViewController.motor2ButtonUp), forControlEvents:.TouchUpInside)
//        thisView.addSubview(m2ButtonUp)
//        
//        m2ButtonDown.backgroundColor = UIColor.redColor()
//        m2ButtonDown.addTarget(self, action: #selector(TabViewController.motor2ButtonDown), forControlEvents:.TouchUpInside)
//        thisView.addSubview(m2ButtonDown)
//        
//        motor2.align(.UnderMatchingLeft, relativeTo: motor1, padding: 40, width: (view.frame.width * 0.5), height: 40)
//        m2ButtonUp.align(.ToTheRightMatchingTop, relativeTo: motor2, padding: 2, width: 30, height: 19)
//        m2ButtonDown.align(.ToTheRightMatchingBottom, relativeTo: motor2, padding: 2, width: 30, height: 19)
    }
    
//    func motorButtonUp() {
//        motor1Val += 1
//        motor1.text = "motor1: \(motor1Val)"
//        Defaults[.SessionBPS] = "\(motor1Val)"
//    }
//    
//    func motorButtonDown() {
//        motor1Val -= 1
//        motor1.text = "motor1: \(motor1Val)"
//        Defaults[.SessionBPS] = "\(motor1Val)"
//    }
//    
//    func motor2ButtonUp() {
//        motor2Val += 1
//        motor2.text = "motor2: \(motor2Val)"
//        Defaults[.SessionStepCount] = "\(motor2Val)"
//    }
//    
//    func motor2ButtonDown() {
//        motor2Val -= 1
//        motor2.text = "motor2: \(motor2Val)"
//        Defaults[.SessionStepCount] = "\(motor2Val)"
//    }
    
    func inGyroMode() {
        if Defaults[.SessionGyro] {
            gyroButton.icon = UIImage(named: "gyro_inactive_icn")!
            Defaults[.SessionGyro] = false
            labelGyro.textColor = UIColor.grayColor()
        } else {
            gyroButton.icon = UIImage(named: "gyro_active_icn")!
            Defaults[.SessionGyro] = true
            labelGyro.textColor = UIColor(hex:0xFF5E00)
        }
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("gestureRecognizer wew")
        return true
    }
    
    func pullButtonTap(recognizer:UITapGestureRecognizer) {
        
        UIView.animateWithDuration(0.5, animations: {
            self.thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
            }, completion:{ finished in
                self.isSettingsViewOpen.value = false
        })
    }
    func gyroButtonTouched() {
        Defaults[.SessionGyro] = true
        self.activeDisplayButtons(true)
    }
    func littlePlanetButtonTouched() {
        Defaults[.SessionGyro] = false
        self.activeDisplayButtons(false)
    }
    
    
    func motorButtonTouched() {
        Defaults[.SessionMotor] = true
        self.activeModeButtons(true)
    }
    
    func manualButtonTouched() {
        Defaults[.SessionMotor] = false
        self.activeModeButtons(false)
    }
    
    func oneRingButtonTouched() {
        Defaults[.SessionUseMultiRing] = false
        self.activeRingButtons(false)
    }
    
    func threeRingButtonTouched() {
        Defaults[.SessionUseMultiRing] = true
        self.activeRingButtons(true)
    }
    func inVrMode() {
        if Defaults[.SessionVRMode] {
            vrButton.icon = UIImage(named: "vr_inactive_btn")!
            Defaults[.SessionVRMode] = false
        } else {
            vrButton.icon = UIImage(named: "vr_button")!
            Defaults[.SessionVRMode] = true
        }
    }
    func activeVrMode() {
        if Defaults[.SessionVRMode] {
            vrButton.icon = UIImage(named: "vr_button")!
        } else {
            vrButton.icon = UIImage(named: "vr_inactive_btn")!
        }
    }
    
    func activeModeButtons(isMotor:Bool) {
        if isMotor {
            motorButton.icon = UIImage(named: "motor_active_icn")!
            manualButton.icon = UIImage(named: "manual_inactive_icn")!
            
            labelManual.textColor = UIColor.grayColor()
            labelMotor.textColor = UIColor(hex:0xFF5E00)
        } else {
            motorButton.icon = UIImage(named: "motor_inactive_icn")!
            manualButton.icon = UIImage(named: "manual_active_icn")!
            
            labelManual.textColor = UIColor(hex:0xFF5E00)
            labelMotor.textColor = UIColor.grayColor()
        }
    }
    
    func activeRingButtons(isMultiRing:Bool) {
        
        if isMultiRing {
            threeRingButton.icon = UIImage(named: "threeRing_active_icn")!
            oneRingButton.icon = UIImage(named: "oneRing_inactive_icn")!
            
            labelRing3.textColor = UIColor(hex:0xFF5E00)
            labelRing1.textColor = UIColor.grayColor()
            
        } else {
            threeRingButton.icon = UIImage(named: "threeRing_inactive_icn")!
            oneRingButton.icon = UIImage(named: "oneRing_active_icn")!
            
            labelRing3.textColor = UIColor.grayColor()
            labelRing1.textColor = UIColor(hex:0xFF5E00)
        }
    }
    func activeDisplayButtons(isGyro:Bool) {
        
        if isGyro {
            gyroButton.icon = UIImage(named: "gyro_active_icn")!
            littlePlanet.icon = UIImage(named: "littlePlanet_inactive_icn")!
            
            labelGyro.textColor = UIColor(hex:0xFF5E00)
            planet.textColor = UIColor.grayColor()
            
        } else {
            gyroButton.icon = UIImage(named: "gyro_inactive_icn")!
            littlePlanet.icon = UIImage(named: "littlePlanet_active_icn")!
            
            labelGyro.textColor = UIColor.grayColor()
            planet.textColor = UIColor(hex:0xFF5E00)
        }
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        let translationY = recognizer.translationInView(self.view).y
        var panBegin:CGFloat = 0.0
        
        switch recognizer.state {
        case .Began:
            panBegin = translationY
        case .Changed:
            if !isSettingsViewOpen.value {
                thisView.frame = CGRectMake(0, translationY - self.view.frame.height , self.view.frame.width, self.view.frame.height)
            } else {
                if translationY <= panBegin {
                    thisView.frame = CGRectMake(0,self.view.frame.height - (self.view.frame.height - translationY) , self.view.frame.width, self.view.frame.height)
                }
            }
            
        case .Cancelled:
            print("cancelled")
        case .Ended:
            if !isSettingsViewOpen.value {
                UIView.animateWithDuration(0.5, animations: {
                    self.thisView.frame = CGRectMake(0, 0 , self.view.frame.width, self.view.frame.height)
                    }, completion:{ finished in
                        self.isSettingsViewOpen.value = true
                })
            } else {
                UIView.animateWithDuration(0.5, animations: {
                    self.thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
                    }, completion:{ finished in
                        self.isSettingsViewOpen.value = false
                })
            }
            
        default: break
        }
    }
    func tapNavBarTitleForFeedClass() {
        
        if !isSettingsViewOpen.value {
            UIView.animateWithDuration(0.3, animations: {
                self.thisView.frame = CGRectMake(0, 0 , self.view.frame.width, self.view.frame.height)
                }, completion:{ finished in
                    self.isSettingsViewOpen.value = true
                    
            })
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
                }, completion:{ finished in
                    self.isSettingsViewOpen.value = false
            })
        }
    }
    
    func tapNavBarTitle(recognizer:UITapGestureRecognizer) {
        
        if !isSettingsViewOpen.value{
            UIView.animateWithDuration(0.3, animations: {
                self.thisView.frame = CGRectMake(0, 0 , self.view.frame.width, self.view.frame.height)
                }, completion:{ finished in
                    self.isSettingsViewOpen.value = true
            
            })
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
                }, completion:{ finished in
                    self.isSettingsViewOpen.value = false
            })
        }
    }
    
    
    dynamic private func tapLeftButton() {
        delegate?.onTapLeftButton()
    }
    
    dynamic private func tapRightButton() {
        delegate?.onTapRightButton()
    }
    
    dynamic private func tapCameraButton() {
        delegate?.onTapCameraButton()
    }
    
    dynamic private func touchStartCameraButton() {
        delegate?.onTouchStartCameraButton()
    }
    
    dynamic private func touchEndCameraButton() {
        delegate?.onTouchEndCameraButton()
    }
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
class SettingsButton : UIButton {
    
    var icon: UIImage = UIImage(named:"motor_active_icn")!{
        didSet{
            setImage(icon, forState: .Normal)
        }
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
                    backgroundColor = UIColor.clearColor()
                    loading = progress != 1
                } else {
                    backgroundColor = UIColor.clearColor()
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        //progressLayer.backgroundColor = UIColor.clearColor()
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


protocol TabControllerDelegate {
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
    func swipeToShare()
}

extension TabControllerDelegate {
    func scrollToOptograph(optographID: UUID) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
    func swipeToShare(){}
}

//protocol DefaultTabControllerDelegate: TabControllerDelegate {}
//
//extension DefaultTabControllerDelegate {
//    
//    func onTapCameraButton() {
//        switch PipelineService.stitchingStatus.value {
//        case .Idle:
//            self.tabController!.centerViewController.cleanup()
//            self.tabController?.centerViewController.pushViewController(CameraViewController(), animated: false)
//            
//        case .Stitching(_):
//            
//            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
//            tabController?.centerViewController.presentViewController(alert, animated: true, completion: nil)
//        case let .StitchingFinished(optographID):
//            scrollToOptograph(optographID)
//            PipelineService.stitchingStatus.value = .Idle
//        case .Uninitialized: ()
//        }
//    }
//    func swipeToShare(){
//        print("swipe")
//    }
//    
//    func onTapLeftButton() {
////        if tabController?.activeViewController == tabController?.leftViewController {
////            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
////                jumpToTop()
////            }
////        } else {
////            tabController?.updateActiveTab(.Left)
////        }
//    }
//    
//    func onTapRightButton() {
////        if tabController?.activeViewController == tabController?.rightViewController {
////            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
////                jumpToTop()
////            }
////        } else {
////            tabController?.updateActiveTab(.Right)
////        }
//    }
//}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
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

class PassThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}