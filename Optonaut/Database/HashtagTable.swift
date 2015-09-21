//
//  HashtagTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct HashtagSchemaType: ModelSchema {
    let id = Expression<UUID>("hashtag_id")
    let name = Expression<String>("hashtag_name")
    let previewAssetId = Expression<UUID>("hashtag_preview_asset_id")
    let isFollowed = Expression<Bool>("hashtag_is_followed")
}

let HashtagSchema = HashtagSchemaType()
let HashtagTable = Table("hashtag")

func HashtagMigration() -> String {
    return HashtagTable.create { t in
        t.column(HashtagSchema.id, primaryKey: true)
        t.column(HashtagSchema.name)
        t.column(HashtagSchema.previewAssetId)
        t.column(HashtagSchema.isFollowed)
    }
}