//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Async
import ReactiveCocoa
import Result

class ActivityTableViewController: UIViewController, RedNavbar {
    
    internal var items = [Activity]()
    internal let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    
    
    let viewModel = ActivitiesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(PlaceholderTableViewCell.self, forCellReuseIdentifier: "placeholder-cell")
        tableView.registerClass(ActivityStarTableViewCell.self, forCellReuseIdentifier: "star-activity-cell")
        tableView.registerClass(ActivityCommentTableViewCell.self, forCellReuseIdentifier: "comment-activity-cell")
        tableView.registerClass(ActivityViewsTableViewCell.self, forCellReuseIdentifier: "views-activity-cell")
        tableView.registerClass(ActivityFollowTableViewCell.self, forCellReuseIdentifier: "follow-activity-cell")
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify(())
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer
            .on(
                next: { results in
                    let wasEmptyBefore = self.items.isEmpty
                    
                    self.items = results.models
                    
                    if wasEmptyBefore {
                        self.tableView.reloadData()
                    } else {
                        self.tableView.beginUpdates()
                        if !results.delete.isEmpty {
                            self.tableView.deleteRowsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.update.isEmpty {
                            self.tableView.reloadRowsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.insert.isEmpty {
                            self.tableView.insertRowsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        self.tableView.endUpdates()
                    }
                    
                    self.refreshControl.endRefreshing()
                    
                    NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(ActivityTableViewController.markVisibleAsRead), userInfo: nil, repeats: false)
                },
                failed: { _ in
                    self.refreshControl.endRefreshing()
                }
            )
            .start()
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
                
        DeviceTokenService.askForPermission()
        
        tabBarController?.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.refreshNotification.notify(())
    }
    
}


// MARK: - UITableViewDelegate
extension ActivityTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if items.isEmpty {
            return view.frame.height
        } else {
            let textWidth = view.frame.width - 80 - 72
            let textHeight = calcTextHeight(items[indexPath.row].text, withWidth: textWidth, andFont: UIFont.displayOfSize(14, withType: .Regular)) + 20
            return max(textHeight, 80)
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        markVisibleAsRead()
    }
    
    dynamic func markVisibleAsRead() {
        guard let visibleCells = tableView.visibleCells as? [ActivityTableViewCell] else {
            return
        }
        
        let unreadActivities = visibleCells.map({ $0.activity }).filter({ !$0.isRead })
        
        if unreadActivities.isEmpty {
            return
        }
        
        SignalProducer<Activity!, NoError>.fromValues(unreadActivities)
            .observeOnUserInteractive()
            .flatMap(.Merge) {
                ApiService<EmptyResponse>.post("activities/\($0.ID)/read")
                    .ignoreError()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .startWithCompleted { [weak self] in
                self?.viewModel.refreshNotification.notify(())
            }
    }
    
}

// MARK: - UITableViewDataSource
extension ActivityTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if items.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("placeholder-cell") as! PlaceholderTableViewCell
            cell.textView.text = "Nothing new yet"
//            cell.iconView.text = String.iconWithName(.Inbox)
            cell.iconView.textColor = .LightGrey
            return cell
        } else {
            let activity = items[indexPath.row]
            
            let cell: ActivityTableViewCell
            switch activity.type {
            case .Star:
                cell = self.tableView.dequeueReusableCellWithIdentifier("star-activity-cell")! as! ActivityStarTableViewCell
            case .Comment:
                cell = self.tableView.dequeueReusableCellWithIdentifier("comment-activity-cell")! as! ActivityCommentTableViewCell
            case .Views:
                cell = self.tableView.dequeueReusableCellWithIdentifier("views-activity-cell")! as! ActivityViewsTableViewCell
            case .Follow:
                cell = self.tableView.dequeueReusableCellWithIdentifier("follow-activity-cell")! as! ActivityFollowTableViewCell
            default:
                fatalError()
            }
            
            
            cell.update(activity)
            cell.navigationController = navigationController as? NavigationController
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 1 : items.count
    }
    
}

// MARK: - UITabBarControllerDelegate
extension ActivityTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
//        if let t = tabBarController as? TabBarViewController where !TabBarViewController.tabBarController(t)(t, shouldSelectViewController: viewController) {
//            return false
//        }
        
        return true
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPointZero, animated: true)
        }
    }
    
}

// MARK: - LoadMore
extension ActivityTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotification.notify(())
        }
    }
    
}