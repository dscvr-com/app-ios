//
//  CommentSchema.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct CommentSchemaType: ModelSchema {
    let id = Expression<Int>("comment_id")
    let text = Expression<String>("comment_text")
    let createdAt = Expression<NSDate>("comment_created_at")
    let personId = Expression<Int>("comment_person_id")
    let optographId = Expression<Int>("comment_optograph_id")
}

let CommentSchema = CommentSchemaType()
let CommentTable = Table("comment")