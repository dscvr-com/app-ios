//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct CommentSchemaType: ModelSchema {
    let id = Expression<UUID>("comment_id")
    let text = Expression<String>("comment_text")
    let createdAt = Expression<NSDate>("comment_created_at")
    let personId = Expression<UUID>("comment_person_id")
    let optographId = Expression<UUID>("comment_optograph_id")
}

let CommentSchema = CommentSchemaType()
let CommentTable = Table("comment")

func CommentMigration() -> String {
    return CommentTable.create { t in
        t.column(CommentSchema.id, primaryKey: true)
        t.column(CommentSchema.text)
        t.column(CommentSchema.createdAt)
        t.column(CommentSchema.personId)
        t.column(CommentSchema.optographId)
    }
}