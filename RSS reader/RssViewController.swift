//
//  SecondViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/02.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit

class RssViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mTableView: UITableView!
    
    fileprivate var mSelectedPath: IndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.navigationItem.title = Localization.get(Localization.CHANNELS)

        self.tabBarController?.tabBar.isTranslucent = false
        
        mTableView.delegate = self
        mTableView.dataSource = self
        SeparatorSetting.setTableView(mTableView)
                
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(RssViewController.onEditClick(_:))),
        ]
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(RssViewController.onAddClick(_:))),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(RssViewController.onActionClick(_:)))]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FeedModelClient.sInstance.fetchFeeds({(Int) -> Void in
            self.mTableView.reloadData()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let selectedPath = mSelectedPath {
            mTableView.deselectRow(at: selectedPath, animated: false)
            mSelectedPath = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Log.d("list item count = " + String(FeedModelClient.sInstance.getFeedCount()))
        return FeedModelClient.sInstance.getFeedCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
        let feed = FeedModelClient.sInstance.getFeed((indexPath as NSIndexPath).row)
        cell.textLabel?.text = feed?.title
        cell.detailTextLabel?.text = nil
        SeparatorSetting.setCell(cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mSelectedPath = indexPath
        guard let feed = FeedModelClient.sInstance.getFeed((indexPath as NSIndexPath).row) else {
            return
        }
        guard let link = feed.link else {
            return
        }
        Log.d(String((indexPath as NSIndexPath).row) + "selected " + link)
        
        performSegue(withIdentifier: "toArticlesViewController",sender: link)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        
        if(editingStyle == UITableViewCellEditingStyle.delete){
            Log.d("delete? " + indexPath.description)
            FeedModelClient.sInstance.deleteFeed((indexPath as NSIndexPath).row, callback: {(ret: Int) -> Void in
                if (ret == FeedModelClient.RET_SUCCESS) {
                    self.mTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: UITableViewRowActionStyle.default, title: Localization.get(Localization.DELETE), handler: {(action: UITableViewRowAction, indexPath: IndexPath) -> Void in
                    Log.d("delete? " + indexPath.description)
                    FeedModelClient.sInstance.deleteFeed((indexPath as NSIndexPath).row, callback: {(ret: Int) -> Void in
                        if (ret == FeedModelClient.RET_SUCCESS) {
                            self.mTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                        }
                    })
            }),
            UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: Localization.get(Localization.SHARE), handler: {(action: UITableViewRowAction, indexPath: IndexPath) -> Void in
                let feed = FeedModelClient.sInstance.getFeed((indexPath as NSIndexPath).row)
                if (feed != nil && feed!.title != nil && feed!.page_link != nil) {
                    let items: [AnyObject] = [feed!.title! as AnyObject, URL(string: feed!.page_link!)! as AnyObject]
                    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                }
            }),
        ]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "toArticlesViewController") {
            Log.d("prepareForSeque " + String(sender as! String!))
            let vc: ArticlesViewController = segue.destination as! ArticlesViewController
            vc.mUrlString = sender as! String!
        }
    }
    
    func onEditClick(_ sender: UIButton) {
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(RssViewController.onDoneClick(_:))),
        ]
        mTableView.setEditing(true, animated: true)
    }

    func onDoneClick(_ sender: UIButton) {
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(RssViewController.onEditClick(_:))),
        ]
        mTableView.setEditing(false, animated: true)
    }
    
    func onAddClick(_ sender: UIButton) {
        let alertController = RssAddDialogController.create(nil, url: nil, callback: {
            (text) -> Void in
            self.saveFeed(text)
        })
        present(alertController, animated: true, completion: nil)
    }

    func onActionClick(_ sender: UIButton) {
        let message = FeedModelClient.sInstance.getFeedsShareText()
        let activityViewController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
     }
    
    func saveFeed(_ url: String) {
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
    
    func showMessage(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .default) {
            action in
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

