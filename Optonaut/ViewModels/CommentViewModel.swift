//
//  CommentViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CommentViewModel {
    
    let text: ConstantProperty<String>
    let avatarUrl: ConstantProperty<String>
    let fullName: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let personId: ConstantProperty<Int>
    let timeSinceCreated = MutableProperty<String>("")
    
    init(comment: Comment) {
        text = ConstantProperty(comment.text)
        avatarUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/avatars/\(comment.person!.id % 4).jpg")
        fullName = ConstantProperty(comment.person!.fullName)
        userName = ConstantProperty("@\(comment.person!.userName)")
        personId = ConstantProperty(comment.person!.id)
        timeSinceCreated.value = RoundedDuration(date: comment.createdAt).shortDescription()
    }
    
}