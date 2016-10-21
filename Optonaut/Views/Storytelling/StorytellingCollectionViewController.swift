//
//  StorytellingCollectionViewController.swift
//  DSCVR
//
//  Created by Thadz on 09/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import Kingfisher




class StorytellingCollectionViewController: UICollectionViewController,WhiteNavBar,TabControllerDelegate {
    
    private var profileViewModel: ProfileViewModel;
    
    private var feedsModel:StorytellingVCModel
    private var optographIDs: [UUID] = [];
    private var feedIDs: [UUID] = [];
    
    private var storyIDs: [UUID] = []; //user stories
    //private var storyFeed: [StorytellingFeed] = []; //feed available stories
    
    var startStory = false;
    var startOpto = ""
    var delegate: FPOptographsCollectionViewControllerDelegate?
    
    private var leftBarButton: UIBarButtonItem?
    private var rightBarButton: UIBarButtonItem?
    
    var fromLoginPage:Bool = false
    
    init(personID: UUID) {
        
        profileViewModel = ProfileViewModel(personID: personID);
        feedsModel = StorytellingVCModel(personID: personID)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
//        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
//        layout.footerReferenceSize = CGSizeMake(100, 50)
        
        super.init(collectionViewLayout: layout);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.title = "Stories";
        
        var leftBarImage = UIImage(named:"iam360_navTitle")
        leftBarImage = leftBarImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        leftBarButton = UIBarButtonItem(image: leftBarImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.dismissMe))
        
        var rightBarImage = UIImage(named:"create_story_icn")
        rightBarImage = rightBarImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        rightBarButton = UIBarButtonItem(image: rightBarImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.showDetailsViewController))
        
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        tabController?.delegate = self
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7);
        collectionView!.alwaysBounceVertical = true;
        collectionView!.delegate = self;
        collectionView!.dataSource = self;
        collectionView?.backgroundColor = UIColor.whiteColor()
        
        collectionView!.registerClass(StorytellingCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell");
        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView")
        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        //get all optographid with stories
        feedsModel.results.producer
            .delayAllUntil(feedsModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                
                
                print(results)
                
                if let strongSelf = self {
                    strongSelf.storyIDs = results
                        .map{$0.optographID}
                }
                })
            .startWithNext { _ in
                self.collectionView?.reloadData()
        }
        
        tabController?.pageStatus.producer.startWithNext { val in
            if val == .Story {
                self.feedsModel.refreshNotification.notify(())
                self.feedsModel.isActive.value = true
            } else {
                self.feedsModel.isActive.value = false
            }
        }
        
        
        
}
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        tabController?.delegate = self
        
        feedsModel.isActive.value = true
        
        feedsModel.refreshNotification.notify()
        
        navigationController?.navigationBarHidden = false
        
        print("SCVC viewWillAppear")
    }
    
    func dismissMe(){
        tabController?.goToProfileFromStory()
    }
    
    func showDetailsViewController(){
        
        let optoCollection = FPOptographsCollectionViewController(personID: SessionService.personID)
        optoCollection.startStory = true
        
        let navCon = UINavigationController()
        navCon.viewControllers = [optoCollection]
        navigationController?.presentViewController(navCon, animated: true, completion: nil)
    }

    //UICollectionView Data Source
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return optographIDs.count;
        
        
        return storyIDs.count;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var storyCell = UICollectionViewCell()
        
        if  indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! StorytellingCollectionViewCell;
            cell.indexPath = indexPath.item
            cell.bind(storyIDs[indexPath.row])
            cell.navigationController = navigationController as? NavigationController
            storyCell = cell
        }
        
        storyCell.contentView.layer.cornerRadius = 10.0;
        storyCell.contentView.layer.borderWidth = 1.0;
        storyCell.contentView.layer.borderColor = UIColor.clearColor().CGColor
        storyCell.contentView.layer.masksToBounds = true;
        
        return storyCell
    }
    
    //UICollectionView Delegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let startOptograph = storyIDs[indexPath.row]
        print("startOpto: \(startOptograph)")
        
        let detailsViewController = DetailsTableViewController(optoList:[startOptograph])
        detailsViewController.cellIndexpath = indexPath.item
        detailsViewController.isStory = true
        
        let optoModel = Models.optographs[startOptograph]!
        detailsViewController.storyID = optoModel.model.storyID
        
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    //UICollectionViewFlowLayout Delegate
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView = UICollectionReusableView()
        
        
        if kind == UICollectionElementKindSectionFooter{
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView", forIndexPath: indexPath)
            
//            let footerLabel = UILabel()
//            footerLabel.text = "footer label"
//            footerLabel.frame = CGRectMake(0, 0, 0, 0);
//            footerLabel.sizeToFit()
//            footerLabel.center = CGPointMake(self.view.center.x, 50/2)
//            footerView.addSubview(footerLabel)
            
            let startStoryButton = UIButton()
//            startStoryButton.setTitle("Create a Story", forState: UIControlState.Normal)
            startStoryButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 22.0)
            startStoryButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            startStoryButton.setImage(UIImage(named:"create_a_story_btn" ), forState: UIControlState.Normal)
//            startStoryButton.sizeToFit()
            startStoryButton.frame = CGRect(x: 0, y: 0, width: 330.0, height: 78.0)
            startStoryButton.center = CGPointMake(self.view.center.x, 200/2)
            startStoryButton.addTarget(self, action: #selector(showDetailsViewController), forControlEvents: UIControlEvents.TouchUpInside)
//            startStoryButton.backgroundColor = UIColor.orangeColor()
//            startStoryButton.layer.cornerRadius = 10.0
            footerView.addSubview(startStoryButton)
            
            let lineView = UIView(frame: CGRect(x: 0, y: 20, width: self.view.frame.width, height: 1))
            lineView.backgroundColor = UIColor.lightGrayColor()
            
            footerView.addSubview(lineView)
            
            reusableView = footerView
        }
        else if kind == UICollectionElementKindSectionHeader{
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath)
            
            let lineView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1))
            lineView.backgroundColor = UIColor.lightGrayColor()
            lineView.center = CGPointMake(self.view.center.x, 25/2)
            
            let storiesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            storiesLabel.text = "YOUR STORIES"
            storiesLabel.font = UIFont(name: "Avenir-Heavy", size: 13.0)
            storiesLabel.textAlignment = NSTextAlignment.Center
            storiesLabel.sizeToFit()
            storiesLabel.frame = CGRect(x: 0, y: 0, width: storiesLabel.frame.size.width + 20, height: storiesLabel.frame.size.height)
            storiesLabel.backgroundColor = UIColor.whiteColor()
            storiesLabel.textColor = UIColor.blackColor()
            storiesLabel.center = lineView.center
            
            headerView.addSubview(lineView)
            headerView.addSubview(storiesLabel)
            
//            headerView.backgroundColor = UIColor.blueColor()
            
            reusableView = headerView
        }
        
        return reusableView;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        
        var referenceSize = CGSize()
        
        if section == 0{
            referenceSize = CGSizeMake(self.view.width, 200)
        }
        else{
            referenceSize = CGSizeMake(self.view.width, 0)
        }
        
        return referenceSize
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
    
        var referenceSize = CGSize()
        
        if section == 0{
            referenceSize = CGSizeMake(self.view.width, 25.0)
        }
        else{
            referenceSize = CGSizeMake(self.view.width, 0)
        }
        
        return referenceSize
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var varyingSize = CGSize()
        
        if indexPath.section == 0 {
            let width = ((self.view.frame.size.width)/3) - 20;
            varyingSize = CGSize(width: width, height: width);
        }
        
        else{
            let width = ((self.view.frame.size.width)/3) - 20;
            varyingSize = CGSize(width: width, height: width);
        }
        
        return varyingSize;
    }
}
