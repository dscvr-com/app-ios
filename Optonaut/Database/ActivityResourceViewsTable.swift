//
//  ActivityResourceViewsTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct ActivityResourceViewsSchemaType: ModelSchema {
    let ID = Expression<UUID>("activity_resource_views_id")
    let count = Expression<Int>("activity_resource_views_count")
    let optographID = Expression<UUID>("activity_resource_views_optograph_id")
}

let ActivityResourceViewsSchema = ActivityResourceViewsSchemaType()
let ActivityResourceViewsTable = Table("activity_resource_views")

func ActivityResourceViewsMigration() -> String {
    return ActivityResourceViewsTable.create { t in
        t.column(ActivityResourceViewsSchema.ID, primaryKey: true)
        t.column(ActivityResourceViewsSchema.count)
        t.column(ActivityResourceViewsSchema.optographID)
    }
}
