//
//  FirstViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/02.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit
import iAd

class ArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate  {
    @IBOutlet weak var mTableView: UITableView!
    
    static var CELL_TAG_TABLE_ITEM_VIEW: String = "TableItemView"
    
    private var mSelectedPath: NSIndexPath? = nil
    
    private var mDateFormatter: NSDateFormatter = NSDateFormatter()
    
    private var mRefreshControl: UIRefreshControl = UIRefreshControl()
    
    private var mAdapter : PArticleItemAdapter?
    
    private var mLoading : UIView?;
    
    private var mRssAddController : RssAddController = RssAddController()
    
    var mDate: NSDate?;
    
    var mUrlString: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        Log.d("Article " + description);
        
        self.canDisplayBannerAds = true
        self.tabBarController?.tabBar.translucent = false

        self.navigationItem.title = Localization.get(Localization.ARTICLES)
        
        mLoading = Loading()
        let barFrame = UIApplication.sharedApplication().statusBarFrame
        let navBarFrame = self.navigationController?.navigationBar.frame
        mLoading!.frame = CGRect(x: barFrame.width - 30, y: barFrame.height + (navBarFrame?.height)!, width: 30, height: 30)

        self.view.addSubview(mLoading!)
        mLoading!.hidden = true
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(RssViewController.onAddClick(_:)))]
        
        mTableView.delegate = self
        mTableView.dataSource = self
        mTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        mTableView.rowHeight = UITableViewAutomaticDimension
        mTableView.estimatedRowHeight = TableItemView.getHeight()
        mTableView.registerClass(TableItemView.self, forCellReuseIdentifier: "TableItemView")
        SeparatorSetting.setTableView(mTableView)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        mTableView.addGestureRecognizer(recognizer)
        
        mRefreshControl.attributedTitle = NSAttributedString(string: Localization.get(Localization.PULL_TO_UPDATE))
        mRefreshControl.addTarget(self, action: #selector(ArticlesViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        mTableView.addSubview(mRefreshControl)

        if let url = mUrlString {
            mAdapter = DBArticleItemAdapter(feedUrl: url)
        } else {
            mAdapter = DBArticleItemAdapter(feedUrl: nil)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.d("viewDidAppear")
        
        let headerView: UIView? = mTableView.tableHeaderView as UIView!
        if (headerView != nil) {
            Log.d("headerView = " + headerView!.frame.height.description)
            mTableView.tableHeaderView = headerView;
        }

        if (mUrlString) != nil {
            FeedModelClient.sInstance.clearSpecificArticles()
        }

        FeedModelClient.sInstance.fetchArticles(mUrlString, callback: {(Int) -> Void in
            self.mTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.mTableView.reloadData()
        })
        
        if (mUrlString) == nil {
            let TIME_DIFF = 300000;
            var diff = TIME_DIFF;
            if let date = mDate {
                let now = NSDate();
                let n = Int(now.timeIntervalSince1970);
                diff = n - Int(date.timeIntervalSince1970)
            }
            if (diff >= TIME_DIFF) {
                showLoading()
                FeedModelClient.sInstance.updateAll({
                    (ret: Int) -> Void in
                        Log.d("UpdateAll done")
                        self.mLoading!.hidden = true
                        self.mTableView.reloadData()
                })
            }
        }
        mDate = NSDate();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(animated: Bool) {
        Log.d("viewDidDisappear")
        let barFrame = UIApplication.sharedApplication().statusBarFrame
        let rect = self.navigationController?.navigationBar.frame
        self.navigationController?.navigationBar.frame = CGRect(x:0, y:barFrame.height, width: (rect?.width)!, height: (rect?.height)!)
        
        if let selectedPath = mSelectedPath {
            mTableView.deselectRowAtIndexPath(selectedPath, animated: false)
            mSelectedPath = nil
        }
        if (mUrlString) != nil {
            FeedModelClient.sInstance.clearSpecificArticles()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let adapter = mAdapter {
            return adapter.getCount(section)
        }
        return 0
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let navController = self.navigationController else {
            return
        }
        if (mRefreshControl.refreshing) {
            return
        }
        
        let top = scrollView.contentInset.top - navController.navigationBar.frame.height
        let diff = scrollView.contentInset.top + scrollView.contentOffset.y
        //Log.d("offset=" + String(scrollView.contentOffset.y))
        //Log.d("top=" + String(scrollView.contentInset.top))
        //Log.d("frame=" + String(self.navigationController?.navigationBar.frame.origin.y))
        
        let rect = navController.navigationBar.frame
        var newY = top - diff
        if (newY + rect.width < 0) {
            newY = -rect.width
        } else if (newY > top) {
            newY = top
        }
        
        let barFrame = UIApplication.sharedApplication().statusBarFrame
        if (newY > barFrame.height) {
            newY = barFrame.height
        }
        
        if (rect.minY == newY) {
            return
        }

        self.navigationController?.navigationBar.frame = CGRect(x:0, y:newY, width: rect.width, height: rect.height)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let adapter = mAdapter {
            return adapter.getItemView(tableView, indexPath: indexPath)
        }
        return UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        mSelectedPath = indexPath
        var link: String? = nil
        var title: String? = nil
        
        if let adapter = mAdapter {
            (link, title, _) = adapter.didSelect(tableView, indexPath: indexPath)
        }

        if let l = link, t = title {
            Log.d(String(indexPath.row) + "selected " + l + ", " + t)
            performSegueWithIdentifier("toWebViewController",sender: [l, t])
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "toWebViewController") {
            let array = sender as! [String]
            let link = array[0]
            let title = array[1]
            Log.d("prepareForSeque " + String(link))
            let webVC: WebViewController = segue.destinationViewController as! WebViewController
            webVC.hidesBottomBarWhenPushed = true
            webVC.mUrlString = link
            webVC.mTitle = title
        }
    }
    
    func showErrorMessage(message: String) {
        let alertController = UIAlertController(title: Localization.get(Localization.ERROR), message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
            action in
        }
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func refresh() {
        Log.d("refresh!!!!!!");
        mRefreshControl.attributedTitle = NSAttributedString(string: Localization.get(Localization.UPDATING))
        mRefreshControl.beginRefreshing()
        if let adapter = mAdapter {
            showLoading()
            adapter.update({() -> Void in
                self.mRefreshControl.endRefreshing()
                Log.d("endRefresh")
                self.mRefreshControl.attributedTitle = NSAttributedString(string: Localization.get(Localization.PULL_TO_UPDATE))
                
                self.mLoading!.hidden = true
                self.mTableView.reloadData()
            })
        }
    }
    
    func showLoading() {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.toValue = M_PI / 180 * 360
        anim.duration = 2
        anim.repeatCount = Float.infinity
        mLoading!.layer.addAnimation(anim, forKey: "rotateAnimation")
        mLoading!.hidden = false
    }
    
    func onAddClick(sender: UIButton) {
        mRssAddController.start(self)
    }
    
    func onLongPress(recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerState.Began) {
            return;
        }
        let p = recognizer.locationInView(mTableView)
        let indexPath = mTableView.indexPathForRowAtPoint(p)
        var title: String? = nil
        var description: String? = nil
        
        if let adapter = mAdapter, path = indexPath {
            (_, title, description) = adapter.didSelect(mTableView, indexPath: path)
        }
        
        if let d = description, t = title {
            let alertController = UIAlertController(title: t, message: d, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
                action in
            }
            alertController.addAction(okAction)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    class DBArticleItemAdapter: NSObject, PArticleItemAdapter {
        
        private var mDateFormatter: NSDateFormatter = NSDateFormatter()
        
        private var mCallback: () -> Void
        
        private var mFeedUrl: String? = nil
        
        private let mOptions : [String: AnyObject] = [
                            String(NSDocumentTypeDocumentAttribute): NSHTMLTextDocumentType,
                            String(NSCharacterEncodingDocumentAttribute): NSUTF8StringEncoding]
        
        init(feedUrl: String?) {
            mCallback = {() -> Void in }
            mFeedUrl = feedUrl
            mDateFormatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
        }

        func getCount(section: Int) -> Int {
            Log.d("list item count = " + String(FeedModelClient.sInstance.getArticleCount(mFeedUrl)))
            return FeedModelClient.sInstance.getArticleCount(mFeedUrl)
        }
        
        func getItemHeight(tableView: UITableView, indexPath: NSIndexPath) -> CGFloat {
            return TableItemView.getHeight();
        }
        
        func getItemView(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
            let cell: TableItemView = tableView.dequeueReusableCellWithIdentifier("TableItemView", forIndexPath: indexPath) as! TableItemView;
            cell.layoutMargins = UIEdgeInsetsZero
            let article_ = FeedModelClient.sInstance.getArticle(mFeedUrl, pos: indexPath.row)
            if let article = article_ {
                if let title = article.title {
                    cell.mTitle.text = title
                }
                if let feedTitle = article.feedTitle {
                    cell.mSubText1.text = feedTitle
                    cell.setMark(feedTitle)
                }
                if let date = article.date {
                    cell.mSubText2.text = mDateFormatter.stringFromDate(date)
                } else {
                    cell.mSubText2.text = ""
                }
                if let detail = article.detail {
                    let detail_ = detail.stringByReplacingOccurrencesOfString("\n", withString: "")
                    cell.mDetail.text = detail_
                } else {
                    cell.mDetail.text = ""
                }

                if (!article.watched) {
                    cell.mTitle.font = UIFont.boldSystemFontOfSize(UIFont.labelFontSize())
                } else {
                    cell.mTitle.font = UIFont.systemFontOfSize(UIFont.labelFontSize())
                }
            }
            
            SeparatorSetting.setCell(cell)
            return cell
        }
        
        func setHtmlText(detail: String, cell: TableItemView) {
            Log.d("Detail=" + detail)
            if let encodedData = detail.dataUsingEncoding(NSUTF8StringEncoding) {
                let attributedString = try? NSAttributedString(data: encodedData, options: mOptions, documentAttributes: nil)
                cell.mDetail.attributedText = attributedString
                Log.d("OK Detail=" + String(attributedString))
            }
        }
        
        func didSelect(tableView: UITableView, indexPath: NSIndexPath) -> (String?, String?, String?) {
            var link: String? = nil
            var title: String? = nil
            var description: String? = nil
            let article_ = FeedModelClient.sInstance.getArticle(mFeedUrl, pos: indexPath.row)
            if let article = article_ {
                link = article.link
                title = article.title
                description = article.detail
                
                if (article.link != nil && !article.watched) {
                    article.watched = true
                    FeedModelClient.sInstance.watchedArticle(article.feedLink!, data: article, callback: {
                        (Int) -> Void in
                            tableView.reloadData()
                    })
                }
            }
            return (link, title, description)
        }
        
        func update(callback: () -> Void) {
            FeedModelClient.sInstance.updateAll({
                (ret: Int) -> Void in
                    Log.d("UpdateAll done")
                    callback()
            })
        }
    }
    

    class DirectArticleItemAdapter: NSObject, PArticleItemAdapter {
        
        private var mUrl: String;
        
        private var mParser: RssXmlParser;
        
        init(uristr: String, parser: RssXmlParser) {
            mUrl = uristr
            mParser = parser
        }
        
        func getCount(section: Int) -> Int {
            return mParser.getCount()
        }
        
        func getItemHeight(tableView: UITableView, indexPath: NSIndexPath) -> CGFloat {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            return cell.frame.height
        }
        
        func getItemView(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.textLabel?.text = mParser.getItem(indexPath.row)?.mTitle
            cell.detailTextLabel?.text = mParser.getItem(indexPath.row)?.mDate
            SeparatorSetting.setCell(cell)
            return cell
        }
        
        func didSelect(tableView: UITableView, indexPath: NSIndexPath) -> (String?, String?, String?) {
            let item = mParser.getItem(indexPath.row)
            return (item?.mLink, item?.mTitle, item?.mDescription)
        }
        
        func update(callback: () -> Void) {
        }
        
        func threadRun(withObject: AnyObject?) {
        }
    }
}