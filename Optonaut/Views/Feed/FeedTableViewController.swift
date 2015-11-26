//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Device
import Mixpanel

class FeedTableViewController: OptographTableViewController, NoNavbar {
    
    let viewModel = FeedViewModel()
    
    private let refreshControl = UIRefreshControl()
    private let recordButtonView = ActionButton()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButtonView.setTitle(String.iconWithName(.Logo), forState: .Normal)
        recordButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        recordButtonView.defaultBackgroundColor = .Accent
        recordButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        recordButtonView.layer.cornerRadius = 30
        recordButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushCamera"))
        view.addSubview(recordButtonView)
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify(())
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer
            .on(
                next: { results in
                    self.items = results.models
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
                    self.refreshControl.endRefreshing()
                },
                error: { _ in
                    self.refreshControl.endRefreshing()
                }
            )
            .start()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
        
        viewModel.refreshNotification.notify(())
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Feed")
        
        Async.background {
            PipelineService.check()
        }
        
        tabBarController?.delegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Feed")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsetsZero
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    override func updateViewConstraints() {
        
        recordButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
        recordButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        recordButtonView.autoSetDimension(.Width, toSize: 60)
        recordButtonView.autoSetDimension(.Height, toSize: 60)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.newResultsAvailable.value = false
    }
    
    func pushCamera() {
        if StitchingService.isStitching() {
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last Optograph has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        } else {
            let cameraViewController = CameraViewController()
            cameraViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(cameraViewController, animated: false)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! OptographTableViewCell
        
        cell.deleteCallback = { [weak self] in
            self?.viewModel.refreshNotification.notify(())
        }
        
        return cell
    }
    
}

// MARK: - UITabBarControllerDelegate
extension FeedTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let t = tabBarController as? TabBarViewController where !TabBarViewController.tabBarController(t)(t, shouldSelectViewController: viewController) {
            if !SessionService.isLoggedIn {
                let alert = UIAlertController(title: "Please login first", message: "In order to see this tab you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                    self?.view.window?.rootViewController = LoginViewController()
                    }))
                alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
                self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            }
            return false
        }
        
        return true
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPointZero, animated: true)
        }
    }
    
}

// MARK: - LoadMore
extension FeedTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotification.notify(())
        }
    }
    
}