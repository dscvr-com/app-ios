//
//  OverlayViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 30/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import FBSDKLoginKit
import SwiftyUserDefaults

class LoginOverlayViewController: UIViewController{
    
    private let logoImageView = UIImageView()
    private let facebookButtonView = UIButton()
    
    private let contentView = UIView()
    
    private let viewModel = LoginOverlayViewModel()
    
    var actInd = UIActivityIndicatorView()
    
    init() {
        
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .OverCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBarHidden = true
        
        contentView.frame = UIScreen.mainScreen().bounds
        contentView.backgroundColor = UIColor(hex:0xf7f7f7)
        view.addSubview(contentView)
        
        let imageSize = UIImage(named: "logo_big")
        logoImageView.image = UIImage(named: "logo_big")
        contentView.addSubview(logoImageView)
        
        //facebookButtonView.rac_loading <~ viewModel.facebookPending
        facebookButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.facebook)))
        facebookButtonView.setBackgroundImage(UIImage(named:"facebook_btn"), forState: .Normal)
        contentView.addSubview(facebookButtonView)
        
        logoImageView.anchorToEdge(.Top, padding: 200, width: imageSize!.size.width, height: imageSize!.size.height)
        facebookButtonView.align(.UnderCentered, relativeTo: logoImageView, padding: 30, width: contentView.frame.width - 85, height: 50)
        
        showActivityIndicatory(contentView)
    }
    
    func showActivityIndicatory(uiView: UIView) {
        actInd.hidesWhenStopped = true
        actInd.center = view.center
        actInd.stopAnimating()
        uiView.addSubview(actInd)
    }
    
    func sendCheckElite() -> SignalProducer<RequestCodeApiModel, ApiError> {
        
        self.actInd.startAnimating()
        
        let parameters = ["uuid": SessionService.personID]
        return ApiService<RequestCodeApiModel>.postForGate("api/check_status", parameters: parameters)
            .on(next: { data in
                print(data.message)
                print(data.status)
                print(data.request_text)
                
                self.actInd.stopAnimating()
                
                if (data.status == "ok" && data.message == "3") {
                    Defaults[.SessionEliteUser] = true
                } else {
                    Defaults[.SessionEliteUser] = false
                }
                
            })
    }
    func checkElite() {
        sendCheckElite().start()
    }
    
    dynamic private func facebook() {
        let loginManager = FBSDKLoginManager()
        let readPermission = ["public_profile","email","user_friends"]
        
        viewModel.facebookPending.value = true
        
        let errorBlock = { [weak self] (message: String) in
            self?.viewModel.facebookPending.value = false
            self?.actInd.stopAnimating()
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            self?.viewModel.facebookSignin(token.userID, token: token.tokenString)
                .on(
                    failed: { _ in
                        loginManager.logOut()
                        self?.actInd.stopAnimating()
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: {
                        Defaults[.SessionUserDidFirstLogin] = true
                        self?.actInd.stopAnimating()
                        self?.checkElite()
                    }
                )
                .start()
        }
        
        loginManager.logInWithReadPermissions(readPermission, fromViewController: self) { [weak self] result, error in
            
            if error != nil || result.isCancelled {
                self?.viewModel.facebookPending.value = false
                loginManager.logOut()
            } else {
                self?.actInd.startAnimating()
                let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
                let allPermissionsGranted = readPermission.reduce(true) { $0 && grantedPermissions.contains($1) }

                if allPermissionsGranted {
                    successBlock(result.token)
                } else {
                    errorBlock("Please allow access to all points in the list. Don't worry, your data will be kept safe.")
                }
            }
        }
    }
    
    
}