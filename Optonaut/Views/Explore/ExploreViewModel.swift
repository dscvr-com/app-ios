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
    
    let refreshNotification = NotificationSignal()
    let loadMoreNotification = NotificationSignal()
    
    init() {
        
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.isStaffPick])
        
        refreshNotification.signal
            .mapError { _ in DatabaseQueryError.Nil }
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOn(QueueScheduler(queue: queue))
                    .map { row -> Optograph in
                        let person = Person.fromSQL(row)
                        let location = Location.fromSQL(row)
                        var optograph = Optograph.fromSQL(row)
                        
                        optograph.person = person
                        optograph.location = location
                        
                        return optograph
                    }
                    .collect()
                    .map { return self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
                self.results.value = optographs
                // needed since Optograph could have been deleted in the meantime
                self.results.value = self.results.value.filter { !$0.deleted }
            }
        
        refreshNotification.signal
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { _ in
                ApiService<Optograph>.get("optographs")
                    .observeOn(QueueScheduler(queue: queue))
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .collect()
                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
                self.results.value = optographs
            }
        
        loadMoreNotification.signal
            .mapError { _ in ApiError.Nil }
            .map { _ in self.results.value.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<Optograph>.get("optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOn(QueueScheduler(queue: queue))
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .collect()
                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
                self.results.value = optographs
            }
    }
    
}