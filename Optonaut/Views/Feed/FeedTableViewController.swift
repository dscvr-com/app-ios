//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Refresher

class FeedTableViewController: OptographTableViewController, RedNavbar {
    
    let viewModel = FeedViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.icomoonWithName(.LogoText)
        
        let cameraButton = UIBarButtonItem()
        cameraButton.image = UIImage.icomoonWithName(.Camera, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        cameraButton.target = self
        cameraButton.action = "pushCamera"
        navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.icomoonWithName(.MagnifyingGlass)
        searchButton.image = UIImage.icomoonWithName(.MagnifyingGlass, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        searchButton.target = self
        searchButton.action = "pushSearch"
        navigationItem.setLeftBarButtonItem(searchButton, animated: false)
        
        let refreshAction = {
            NSOperationQueue().addOperationWithBlock {
                self.viewModel.refreshNotificationSignal.notify()
            }
        }
        
        tableView.addPullToRefreshWithAction(refreshAction, withAnimator: RefreshAnimator())
        
        viewModel.results.producer
            .start(
                next: { results in
                    self.items = results
                    self.tableView.reloadData()
                    self.tableView.stopPullToRefresh()
                },
                error: { _ in
                    self.tableView.stopPullToRefresh()
                }, completed: {
                    
            })
        
        addNotificationCircle()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
        navigationController?.hidesBarsOnSwipe = true
        
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(16, forBarMetrics: .Default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.icomoonOfSize(50),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        tabBarController?.delegate = nil
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func addNotificationCircle() {
        
        // TODO: simplify
        let tabBar = tabBarController!.tabBar
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
        
        let circle = CALayer()
        circle.frame = CGRect(x: tabBarItemSize.width / 2 + 13, y: tabBarController!.view.frame.height - tabBarItemSize.height / 2 - 12, width: 6, height: 6)
        circle.backgroundColor = UIColor.whiteColor().CGColor
        circle.cornerRadius = 3
        circle.hidden = true
        tabBarController!.view.layer.addSublayer(circle)
        
        viewModel.newResultsAvailable.producer
            .start(next: { newAvailable in
                circle.hidden = !newAvailable
            })
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == viewModel.results.value.count - 1 {
            viewModel.loadMoreNotificationSignal.notify()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.newResultsAvailable.value = false
    }
    
    func pushCamera() {
        navigationController?.pushViewController(CameraViewController(), animated: false)
    }
    
    func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: false)
    }
    
}

extension FeedTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPointZero, animated: true)
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
}