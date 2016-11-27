//
//  FeedModelClient.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/10.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit
import CoreData

class FeedModelClient {
    
    static let RET_ERROR : Int = -1
    static let RET_SUCCESS : Int = 0
    static let RET_SAVE_FEED_ALREADY_ADDED : Int = 1
    
    fileprivate static let ARTICLE_MAX_NUMBER = 1000
    
    class Feed {
        var title: String?
        var link: String?
        var page_link: String?
        var last_modified: String?
    }
    
    class Article {
        var title: String?
        var link: String?
        var detail: String?
        var date: Date?
        var feedTitle: String?
        var feedLink: String?
        var watched: Bool = false
    }
    
    static var sInstance : FeedModelClient = FeedModelClient()
    
    fileprivate var mDateFormatter: DateFormatter = DateFormatter()
    
    fileprivate var mPubDateFormatter: DateFormatter = DateFormatter()

    fileprivate var mFeedArray: [NSManagedObject]? = nil
    
    fileprivate var mArticleArray: [ArticleEntity]? = nil
    
    fileprivate var mSpecificArticleArray: [ArticleEntity]? = nil
    
    fileprivate var mWorkerQueue: OperationQueue;
    
    fileprivate var mMainQueue: OperationQueue;
    
    fileprivate var mUpdateCount: Int = 0

    init() {
        mWorkerQueue = OperationQueue()
        mWorkerQueue.maxConcurrentOperationCount = 1
        mMainQueue = OperationQueue.main
        mMainQueue.maxConcurrentOperationCount = 1
        mDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        mPubDateFormatter.dateFormat = "dd MM yyyy HH:mm:ss"
    }
    
    func deleteFeed(_ pos: Int, callback: @escaping (Int) -> Void) {
        guard let feed = getFeed(pos) else {
            callback(FeedModelClient.RET_ERROR)
            return
        }
        guard let _ = feed.link else {
            callback(FeedModelClient.RET_ERROR)
            return
        }
        
        let operation = DeleteOperation(mainQueue: mMainQueue, feed: feed, callback: {(ret: Int, feeds: [NSManagedObject]?) -> Void in
            if (feeds != nil) {
                self.mFeedArray = feeds
            }
            callback(ret)
        })
        mWorkerQueue.addOperation(operation)
    }

    func watchedArticle(_ feedLink: String, data: Article, callback: @escaping (Int) -> Void) {
        let operation = WatchedOperation(mainQueue: mMainQueue, feedLink: feedLink, data: data, watched: true, callback: {(ret: Int, articles: [ArticleEntity]?) -> Void in
            if (articles != nil) {
                self.mArticleArray = articles
            }
            callback(ret)
        })
        mWorkerQueue.addOperation(operation)
    }
    
    func fetchFeeds(_ callback: @escaping (Int) -> Void) {
        let operation = FetchFeedsOperation(mainQueue: mMainQueue, callback: {
            (ret: Int, feeds: [NSManagedObject]?) -> Void in
                if let fs = feeds {
                    self.mFeedArray = fs
                }
                callback(ret)
            })
        mWorkerQueue.addOperation(operation)
    }

    func fetchArticles(_ feedUrl: String?, callback: @escaping (Int) -> Void) {
        let callback = {
            (ret: Int, articles: [ArticleEntity]?) -> Void in
            if let articles_ = articles {
                if let _ = feedUrl {
                    self.mSpecificArticleArray = articles_
                } else {
                    self.mArticleArray = articles_
                }
            }
            callback(ret)
        }
        var operation: Operation
        if let furl = feedUrl {
            operation = FetchArticlesOperation(mainQueue: mMainQueue, feedUrl: furl, callback: callback)
        } else {
            operation = FetchArticlesOperation(mainQueue: mMainQueue, callback: callback)
        }
        mWorkerQueue.addOperation(operation)
    }
    
    func clearSpecificArticles() {
        mSpecificArticleArray = nil
    }
    
    func getFeedCount() -> Int {
        guard let array = mFeedArray else {
            return 0
        }
        return array.count
    }
    
    func getFeed(_ pos: Int) -> Feed? {
        guard var array = mFeedArray else {
            return nil
        }
        if (pos < 0 || pos >= array.count) {
            return nil
        }
        let obj = array[pos]
        let feed = FeedModelClient.getFeedFromObj(obj)
        return feed
    }
    
    func getFeedsShareText() -> String {
        var ret = ""
        guard let array = mFeedArray else {
            return "No channels"
        }
        for a in array {
            let f = a as! FeedEntity
            ret += "[" + f.title + "]\n"
            ret += f.page_link + "\n"
            ret += f.link + "\n\n"
        }
        return ret
    }
    
    func getArticleCount(_ feedUrl: String?) -> Int {
        var array_: [NSManagedObject]?
        if let _ = feedUrl {
            array_ = mSpecificArticleArray
        } else {
            array_ = mArticleArray
        }
        if let array = array_ {
            return array.count
        }
        return 0
    }
    
    func getArticle(_ feedUrl: String?, pos: Int) -> Article? {
        var array_: [ArticleEntity]?
        if let _ = feedUrl {
            array_ = mSpecificArticleArray
        } else {
            array_ = mArticleArray
        }
        guard let array = array_ else {
            return nil
        }
        if (pos < 0 || pos >= array.count) {
            return nil
        }
        let obj = array[pos]
        let article: Article = Article()
        article.title = obj.title
        article.link = obj.link
        article.detail = obj.detail
        article.date = obj.date as Date
        if let watched = obj.watched {
            article.watched = watched as Bool
        } else {
            article.watched = false
        }
        
        if let set = obj.feed {
            let feeds = set.allObjects
            if (feeds.count > 0) {
                if let obj = feeds[0] as? FeedEntity {
                    article.feedTitle = obj.title
                    article.feedLink = obj.link
                }
            }
        }
        
        return article
    }
    
    func updateAll(_ callback: @escaping (Int) -> Void) {
        let operation = UpdateAllOperation(mainQueue: mMainQueue, dateFormatter: mDateFormatter, pubDateFormatter: mPubDateFormatter, callback: {(ret: Int, articles: [ArticleEntity]?) -> Void in
            if (articles != nil) {
                self.mArticleArray = articles
            }
            callback(ret)
        })
        mWorkerQueue.addOperation(operation)
    }
    
    func saveFeed(_ url: String, callback: @escaping (Int, String?) -> Void) {
        let count = getFeedCount()
        for i in 0 ..< count {
            let feed = getFeed(i)
            if (feed?.link == url) {
                callback(FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED, feed?.title)
                return
            }
        }
        
        let operation = SaveFeedOperation(mainQueue: mMainQueue, url: url, callback: {(ret: Int, title: String?, feeds: [NSManagedObject]?) -> Void in
            if (feeds != nil) {
                self.mFeedArray = feeds
            }
            callback(ret, title)
        })
        mWorkerQueue.addOperation(operation)
    }
    
    fileprivate static func getFeedFromObj(_ obj: NSManagedObject) -> Feed {
        let feed: Feed = Feed()
        if let feedObj = obj as? FeedEntity {
            feed.title = feedObj.title
            feed.link = feedObj.link
            feed.page_link = feedObj.page_link
            feed.last_modified = feedObj.last_modified
        }
        return feed
    }
  
    fileprivate func getFeedEntity(_ link: String, managedContext: NSManagedObjectContext) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedEntity")
        fetchRequest.predicate = NSPredicate(format: "link = %@", link)
        
        /* Get result array from ManagedObjectContext */
        let array_: [AnyObject]?
        do {
            array_ = try managedContext.fetch(fetchRequest)
        } catch _ as NSError {
            array_ = nil
        }
        var feedObject: NSManagedObject? = nil
        if let array = array_ {
            if (array.count > 0) {
                feedObject = array[0] as? NSManagedObject
            }
        }
        return feedObject
    }
    
    class DeleteOperation: WorkerOperation {
        
        fileprivate let mFeed: Feed
        
        fileprivate var mFeeds: [NSManagedObject]? = nil
        
        fileprivate var mCallback: (Int, [NSManagedObject]?) -> Void
        
        fileprivate var mError = FeedModelClient.RET_SUCCESS
        
        init(mainQueue: OperationQueue, feed: Feed, callback: @escaping (_ ret: Int, _ feeds: [NSManagedObject]?) -> Void) {
            mFeed = feed
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            let managedContext = getManagedContext()
            
            guard let feedObject = getFeedEntity(mFeed.link!, managedContext: managedContext) else {
                mError = FeedModelClient.RET_ERROR
                return
            }

            managedContext.delete(feedObject)
            if let articles = feedObject.value(forKey: "article") as? NSSet {
                var all: [AnyObject] = articles.allObjects as [AnyObject]
                for i in 0 ..< all.count {
                    managedContext.delete((all[i] as? NSManagedObject)!)
                }
            }
            
            /* Error handling */
            do {
                try managedContext.save()
            } catch let error {
                Log.d("Could not save \(error)")
                mError = FeedModelClient.RET_ERROR
                return
            }

            mFeeds = fetchFeeds(nil)
            mError = FeedModelClient.RET_SUCCESS
        }
        
        override func onDone() {
            mCallback(mError, mFeeds)
        }
    }

    class WatchedOperation: WorkerOperation {
        
        fileprivate let mFeedLink: String
        
        fileprivate let mArticle: Article
        
        fileprivate let mWatched: Bool
        
        fileprivate let mCallback: (Int, [ArticleEntity]?) -> Void
        
        fileprivate var mArticles: [ArticleEntity]? = nil
        
        init(mainQueue: OperationQueue, feedLink: String, data: Article, watched: Bool, callback: @escaping (_ ret: Int, _ articles: [ArticleEntity]?) -> Void) {
            mFeedLink = feedLink
            mArticle = data
            mWatched = watched
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            saveArticle(mFeedLink, data: mArticle, setWatched: mWatched, lastModified: nil)
            mArticles = fetchArticles()
        }
        
        override func onDone() {
            mCallback(FeedModelClient.RET_SUCCESS, mArticles)
        }
    }

    class FetchFeedsOperation: WorkerOperation {
        
        fileprivate let mCallback: (Int, [NSManagedObject]?) -> Void
        
        fileprivate var mFeeds: [NSManagedObject]? = nil
        
        init(mainQueue: OperationQueue, callback: @escaping (_ ret: Int, _ feeds: [NSManagedObject]?) -> Void) {
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            mFeeds = self.fetchFeeds(nil)
        }
        
        override func onDone() {
            mCallback(FeedModelClient.RET_SUCCESS, mFeeds)
        }
    }

    class FetchArticlesOperation: WorkerOperation {
        
        fileprivate let mCallback: (Int, [ArticleEntity]?) -> Void
        
        fileprivate var mFeedUrl: String? = nil
        
        fileprivate var mArticles: [ArticleEntity]? = nil
        
        init(mainQueue: OperationQueue, callback: @escaping (_ ret: Int, _ articles: [ArticleEntity]?) -> Void) {
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        init(mainQueue: OperationQueue, feedUrl: String, callback: @escaping (_ ret: Int, _ articles: [ArticleEntity]?) -> Void) {
            mFeedUrl = feedUrl
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            if let feedUrl = mFeedUrl {
                var feeds = fetchFeeds(feedUrl)
                if (feeds != nil && feeds!.count > 0) {
                    let obj: NSManagedObject = feeds![0]
                    if let articlesSet = obj.value(forKey: "article") as? NSSet {
                        let sortDesc: NSSortDescriptor = NSSortDescriptor(key: "date", ascending: false)
                        let all = articlesSet.sortedArray(using: [sortDesc])
                        mArticles = all as? [ArticleEntity]
                    }
                }
                return
            }
            mArticles = fetchArticles()
        }
        
        override func onDone() {
            mCallback(FeedModelClient.RET_SUCCESS, mArticles)
        }
    }
    
    class SaveFeedOperation: WorkerOperation {
        
        fileprivate let mCallback: (Int, String?, [NSManagedObject]?) -> Void
        
        fileprivate let mUrl: String
        
        fileprivate var mFeeds: [NSManagedObject]? = nil
        
        fileprivate var mError: Int = FeedModelClient.RET_ERROR
        
        fileprivate var mTitle: String? = nil

        init(mainQueue: OperationQueue, url: String, callback: @escaping (_ ret: Int, _ title: String?, _ feeds: [NSManagedObject]?) -> Void) {
            mUrl = url
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            let url = URL(string: mUrl)
            let request = URLRequest(url: url!)
            var response: URLResponse?
            var err: NSError?
            var data: Data?
            do {
                data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
            } catch let error as NSError {
                err = error
                data = nil
            }
            if (data != nil && err == nil) {
                let parser: RssXmlParser = RssXmlParser(data: data!)
                let success = parser.parse()
                if (success) {
                    Log.d(parser.getTitle()! + " : " + parser.getLink()! + " : " + mUrl)
                    if (parser.getTitle() != nil && parser.getLink() != nil) {
                        mError = saveFeed(parser.getTitle()!, link: mUrl, page: parser.getLink()!)
                        mTitle = parser.getTitle()
                        Log.d("saveFeed")
                        if (mError == FeedModelClient.RET_SUCCESS) {
                            mFeeds = fetchFeeds(nil)
                            
                        }
                    }
                }
            }
        }
        
        override func onDone() {
            mCallback(mError, mTitle, mFeeds)
        }
        
        fileprivate func saveFeed(_ title: String, link: String, page: String) -> Int {
            var ret = FeedModelClient.RET_SUCCESS
            let managedContext = getManagedContext()
            
            var feedObject: NSManagedObject? = getFeedEntity(link, managedContext: managedContext)
            
            /* Create new ManagedObject */
            if (feedObject == nil) {
                let entity = NSEntityDescription.entity(forEntityName: "FeedEntity", in: managedContext)
                feedObject = NSManagedObject(entity: entity!, insertInto: managedContext)
            } else {
                ret = FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED
            }
            
            guard let feedObj = feedObject else {
                return FeedModelClient.RET_ERROR
            }
            
            /* Set the name attribute using key-value coding */
            feedObj.setValue(title, forKey: "title")
            feedObj.setValue(link, forKey: "link")
            feedObj.setValue(page, forKey: "page_link")
            
            /* Error handling */
            Log.d("save!!!!!! + title=" + title)
            do {
                try managedContext.save()
            } catch let error {
                Log.d("Could not save \(error)")
                if (ret != FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED) {
                    return FeedModelClient.RET_ERROR
                }
            }
            return ret
        }
    }
    
    class UpdateAllOperation: WorkerOperation {
        
        fileprivate let mCallback: (Int, [ArticleEntity]?) -> Void
        
        fileprivate let mDateFormatter: DateFormatter
        
        fileprivate let mPubDateFormatter: DateFormatter
        
        fileprivate var mArticles: [ArticleEntity]?
        
        init(mainQueue: OperationQueue, dateFormatter: DateFormatter, pubDateFormatter: DateFormatter, callback: @escaping (_ ret: Int, _ articles: [ArticleEntity]?) -> Void) {
            mDateFormatter = dateFormatter
            mPubDateFormatter = pubDateFormatter
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            guard let feedObjs = fetchFeeds(nil) else {
                return
            }

            var feeds: [FeedModelClient.Feed] = []
            let count = feedObjs.count
            for i in 0 ..< count {
                feeds.append(FeedModelClient.getFeedFromObj(feedObjs[i]))
            }

            for i in 0 ..< feeds.count {
                let feed = feeds[i]
                if let feedlink = feed.link {
                    let url = URL(string: feedlink)
                    let request = URLRequest(url: url!)
                    var response: URLResponse?
                    var err: NSError?
                    var data: Data?
                    var lastModified: String?
                    do {
                        data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
                        if let res = response as? HTTPURLResponse {
                            var headers  = res.allHeaderFields
                            if let lastModifiedVar = headers.removeValue(forKey: "Last-Modified") {
                                lastModified = lastModifiedVar as? String
                                if (feed.last_modified != nil && lastModified == feed.last_modified!) {
                                    Log.d(feed.title! + " is not updated, skip")
                                    continue
                                }
                            }
                        }
                    } catch let error as NSError {
                        err = error
                        data = nil
                    }
                    if (data != nil && err == nil) {
                        let parser = RssXmlParser(data: data!)
                        let success = parser.parse()
                        if (success) {
                            for i in 0 ..< parser.getCount() {
                                saveArticle(feedlink, item: parser.getItem(i)!, dateFormatter: mDateFormatter, pubDateFormatter: mPubDateFormatter, lastModified: lastModified)
                            }
                        }

                    }
                }
            }
            
            limitArticles()
            mArticles = fetchArticles()
        }
        
        override func onDone() {
            mCallback(FeedModelClient.RET_SUCCESS, mArticles)
        }
    }
    
    class WorkerOperation : Operation {
        fileprivate let mMainQueue: OperationQueue
        
        init(mainQueue: OperationQueue) {
            mMainQueue = mainQueue
        }
        
        override func main() {
            doInBackground()
            mMainQueue.addOperation(MainOperation(callback: {() -> Void in
                self.onDone()
            }))
        }
        
        func doInBackground() {
        }
        
        func onDone() {
        }
        
        func getFeedEntity(_ link: String, managedContext: NSManagedObjectContext) -> NSManagedObject? {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedEntity")
            fetchRequest.predicate = NSPredicate(format: "link = %@", link)
            
            /* Get result array from ManagedObjectContext */
            let array_: [AnyObject]?
            do {
                array_ = try managedContext.fetch(fetchRequest)
            } catch _ as NSError {
                array_ = nil
            }
            var feedObject: NSManagedObject? = nil
            if let array = array_ {
                if (array.count > 0) {
                    feedObject = array[0] as? NSManagedObject
                }
            }
            return feedObject
        }
        
        func fetchFeeds(_ feedUrl: String?) -> [NSManagedObject]? {
            let manageContext = getManagedContext()
            
            /* Set search conditions */
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedEntity")
            if (feedUrl != nil) {
                fetchRequest.predicate = NSPredicate(format: "link = %@", feedUrl!)
            }
            
            /* Get result array from ManagedObjectContext */
            let array_: [AnyObject]?
            do {
                array_ = try manageContext.fetch(fetchRequest)
            } catch _ as NSError {
                array_ = nil
            }
            if let array = array_ {
                return array as? [NSManagedObject]
            }
            return nil
        }
        
        fileprivate func saveArticle(_ urlString: String, item: RssXmlParser.Item, dateFormatter: DateFormatter,
                                 pubDateFormatter: DateFormatter, lastModified: String?) {
            let article: FeedModelClient.Article = FeedModelClient.Article()
            article.title = item.mTitle
            article.link = item.mLink
            
            let date: Date?;
            if (item.mDate != "") {
                var dateStr: NSString = NSString(string: item.mDate)
                let range: NSRange = dateStr.range(of: "+")
                if (range.location != NSNotFound) {
                    dateStr = dateStr.substring(to: range.location) as NSString
                }
                date = dateFormatter.date(from: dateStr as String)
            } else {
                var dateStr: NSString = NSString(string: item.mPubDate)
                
                let range: NSRange = dateStr.range(of: "+")
                if (range.location != NSNotFound) {
                    dateStr = dateStr.substring(to: range.location - 1) as NSString
                }
                let range_: NSRange = dateStr.range(of: "-")
                if (range_.location != NSNotFound) {
                    dateStr = dateStr.substring(to: range_.location - 1) as NSString
                }
                
                dateStr = dateStr.replacingOccurrences(of: "PST", with: "") as NSString
                dateStr = dateStr.replacingOccurrences(of: "EST", with: "") as NSString
                
                dateStr = dateStr.replacingOccurrences(of: "Jan", with: "01") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Feb", with: "02") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Mar", with: "03") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Apr", with: "04") as NSString
                dateStr = dateStr.replacingOccurrences(of: "May", with: "05") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Jun", with: "06") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Jul", with: "07") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Aug", with: "08") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Sep", with: "09") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Oct", with: "10") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Nov", with: "11") as NSString
                dateStr = dateStr.replacingOccurrences(of: "Dec", with: "12") as NSString
                dateStr = dateStr.substring(from: 5) as NSString
                date = pubDateFormatter.date(from: dateStr as String)
            }
            
            if (date != nil) {
                article.date = date!
            } else {
                article.date = Date()
            }
            
            article.detail = item.mDescription
            //Log.d("save article " + article.title! + " "+item.mDate)
            saveArticle(urlString, data: article, setWatched: false, lastModified: lastModified)
        }

        
        func saveArticle(_ feedLink: String, data: Article, setWatched: Bool, lastModified: String?) {
            if (data.link == nil) {
                return
            }
            let managedContext = getManagedContext()
            
            var currentFeed: NSManagedObject? = getFeedEntity(feedLink, managedContext: managedContext)
            if (currentFeed == nil) {
                let feedEntity = NSEntityDescription.entity(forEntityName: "FeedEntity", in: managedContext)
                currentFeed = NSManagedObject(entity: feedEntity!, insertInto: managedContext)
                currentFeed?.setValue(feedLink, forKey: "link")
            }
            
            if (lastModified != nil) {
                currentFeed?.setValue(lastModified, forKey: "last_modified")
            }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ArticleEntity")
            fetchRequest.predicate = NSPredicate(format: "link = %@", data.link!)
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.fetch(fetchRequest)
            } catch _ as NSError {
                array = nil
            }
            var articleObject: NSManagedObject? = nil
            if (array != nil) {
                if (array!.count > 0) {
                    articleObject = (array![0] as! NSManagedObject)
                }
            }
            
            /* Create new ManagedObject */
            if (articleObject == nil) {
                let entity = NSEntityDescription.entity(forEntityName: "ArticleEntity", in: managedContext)
                articleObject = NSManagedObject(entity: entity!, insertInto: managedContext)
            }
            
            /* Set the name attribute using key-value coding */
            articleObject!.setValue(data.title, forKey: "title")
            articleObject!.setValue(data.link, forKey: "link")
            articleObject!.setValue(data.detail, forKey: "detail")
            articleObject!.setValue(data.date, forKey: "date")
            let obj: AnyObject? = articleObject!.value(forKey: "watched") as AnyObject?
            if (setWatched) {
                articleObject!.setValue(true, forKey: "watched")
            } else if (obj == nil) {
                articleObject!.setValue(false, forKey: "watched")
            }
            if (currentFeed != nil) {
                let set: NSMutableSet = NSMutableSet()
                set.add(currentFeed!)
                articleObject!.setValue(set, forKey: "feed")
            }
            
            let updateSet: NSMutableSet = NSMutableSet()
            let articlesSet: NSSet? = currentFeed?.value(forKey: "article") as? NSSet
            if (articlesSet != nil) {
                var all: [AnyObject]? = articlesSet?.allObjects as [AnyObject]?
                if (all != nil) {
                    for i in 0 ..< all!.count {
                        let obj: NSManagedObject? = all![i] as? NSManagedObject
                        if (obj != nil) {
                            updateSet.add(obj!)
                        }
                    }
                }
            }
            if (currentFeed != nil) {
                currentFeed?.setValue(updateSet, forKey: "article")
            }
            
            /* Error handling */
            do {
                try managedContext.save()
            } catch let error {
                Log.d("Could not save \(error)")
            }
        }
        
        func fetchArticles() -> [ArticleEntity]? {
            let managedContext = getManagedContext()
            
            /* Set search conditions */
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ArticleEntity")
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            let sortDescriptors = [sortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.fetch(fetchRequest)
            } catch _ as NSError {
                array = nil
            }
            if (array != nil) {
                return array as? [ArticleEntity]
            }
            return nil
        }

        func limitArticles() {
            let managedContext = getManagedContext()
            
            /* Set search conditions */
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ArticleEntity")
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            let sortDescriptors = [sortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            fetchRequest.fetchOffset = FeedModelClient.ARTICLE_MAX_NUMBER
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.fetch(fetchRequest)
            } catch _ as NSError {
                array = nil
            }
            if (array == nil) {
                return
            }
            let deleteObjs = array as! [NSManagedObject]
            for obj in deleteObjs {
                managedContext.delete(obj)
            }
            
            do {
                try managedContext.save()
            } catch let error {
                Log.d("Could not save \(error)")
            }
        }

        func getManagedContext() -> NSManagedObjectContext {
            /* Get ManagedObjectContext from AppDelegate */
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext: NSManagedObjectContext = appDelegate.managedObjectContext!
            return managedContext
        }
        
        func downloadWithDataTask(_ url: URL) {
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task = session.dataTask(with: url, completionHandler: {
                (data: Data?, response: URLResponse?, error: NSError?) in
                if (data != nil && error == nil) {
                    // do something
                }
                session.finishTasksAndInvalidate()
            } as! (Data?, URLResponse?, Error?) -> Void)
            task.resume()
        }
    }
    
    class MainOperation : Operation {
        fileprivate var mCallback: () -> Void
        
        init(callback: @escaping () -> Void) {
            mCallback = callback
        }
        
        override func main() {
            mCallback()
        }
    }
}
