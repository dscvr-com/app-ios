//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS

class HashtagTableViewController: OptographTableViewController, RedNavbar {
    
    let viewModel = SearchViewModel()
    
    let hashtag: String
    
    required init(hashtag: String) {
        self.hashtag = hashtag
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = hashtag
        
        viewModel.searchText.value = hashtag
        
        viewModel.results.producer
            .start(
                next: { results in
                    self.items = results
                    self.tableView.reloadData()
                },
                error: { _ in
                }
        )
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
}