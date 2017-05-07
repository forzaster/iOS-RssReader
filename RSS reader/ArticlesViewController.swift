//
//  FirstViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/02.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit

class ArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate  {
    @IBOutlet weak var mTableView: UITableView!
    
    static var CELL_TAG_TABLE_ITEM_VIEW: String = "TableItemView"
    
    fileprivate var mSelectedPath: IndexPath? = nil
    
    fileprivate var mDateFormatter: DateFormatter = DateFormatter()
    
    fileprivate var mRefreshControl: UIRefreshControl = UIRefreshControl()
    
    fileprivate var mAdapter : PArticleItemAdapter?
    
    fileprivate var mLoading : Loading?;
    
    fileprivate var mRssAddController : RssAddController = RssAddController()
    
    var mDate: Date?;
    
    var mUrlString: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        Log.d("Article " + description);
        
        self.tabBarController?.tabBar.isTranslucent = false

        self.navigationItem.title = Localization.get(Localization.ARTICLES)
        
        mLoading = Loading()
        let barFrame = UIApplication.shared.statusBarFrame
        let navBarFrame = self.navigationController?.navigationBar.frame
        mLoading!.frame = CGRect(x: barFrame.width - 30, y: barFrame.height + (navBarFrame?.height)!, width: 30, height: 30)

        self.view.addSubview(mLoading!)
        mLoading!.isHidden = true
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(RssViewController.onAddClick(_:)))]
        
        mTableView.delegate = self
        mTableView.dataSource = self
        mTableView.separatorStyle = UITableViewCellSeparatorStyle.none
        mTableView.rowHeight = UITableViewAutomaticDimension
        mTableView.estimatedRowHeight = TableItemView.getHeight()
        mTableView.register(TableItemView.self, forCellReuseIdentifier: "TableItemView")
        SeparatorSetting.setTableView(mTableView)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        mTableView.addGestureRecognizer(recognizer)
        
        mRefreshControl.attributedTitle = NSAttributedString(string: Localization.get(Localization.PULL_TO_UPDATE))
        mRefreshControl.addTarget(self, action: #selector(ArticlesViewController.refresh), for: UIControlEvents.valueChanged)
        mTableView.addSubview(mRefreshControl)

        if let url = mUrlString {
            mAdapter = DBArticleItemAdapter(feedUrl: url)
        } else {
            mAdapter = DBArticleItemAdapter(feedUrl: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
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
            self.mTableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            self.mTableView.reloadData()
        })
        
        if (mUrlString) == nil {
            let TIME_DIFF = 300000;
            var diff = TIME_DIFF;
            if let date = mDate {
                let now = Date();
                let n = Int(now.timeIntervalSince1970);
                diff = n - Int(date.timeIntervalSince1970)
            }
            if (diff >= TIME_DIFF) {
                showLoading()
                FeedModelClient.sInstance.updateAll({
                    (ret: Int) -> Void in
                        Log.d("UpdateAll done")
                        self.mLoading!.stopAnim()
                        self.mLoading!.isHidden = true
                        self.mTableView.reloadData()
                })
            }
        }
        mDate = Date();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Log.d("viewDidDisappear")
        let barFrame = UIApplication.shared.statusBarFrame
        let rect = self.navigationController?.navigationBar.frame
        self.navigationController?.navigationBar.frame = CGRect(x:0, y:barFrame.height, width: (rect?.width)!, height: (rect?.height)!)
        
        if let selectedPath = mSelectedPath {
            mTableView.deselectRow(at: selectedPath, animated: false)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "toWebViewController") {
            let array = sender as! [String]
            let link = array[0]
            let title = array[1]
            Log.d("prepareForSeque " + String(link))
            let webVC: WebViewController = segue.destination as! WebViewController
            webVC.hidesBottomBarWhenPushed = true
            webVC.mUrlString = link
            webVC.mTitle = title
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
        guard let navController = self.navigationController else {
            return
        }
        if (mRefreshControl.isRefreshing) {
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
        
        let barFrame = UIApplication.shared.statusBarFrame
        if (newY > barFrame.height) {
            newY = barFrame.height
        }
        
        if (rect.minY == newY) {
            return
        }

        self.navigationController?.navigationBar.frame = CGRect(x:0, y:newY, width: rect.width, height: rect.height)
        */
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let adapter = mAdapter {
            return adapter.getCount(section)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let adapter = mAdapter {
            return adapter.getItemView(tableView, indexPath: indexPath)
        }
        return UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mSelectedPath = indexPath
        var link: String? = nil
        var title: String? = nil
        
        if let adapter = mAdapter {
            (link, title, _) = adapter.didSelect(tableView, indexPath: indexPath)
        }

        if let l = link, let t = title {
            Log.d(String((indexPath as NSIndexPath).row) + "selected " + l + ", " + t)
            performSegue(withIdentifier: "toWebViewController",sender: [l, t])
        }
    }
    
    func showErrorMessage(_ message: String) {
        let alertController = UIAlertController(title: Localization.get(Localization.ERROR), message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .default) {
            action in
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showLoading() {
        //let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        //anim.toValue = M_PI / 180 * 360
        //anim.duration = 2
        //anim.repeatCount = Float.infinity
        //mLoading!.layer.add(anim, forKey: "rotateAnimation")
        mLoading!.isHidden = false
        mLoading!.startAnim()
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
                self.mLoading!.stopAnim()
                self.mLoading!.isHidden = true
                self.mTableView.reloadData()
            })
        }
    }
    
    func onAddClick(_ sender: UIButton) {
        mRssAddController.start(self)
    }
    
    func onLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerState.began) {
            return;
        }
        let p = recognizer.location(in: mTableView)
        let indexPath = mTableView.indexPathForRow(at: p)
        var title: String? = nil
        var description: String? = nil
        
        if let adapter = mAdapter, let path = indexPath {
            (_, title, description) = adapter.didSelect(mTableView, indexPath: path)
        }
        
        if let d = description, let t = title {
            let alertController = UIAlertController(title: t, message: d, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .default) {
                action in
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate class DBArticleItemAdapter: NSObject, PArticleItemAdapter {


        fileprivate var mDateFormatter: DateFormatter = DateFormatter()
        
        fileprivate var mCallback: () -> Void
        
        fileprivate var mFeedUrl: String? = nil
        
        fileprivate let mOptions : [String: AnyObject] = [
                            String(NSDocumentTypeDocumentAttribute): NSHTMLTextDocumentType as AnyObject,
                            String(NSCharacterEncodingDocumentAttribute): String.Encoding.utf8 as AnyObject]
        
        init(feedUrl: String?) {
            mCallback = {() -> Void in }
            mFeedUrl = feedUrl
            mDateFormatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
        }

        func getCount(_ section: Int) -> Int {
            Log.d("list item count = " + String(FeedModelClient.sInstance.getArticleCount(mFeedUrl)))
            return FeedModelClient.sInstance.getArticleCount(mFeedUrl)
        }
        
        func getItemHeight(_ tableView: UITableView, indexPath: IndexPath) -> CGFloat {
            return TableItemView.getHeight();
        }
        
        func getItemView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
            let cell: TableItemView = tableView.dequeueReusableCell(withIdentifier: "TableItemView", for: indexPath) as! TableItemView;
            cell.layoutMargins = UIEdgeInsets.zero
            let article_ = FeedModelClient.sInstance.getArticle(mFeedUrl, pos: (indexPath as NSIndexPath).row)
            if let article = article_ {
                if let title = article.title {
                    cell.mTitle.text = title
                }
                if let feedTitle = article.feedTitle {
                    cell.mSubText1.text = feedTitle
                    cell.setMark(feedTitle)
                }
                if let date = article.date {
                    cell.mSubText2.text = mDateFormatter.string(from: date)
                } else {
                    cell.mSubText2.text = ""
                }
                if let detail = article.detail {
                    let detail_ = detail.replacingOccurrences(of: "\n", with: "")
                    cell.mDetail.text = detail_
                } else {
                    cell.mDetail.text = ""
                }

                if (!article.watched) {
                    cell.mTitle.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
                } else {
                    cell.mTitle.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
                }
            }
            
            SeparatorSetting.setCell(cell)
            return cell
        }
        
        func setHtmlText(_ detail: String, cell: TableItemView) {
            Log.d("Detail=" + detail)
            if let encodedData = detail.data(using: String.Encoding.utf8) {
                let attributedString = try? NSAttributedString(data: encodedData, options: mOptions, documentAttributes: nil)
                cell.mDetail.attributedText = attributedString
                Log.d("OK Detail=" + String(describing: attributedString))
            }
        }
        
        func didSelect(_ tableView: UITableView, indexPath: IndexPath) -> (String?, String?, String?) {
            var link: String? = nil
            var title: String? = nil
            var description: String? = nil
            let article_ = FeedModelClient.sInstance.getArticle(mFeedUrl, pos: (indexPath as NSIndexPath).row)
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
        
        internal func update(_ callback: @escaping () -> Void) {
            FeedModelClient.sInstance.updateAll({
                (ret: Int) -> Void in
                Log.d("UpdateAll done")
                callback()
            })
        }
    }
    
    fileprivate class DirectArticleItemAdapter: NSObject, PArticleItemAdapter {
        
        fileprivate var mUrl: String;
        
        fileprivate var mParser: RssXmlParser;
        
        init(uristr: String, parser: RssXmlParser) {
            mUrl = uristr
            mParser = parser
        }
        
        func getCount(_ section: Int) -> Int {
            return mParser.getCount()
        }
        
        func getItemHeight(_ tableView: UITableView, indexPath: IndexPath) -> CGFloat {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
            return cell.frame.height
        }
        
        func getItemView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
            cell.textLabel?.text = mParser.getItem((indexPath as NSIndexPath).row)?.mTitle
            cell.detailTextLabel?.text = mParser.getItem((indexPath as NSIndexPath).row)?.mDate
            SeparatorSetting.setCell(cell)
            return cell
        }
        
        func didSelect(_ tableView: UITableView, indexPath: IndexPath) -> (String?, String?, String?) {
            let item = mParser.getItem((indexPath as NSIndexPath).row)
            return (item?.mLink, item?.mTitle, item?.mDescription)
        }
        
        func update(_ callback: @escaping () -> Void) {
        }
        
        func threadRun(_ withObject: AnyObject?) {
        }
    }
}
