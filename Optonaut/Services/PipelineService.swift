//
//  PipelineService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite
import Async
import ReactiveCocoa
    
func ==(lhs: PipelineService.Status, rhs: PipelineService.Status) -> Bool {
    switch (lhs, rhs) {
    case let (.Stitching(lhs), .Stitching(rhs)): return lhs == rhs
    case let (.StitchingFinished(lhs), .StitchingFinished(rhs)): return lhs == rhs
    default: return false
    }
}

class PipelineService {
    
    enum Status: Equatable {
        case Stitching(Float)
        case StitchingFinished(Optograph)
        case Idle
    }
    
    static let status = MutableProperty<Status>(.Idle)
    
    static func check() {
        Async.main {
            updateOptographs()
        }
    }
    
    static func stop(ID: UUID) {
        if StitchingService.isStitching() {
            StitchingService.cancelStitching()
        }
    }
    
    private static func updateOptographs() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(!OptographTable[OptographSchema.isStitched])
        
        let optograph = DatabaseService.defaultConnection.pluck(query)
            .map { row -> Optograph in
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = Person.fromSQL(row)
                optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
                
                return optograph
            }
        
        if let optograph = optograph {
            stitch(optograph)
        } else if !StitchingService.isStitching() && StitchingService.hasUnstitchedRecordings() {
            // This happens when an optograph was recorded, but never
            // inserted into the DB, for example due to cancel.
            // So it needs to be removed.
            StitchingService.removeUnstitchedRecordings()
        }
    }
    
    private static func stitch(var optograph: Optograph) {
        
        let stitchingSignal = StitchingService.startStitching(optograph)
        
        stitchingSignal
            .observeNext { result in
                switch result {
                case .LeftImage(let data):
                    optograph.leftTextureAssetID = uuid()
                    optograph.saveAsset(.LeftImage(data))
                case .RightImage(let data):
                    optograph.rightTextureAssetID = uuid()
                    optograph.saveAsset(.RightImage(data))
                case .Progress(let progress):
                    status.value = .Stitching(min(0.99, progress))
                }
            }
        
        stitchingSignal
            .observeCompleted {
                optograph.isStitched = true
                optograph.stitcherVersion = StitcherVersion
                optograph.isInFeed = true
                try! optograph.insertOrUpdate()
                StitchingService.removeUnstitchedRecordings()
                status.value = .Stitching(1)
                status.value = .StitchingFinished(optograph)
            }
    }
    
}