//
//  AddUsernameViewController.swift
//  DSCVR
//
//  Created by Thadz on 7/7/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//


///july 08, 2016
///temporarily commented Models.persons.touch(apiModel).insertOrUpdate() (line 34) in SearchTableModel

import UIKit
import ReactiveCocoa
import SwiftyUserDefaults

class AddUsernameViewController: UIViewController, UITextFieldDelegate {
    
    private let viewModel = OnboardingViewModel()
    private var person: [Person] = []
    
    private let contentView = UIView()
    private let logoImageView = UIImageView()
    
    private let username = UITextField()
    private let createButton = UIButton()
    
    private let availability = UILabel()
    
    private var personSQL: Person
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    required init() {
        
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] ==- Defaults[.SessionPersonID]!)
        personSQL = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL)!
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.frame = UIScreen.mainScreen().bounds
        contentView.backgroundColor = UIColor(hex:0x444444)
        view.addSubview(contentView)
        
        let imageSize = UIImage(named: "logo_big")
        logoImageView.image = UIImage(named: "logo_big")
        contentView.addSubview(logoImageView)
        
        logoImageView.anchorToEdge(.Top, padding: 125, width: imageSize!.size.width, height: imageSize!.size.height)
        
        username.delegate = self
        
        username.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width - 80.0, height: 44.0)
        username.backgroundColor = UIColor.darkGrayColor()
        username.center = contentView.center
        username.borderStyle = UITextBorderStyle.RoundedRect
        username.font = UIFont(name: "Avenir-Heavy", size: 15)
        username.textColor = UIColor(hex:0xffd24e)
        username.autocorrectionType = UITextAutocorrectionType.No
        username.autocapitalizationType = UITextAutocapitalizationType.None
        
        let placeholderText = NSLocalizedString("Username", comment: "Username")
        let placeholderString = NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor(white: 0.66, alpha: 1.0),
            NSFontAttributeName: UIFont(name: "Avenir-Book", size: 15)!])
        
        username.attributedPlaceholder = placeholderString
        
        username.layer.cornerRadius = 7.0
        username.layer.borderWidth = 1.0
        username.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        contentView.addSubview(username)
        
        let buttonPadding = CGFloat(46.0)
        
        createButton.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width - buttonPadding, height: 44.0)
        createButton.backgroundColor = UIColor.grayColor()
        createButton.center = CGPoint(x: username.center.x, y: username.center.y + username.frame.size.height + buttonPadding)
        createButton.setTitle("CREATE USERNAME", forState: UIControlState.Normal)
        createButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        createButton.titleLabel!.font = UIFont(name: "Avenir-Heavy", size: 15)
        createButton.enabled = false
        createButton.addTarget(self, action: #selector(createUsername), forControlEvents: .TouchUpInside)
        
        createButton.layer.cornerRadius = 7.0
        
        contentView.addSubview(createButton)
        
        let createLabel = UILabel()
        createLabel.text = "Create your username:"
        createLabel.font = UIFont(name: "Avenir-Heavy", size: 15)
        createLabel.textColor = UIColor.whiteColor()
        createLabel.sizeToFit()
        
        createLabel.frame = CGRect(x: 20.0, y: username.frame.origin.y - (createLabel.frame.size.height * 1.5), width: createLabel.frame.size.width, height: createLabel.frame.size.height)
        contentView.addSubview(createLabel)
        
        let atLabel = UILabel()
        atLabel.text = "@"
        atLabel.font = UIFont(name: "Avenir-Heavy", size: 32)
        atLabel.textColor = UIColor.whiteColor()
//        atLabel.textAlignment = NSTextAlignment.Center
        atLabel.frame = CGRect(x: createLabel.frame.origin.x, y: username.frame.origin.y, width: username.frame.size.height, height: username.frame.size.height)
        
        contentView.addSubview(atLabel)
        
        availability.frame = CGRect(x: atLabel.frame.origin.x + atLabel.frame.size.width, y: username.frame.origin.y + username.frame.size.height + 10.0, width: 0, height: 0)
        availability.font = UIFont(name: "Avenir-Book", size: 12.0)
        
        contentView.addSubview(availability)
        
        username.frame = CGRect(x: atLabel.frame.origin.x + atLabel.frame.size.width, y: atLabel.frame.origin.y, width: contentView.frame.size.width - (40.0 + atLabel.frame.size.width), height: 44.0)
        
        viewModel.results.producer
            .on(
                next: { people in
                    
                    self.person = people
                    
                    if self.person.count > 0{
                        if self.person[0].userName == "" {
                            print("string available")
                            self.createButton.enabled = true
                            self.createButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
                            self.createButton.backgroundColor = UIColor(hex:0xffd24e)
                            self.availability.text = "Username is available"
                            self.availability.textColor = UIColor(hex:0xffd24e)
                        } else {
                            print("string exists")
                            self.createButton.enabled = false
                            self.createButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
                            self.createButton.backgroundColor = UIColor.grayColor()
                            self.availability.text = "Username is taken"
                            self.availability.textColor = UIColor.whiteColor()
                        }
                        self.availability.sizeToFit()
                    }
                }
            )
            .start()
        
        viewModel.nameOk.producer.startWithNext{ val in
            if val {
                print("string available")
                self.insertStatusText("Username is available")
            }
        }
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeKeyboard)))
        
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        activityIndicator.stopAnimating()
        contentView.addSubview(activityIndicator)
    }
    
    func insertStatusText(str:String) {
        self.createButton.enabled = true
        self.createButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        self.createButton.backgroundColor = UIColor(hex:0xffd24e)
        self.availability.text = str
        self.availability.textColor = UIColor(hex:0xffd24e)
        self.availability.sizeToFit()
    
    }
    
    func createUsername() {
        updateData().start()
    }
    
    func closeKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.setHidesBackButton(true, animated:true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationItem.setHidesBackButton(false, animated:true)
    }
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        
        let parameters = [
            "display_name": viewModel.searchText.value,
            "user_name": viewModel.searchText.value,
            "onboarding_version": OnboardingVersion,
            ] as [String: AnyObject]
        
        return ApiService.put("persons/me", parameters: parameters)
            .on(
                started: {
                    print("updating")
                    self.activityIndicator.startAnimating()
                },
                completed: {
                    self.personSQL.displayName = self.viewModel.searchText.value
                    self.personSQL.userName = self.viewModel.searchText.value
                    Defaults[.SessionOnboardingVersion] = OnboardingVersion
                    self.saveModel()
                    self.activityIndicator.stopAnimating()
                },
                failed: { error in
                    print(error)
                    self.activityIndicator.stopAnimating()
                }
        )
    }
    
    private func saveModel() {
        try! personSQL.insertOrUpdate()
        self.sendAlert("Username updated successfully!")
    }
    
    func sendAlert(message:String) {
        let alert = UIAlertController(title: "Welcome to DSCVR!", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in
            self.navigationController?.popViewControllerAnimated(true)
            
            return
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var updatedTextString : NSString = textField.text! as NSString
        updatedTextString = updatedTextString.stringByReplacingCharactersInRange(range, withString: string)
        
        print("updated string: \(updatedTextString)")
        
        if updatedTextString.length <= 12 {
            if updatedTextString.length >= 5{
                if isValidUserName(updatedTextString as String) {
                    createButton.enabled = false
                    viewModel.searchText.value = updatedTextString as String
                } else {
                    self.insertStatusText("Username is invalid!")
                    return false
                }
                
            }
            return true
        } else {
            return false
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        print("username is editing")
    }
}
