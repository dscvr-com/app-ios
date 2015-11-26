//
//  LoginViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class LoginViewModel {
    
    enum Tab { case SignUp, LogIn }
    
    let emailOrUserName = MutableProperty<String>("")
    let emailOrUserNameValid = MutableProperty<Bool>(false)
    let password = MutableProperty<String>("")
    let passwordValid = MutableProperty<Bool>(false)
    let allowed = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    let facebookPending = MutableProperty<Bool>(false)
    let selectedTab = MutableProperty<Tab>(.SignUp)
    
    init() {
        
        emailOrUserNameValid <~ emailOrUserName.producer
            .map { $0.rangeOfString("@") != nil ? isValidEmail($0) : isValidUserName($0) }
            .skipRepeats()
        
        passwordValid <~ password.producer
            .map(isValidPassword)
            .skipRepeats()
        
        allowed <~ emailOrUserNameValid.producer.combineLatestWith(passwordValid.producer).map(and)
    }
    
    deinit {
        logRetain()
    }
    
    func submit() -> SignalProducer<Void, ApiError> {
        
        let usesEmail = emailOrUserName.value.rangeOfString("@") != nil
        let identifier = usesEmail ? LoginIdentifier.Email(emailOrUserName.value) : LoginIdentifier.UserName(emailOrUserName.value)
        let signalProducer: SignalProducer<Void, ApiError>
        
        if case .LogIn = selectedTab.value {
            signalProducer = SessionService.login(identifier, password: password.value)
        } else {
            let parameters = [
                "email": emailOrUserName.value,
                "password": password.value,
            ]
            signalProducer = ApiService<EmptyResponse>.post("persons", parameters: parameters)
                .flatMap(.Latest) { _ in SessionService.login(identifier, password: self.password.value) }
        }
        
        return signalProducer
                .on(
                    started: { [weak self] in
                        self?.pending.value = true
                    },
                    next: { [weak self] _ in
                        self?.pending.value = false
                    },
                    error: { [weak self] _ in
                        self?.pending.value = false
                    }
                )
                .mapError { _ in ApiError.Nil }
                .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
    func facebookSignin(userID: String, token: String) -> SignalProducer<Void, ApiError> {
        let parameters = [
            "facebook_user_id": userID,
            "facebook_token": token,
        ]
        return ApiService<LoginMappable>.post("persons/facebook/signin", parameters: parameters)
            .flatMap(.Latest) { SessionService.handleSignin($0) }
            .on(
                error: { [weak self] _ in
                    self?.facebookPending.value = false
                },
                completed: { [weak self] in
                    self?.facebookPending.value = false
                }
            )
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}