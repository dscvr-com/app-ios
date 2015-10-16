//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ActiveLabel

class DetailsTableViewCell: UITableViewCell {
    
    weak var viewModel: DetailsViewModel!
    weak var navigationController: NavigationController?
    
    // subviews
    private let infoView = OptographInfoView()
    private let textView = UILabel()
    private let hashtagsView = ActiveLabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        infoView.deleteCallback = { [weak self] in
            self?.navigationController?.popViewControllerAnimated(true)
        }
        contentView.addSubview(infoView)
        
        textView.numberOfLines = 0
        textView.font = UIFont.textOfSize(14, withType: .Regular)
        textView.textColor = .whiteColor()
        contentView.addSubview(textView)
        
        hashtagsView.numberOfLines = 0
        hashtagsView.font = UIFont.textOfSize(14, withType: .Semibold)
        hashtagsView.hashtagColor = .Accent
        hashtagsView.URLEnabled = false
        hashtagsView.mentionEnabled = false
        contentView.addSubview(hashtagsView)
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "triggerTapCallback"))
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func updateConstraints() {
        infoView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        infoView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        infoView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        infoView.autoSetDimension(.Height, toSize: 75)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: infoView, withOffset: 10)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        hashtagsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 15)
        hashtagsView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        hashtagsView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        super.updateConstraints()
    }
    
    func bindViewModel() {
        infoView.bindViewModel(viewModel.optograph)
        infoView.navigationController = navigationController
        
        textView.rac_text <~ viewModel.text
        hashtagsView.rac_text <~ viewModel.hashtags.producer
            .map { $0.componentsSeparatedByString(",").map({ "#\($0)" }).joinWithSeparator(" ") }
        
        hashtagsView.handleHashtagTap { [weak self] hashtag in
            self?.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileTableViewController(personId: viewModel.personId.value)
        navigationController?.pushViewController(profileContainerViewController, animated: true)
    }
    
    func pushViewer() {
        let alert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    func triggerTapCallback() {
        let superView = tableView!.superview!
        let yOffset = max(0, superView.frame.height - tableView!.contentSize.height)
        UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState],
            animations: {
                self.tableView!.contentOffset = CGPoint(x: 0, y: -yOffset)
            },
            completion: nil)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}

// MARK: - OptographOptions
extension DetailsTableViewCell: OptographOptions {
    
    func didTapOptions() {
        showOptions(viewModel.optograph)
    }
    
}