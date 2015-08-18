//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct LocationSchemaType: ModelSchema {
    let id = Expression<UUID>("location_id")
    let text = Expression<String>("location_text")
    let createdAt = Expression<NSDate>("location_created_at")
    let latitude = Expression<Double>("location_latitude")
    let longitude = Expression<Double>("location_longitude")
}

let LocationSchema = LocationSchemaType()
let LocationTable = Table("location")

func LocationMigration() -> String {
    return LocationTable.create { t in
        t.column(LocationSchema.id, primaryKey: true)
        t.column(LocationSchema.text)
        t.column(LocationSchema.createdAt)
        t.column(LocationSchema.latitude)
        t.column(LocationSchema.longitude)
    }
}
