//
//  OnboardingHashtagViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OnboardingHashtagSelectViewModel {
    
    private let results = MutableProperty<[Hashtag]>([])
    private var skippedResults: [Hashtag] = []
    let selectedHashtags = MutableProperty<[Hashtag]>([])
    let currentHashtag = MutableProperty<Hashtag?>(nil)
    
    init() {
        ApiService<Hashtag>.get("hashtags/popular")
            .collect()
            .startWithNext { hashtags in
                self.results.value = hashtags.filter { !$0.isFollowed }
                self.selectedHashtags.value = hashtags.filter { $0.isFollowed }
                self.advance()
            }
    }
    
    private func advance() {
        if results.value.isEmpty && !skippedResults.isEmpty {
            results.value = skippedResults
            skippedResults.removeAll()
        }
        if !results.value.isEmpty {
            currentHashtag.value = results.value.removeFirst()
        }
    }
    
    func followHashtag() {
        guard let hashtag = currentHashtag.value else {
            return
        }
        
        ApiService<Hashtag>.post("hashtags/\(hashtag.id)/follow")
            .startWithCompleted {
                self.selectedHashtags.value.append(self.currentHashtag.value!)
                self.advance()
            }
    }
    
    func skipHashtag() {
        guard let hashtag = currentHashtag.value else {
            return
        }
        skippedResults.append(hashtag)
        self.advance()
    }
    
}