//
//  SecondViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/02.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit
import iAd

class RssViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mTableView: UITableView!
    
    private var mSelectedPath: NSIndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.navigationItem.title = Localization.get(Localization.CHANNELS)

        self.canDisplayBannerAds = true
        self.tabBarController?.tabBar.translucent = false
        
        mTableView.delegate = self
        mTableView.dataSource = self
        SeparatorSetting.setTableView(mTableView)
                
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(RssViewController.onEditClick(_:))),
        ]
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(RssViewController.onAddClick(_:))),
            UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(RssViewController.onActionClick(_:)))]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        FeedModelClient.sInstance.fetchFeeds({(Int) -> Void in
            self.mTableView.reloadData()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let selectedPath = mSelectedPath {
            mTableView.deselectRowAtIndexPath(selectedPath, animated: false)
            mSelectedPath = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Log.d("list item count = " + String(FeedModelClient.sInstance.getFeedCount()))
        return FeedModelClient.sInstance.getFeedCount()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        let feed = FeedModelClient.sInstance.getFeed(indexPath.row)
        cell.textLabel?.text = feed?.title
        cell.detailTextLabel?.text = nil
        SeparatorSetting.setCell(cell)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        mSelectedPath = indexPath
        guard let feed = FeedModelClient.sInstance.getFeed(indexPath.row) else {
            return
        }
        guard let link = feed.link else {
            return
        }
        Log.d(String(indexPath.row) + "selected " + link)
        
        performSegueWithIdentifier("toArticlesViewController",sender: link)
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        
        if(editingStyle == UITableViewCellEditingStyle.Delete){
            Log.d("delete? " + indexPath.description)
            FeedModelClient.sInstance.deleteFeed(indexPath.row, callback: {(ret: Int) -> Void in
                if (ret == FeedModelClient.RET_SUCCESS) {
                    self.mTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: Localization.get(Localization.DELETE), handler: {(action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
                    Log.d("delete? " + indexPath.description)
                    FeedModelClient.sInstance.deleteFeed(indexPath.row, callback: {(ret: Int) -> Void in
                        if (ret == FeedModelClient.RET_SUCCESS) {
                            self.mTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                    })
            }),
            UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: Localization.get(Localization.SHARE), handler: {(action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
                let feed = FeedModelClient.sInstance.getFeed(indexPath.row)
                if (feed != nil && feed!.title != nil && feed!.page_link != nil) {
                    let items: [AnyObject] = [feed!.title!, NSURL(string: feed!.page_link!)!]
                    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    self.presentViewController(activityViewController, animated: true, completion: nil)
                }
            }),
        ]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "toArticlesViewController") {
            Log.d("prepareForSeque " + String(sender as! String!))
            let vc: ArticlesViewController = segue.destinationViewController as! ArticlesViewController
            vc.mUrlString = sender as! String!
        }
    }
    
    func onEditClick(sender: UIButton) {
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(RssViewController.onDoneClick(_:))),
        ]
        mTableView.setEditing(true, animated: true)
    }

    func onDoneClick(sender: UIButton) {
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(RssViewController.onEditClick(_:))),
        ]
        mTableView.setEditing(false, animated: true)
    }
    
    func onAddClick(sender: UIButton) {
        let alertController = RssAddDialogController.create(nil, url: nil, callback: {
            (text) -> Void in
            self.saveFeed(text)
        })
        presentViewController(alertController, animated: true, completion: nil)
    }

    func onActionClick(sender: UIButton) {
        let message = FeedModelClient.sInstance.getFeedsShareText()
        let activityViewController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
     }
    
    func saveFeed(url: String) {
        FeedModelClient.sInstance.saveFeed(url, callback: {(error: Int, title: String?) -> Void in
            if (error == FeedModelClient.RET_SUCCESS) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.SUCCESSFULLY_ADDED)
                self.showMessage(Localization.get(Localization.DONE), message: message)
                self.mTableView.reloadData()
            } else if (error == FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.ALREADY_ADDED)
                self.showMessage(Localization.get(Localization.DONE), message: message)
            } else {
                self.showMessage(Localization.get(Localization.ERROR), message: Localization.get(Localization.CAN_NOT_ADD))
            }
        })
    }
    
    func showMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
            action in
        }
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
}

