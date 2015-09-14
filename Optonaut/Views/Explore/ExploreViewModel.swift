//
//  ExploreViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ExploreViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    init() {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.isStaffPick])
        
        refreshNotificationSignal.subscribe {
            DatabaseService.defaultConnection.prepare(query)
                .map({ row -> Optograph in
                    let person = Person.fromSQL(row)
                    let location = Location.fromSQL(row)
                    var optograph = Optograph.fromSQL(row)
                    
                    optograph.person = person
                    optograph.location = location
                    
                    return optograph
                })
                .forEach(self.processNewOptograph)
            
            ApiService<Optograph>.get("optographs")
                .startWithNext { optograph in
                    self.processNewOptograph(optograph)
                    
                    try! optograph.insertOrReplace()
                    try! optograph.location.insertOrReplace()
                    try! optograph.person.insertOrReplace()
                }
        }
        
        loadMoreNotificationSignal.subscribe {
            if let oldestResult = self.results.value.last {
                ApiService<Optograph>.get("optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .startWithNext { optograph in
                        self.processNewOptograph(optograph)
                        
                        try! optograph.insertOrReplace()
                        try! optograph.location.insertOrReplace()
                        try! optograph.person.insertOrReplace()
                    }
            }
        }
        
        refreshNotificationSignal.notify()
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        results.value.filterDeleted()
    }
    
}