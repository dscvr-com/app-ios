//
//  NotificationTableViewCell.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/15/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import Async
import ReactiveCocoa
import Result

class NotificationTableViewCell: UICollectionViewCell,UITableViewDataSource, UITableViewDelegate{
    
    internal var items = [Activity]()
    internal let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    weak var navigationController: NavigationController?
    
    let viewModel = ActivitiesViewModel()
    
    private var lastLoadMoreRowAssociationKey: UInt8 = 0
    var lastLoadMoreRow: Int {
        get {
            return objc_getAssociatedObject(self, &lastLoadMoreRowAssociationKey) as? Int ?? 0
        }
        set(newValue) {
            objc_setAssociatedObject(self, &lastLoadMoreRowAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        tableView.frame = CGRect(origin: CGPointZero, size: frame.size)
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
                    
//                    NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(NotificationTableViewCell.markVisibleAsRead), userInfo: nil, repeats: false)
                },
                failed: { _ in
                    self.refreshControl.endRefreshing()
                }
            )
            .start()
        
        contentView.addSubview(tableView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
//    override func awakeFromNib() {
//        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
//    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if items.isEmpty {
            return contentView.frame.height
        } else {
            let textWidth = contentView.frame.width - 80 - 72
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if items.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("placeholder-cell") as! PlaceholderTableViewCell
            cell.textView.text = "Nothing new yet"
            //cell.iconView.text = String.iconWithName(.Inbox)
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
            cell.navigationController = navigationController
            return cell
        }
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        checkRow(indexPath) {
            self.viewModel.loadMoreNotification.notify(())
        }
    }
    
    func checkRow(indexPath: NSIndexPath, success: () -> Void) {
        let preloadOffset = 4
        if indexPath.row > lastLoadMoreRow && indexPath.row > items.count - preloadOffset {
            success()
            lastLoadMoreRow = items.count - 1
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 1 : items.count
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}