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
    
    private static let ARTICLE_MAX_NUMBER = 1000
    
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
        var date: NSDate?
        var feedTitle: String?
        var feedLink: String?
        var watched: Bool = false
    }
    
    static var sInstance : FeedModelClient = FeedModelClient()
    
    private var mDateFormatter: NSDateFormatter = NSDateFormatter()
    
    private var mPubDateFormatter: NSDateFormatter = NSDateFormatter()

    private var mFeedArray: [NSManagedObject]? = nil
    
    private var mArticleArray: [ArticleEntity]? = nil
    
    private var mSpecificArticleArray: [ArticleEntity]? = nil
    
    private var mWorkerQueue: NSOperationQueue;
    
    private var mMainQueue: NSOperationQueue;
    
    private var mUpdateCount: Int = 0

    init() {
        mWorkerQueue = NSOperationQueue()
        mWorkerQueue.maxConcurrentOperationCount = 1
        mMainQueue = NSOperationQueue.mainQueue()
        mMainQueue.maxConcurrentOperationCount = 1
        mDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        mPubDateFormatter.dateFormat = "dd MM yyyy HH:mm:ss"
    }
    
    func deleteFeed(pos: Int, callback: (Int) -> Void) {
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

    func watchedArticle(feedLink: String, data: Article, callback: (Int) -> Void) {
        let operation = WatchedOperation(mainQueue: mMainQueue, feedLink: feedLink, data: data, watched: true, callback: {(ret: Int, articles: [ArticleEntity]?) -> Void in
            if (articles != nil) {
                self.mArticleArray = articles
            }
            callback(ret)
        })
        mWorkerQueue.addOperation(operation)
    }
    
    func fetchFeeds(callback: (Int) -> Void) {
        let operation = FetchFeedsOperation(mainQueue: mMainQueue, callback: {
            (ret: Int, feeds: [NSManagedObject]?) -> Void in
                if let fs = feeds {
                    self.mFeedArray = fs
                }
                callback(ret)
            })
        mWorkerQueue.addOperation(operation)
    }

    func fetchArticles(feedUrl: String?, callback: (Int) -> Void) {
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
        var operation: NSOperation
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
    
    func getFeed(pos: Int) -> Feed? {
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
    
    func getArticleCount(feedUrl: String?) -> Int {
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
    
    func getArticle(feedUrl: String?, pos: Int) -> Article? {
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
        article.date = obj.date
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
    
    func updateAll(callback: (Int) -> Void) {
        let operation = UpdateAllOperation(mainQueue: mMainQueue, dateFormatter: mDateFormatter, pubDateFormatter: mPubDateFormatter, callback: {(ret: Int, articles: [ArticleEntity]?) -> Void in
            if (articles != nil) {
                self.mArticleArray = articles
            }
            callback(ret)
        })
        mWorkerQueue.addOperation(operation)
    }
    
    func saveFeed(url: String, callback: (Int, String?) -> Void) {
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
    
    private static func getFeedFromObj(obj: NSManagedObject) -> Feed {
        let feed: Feed = Feed()
        if let feedObj = obj as? FeedEntity {
            feed.title = feedObj.title
            feed.link = feedObj.link
            feed.page_link = feedObj.page_link
            feed.last_modified = feedObj.last_modified
        }
        return feed
    }
  
    private func getFeedEntity(link: String, managedContext: NSManagedObjectContext) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest(entityName: "FeedEntity")
        fetchRequest.predicate = NSPredicate(format: "link = %@", link)
        
        /* Get result array from ManagedObjectContext */
        let array_: [AnyObject]?
        do {
            array_ = try managedContext.executeFetchRequest(fetchRequest)
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
        
        private let mFeed: Feed
        
        private var mFeeds: [NSManagedObject]? = nil
        
        private var mCallback: (Int, [NSManagedObject]?) -> Void
        
        private var mError = FeedModelClient.RET_SUCCESS
        
        init(mainQueue: NSOperationQueue, feed: Feed, callback: (ret: Int, feeds: [NSManagedObject]?) -> Void) {
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

            managedContext.deleteObject(feedObject)
            if let articles = feedObject.valueForKey("article") as? NSSet {
                var all: [AnyObject] = articles.allObjects
                for i in 0 ..< all.count {
                    managedContext.deleteObject((all[i] as? NSManagedObject)!)
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
        
        private let mFeedLink: String
        
        private let mArticle: Article
        
        private let mWatched: Bool
        
        private let mCallback: (Int, [ArticleEntity]?) -> Void
        
        private var mArticles: [ArticleEntity]? = nil
        
        init(mainQueue: NSOperationQueue, feedLink: String, data: Article, watched: Bool, callback: (ret: Int, articles: [ArticleEntity]?) -> Void) {
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
        
        private let mCallback: (Int, [NSManagedObject]?) -> Void
        
        private var mFeeds: [NSManagedObject]? = nil
        
        init(mainQueue: NSOperationQueue, callback: (ret: Int, feeds: [NSManagedObject]?) -> Void) {
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
        
        private let mCallback: (Int, [ArticleEntity]?) -> Void
        
        private var mFeedUrl: String? = nil
        
        private var mArticles: [ArticleEntity]? = nil
        
        init(mainQueue: NSOperationQueue, callback: (ret: Int, articles: [ArticleEntity]?) -> Void) {
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        init(mainQueue: NSOperationQueue, feedUrl: String, callback: (ret: Int, articles: [ArticleEntity]?) -> Void) {
            mFeedUrl = feedUrl
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            if let feedUrl = mFeedUrl {
                var feeds = fetchFeeds(feedUrl)
                if (feeds != nil && feeds!.count > 0) {
                    let obj: NSManagedObject = feeds![0]
                    if let articlesSet = obj.valueForKey("article") as? NSSet {
                        let sortDesc: NSSortDescriptor = NSSortDescriptor(key: "date", ascending: false)
                        let all = articlesSet.sortedArrayUsingDescriptors([sortDesc])
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
        
        private let mCallback: (Int, String?, [NSManagedObject]?) -> Void
        
        private let mUrl: String
        
        private var mFeeds: [NSManagedObject]? = nil
        
        private var mError: Int = FeedModelClient.RET_ERROR
        
        private var mTitle: String? = nil

        init(mainQueue: NSOperationQueue, url: String, callback: (ret: Int, title: String?, feeds: [NSManagedObject]?) -> Void) {
            mUrl = url
            mCallback = callback
            super.init(mainQueue: mainQueue)
        }
        
        override func doInBackground() {
            let url = NSURL(string: mUrl)
            let request = NSURLRequest(URL: url!)
            var response: NSURLResponse?
            var err: NSError?
            var data: NSData?
            do {
                data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
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
        
        private func saveFeed(title: String, link: String, page: String) -> Int {
            var ret = FeedModelClient.RET_SUCCESS
            let managedContext = getManagedContext()
            
            var feedObject: NSManagedObject? = getFeedEntity(link, managedContext: managedContext)
            
            /* Create new ManagedObject */
            if (feedObject == nil) {
                let entity = NSEntityDescription.entityForName("FeedEntity", inManagedObjectContext: managedContext)
                feedObject = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
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
        
        private let mCallback: (Int, [ArticleEntity]?) -> Void
        
        private let mDateFormatter: NSDateFormatter
        
        private let mPubDateFormatter: NSDateFormatter
        
        private var mArticles: [ArticleEntity]?
        
        init(mainQueue: NSOperationQueue, dateFormatter: NSDateFormatter, pubDateFormatter: NSDateFormatter, callback: (ret: Int, articles: [ArticleEntity]?) -> Void) {
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
                    let url = NSURL(string: feedlink)
                    let request = NSURLRequest(URL: url!)
                    var response: NSURLResponse?
                    var err: NSError?
                    var data: NSData?
                    var lastModified: String?
                    do {
                        data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
                        if let res = response as? NSHTTPURLResponse {
                            var headers  = res.allHeaderFields
                            if let lastModifiedVar = headers.removeValueForKey("Last-Modified") {
                                lastModified = lastModifiedVar as? String
                                if (feed.last_modified != nil && lastModified == feed.last_modified!) {
                                    Log.d(feed.title! + " is not updated, skip")
                                    continue
                                }
                                Log.d("LastModified " + String(lastModified!) + ", db=" + (feed.last_modified)!)
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
    
    class WorkerOperation : NSOperation {
        private let mMainQueue: NSOperationQueue
        
        init(mainQueue: NSOperationQueue) {
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
        
        func getFeedEntity(link: String, managedContext: NSManagedObjectContext) -> NSManagedObject? {
            let fetchRequest = NSFetchRequest(entityName: "FeedEntity")
            fetchRequest.predicate = NSPredicate(format: "link = %@", link)
            
            /* Get result array from ManagedObjectContext */
            let array_: [AnyObject]?
            do {
                array_ = try managedContext.executeFetchRequest(fetchRequest)
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
        
        func fetchFeeds(feedUrl: String?) -> [NSManagedObject]? {
            let manageContext = getManagedContext()
            
            /* Set search conditions */
            let fetchRequest = NSFetchRequest(entityName: "FeedEntity")
            if (feedUrl != nil) {
                fetchRequest.predicate = NSPredicate(format: "link = %@", feedUrl!)
            }
            
            /* Get result array from ManagedObjectContext */
            let array_: [AnyObject]?
            do {
                array_ = try manageContext.executeFetchRequest(fetchRequest)
            } catch _ as NSError {
                array_ = nil
            }
            if let array = array_ {
                return array as? [NSManagedObject]
            }
            return nil
        }
        
        private func saveArticle(urlString: String, item: RssXmlParser.Item, dateFormatter: NSDateFormatter,
                                 pubDateFormatter: NSDateFormatter, lastModified: String?) {
            let article: FeedModelClient.Article = FeedModelClient.Article()
            article.title = item.mTitle
            article.link = item.mLink
            
            let date: NSDate?;
            if (item.mDate != "") {
                var dateStr: NSString = NSString(string: item.mDate)
                let range: NSRange = dateStr.rangeOfString("+")
                if (range.location != NSNotFound) {
                    dateStr = dateStr.substringToIndex(range.location)
                }
                date = dateFormatter.dateFromString(dateStr as String)
            } else {
                var dateStr: NSString = NSString(string: item.mPubDate)
                
                let range: NSRange = dateStr.rangeOfString("+")
                if (range.location != NSNotFound) {
                    dateStr = dateStr.substringToIndex(range.location - 1)
                }
                let range_: NSRange = dateStr.rangeOfString("-")
                if (range_.location != NSNotFound) {
                    dateStr = dateStr.substringToIndex(range_.location - 1)
                }
                
                dateStr = dateStr.stringByReplacingOccurrencesOfString("PST", withString: "")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("EST", withString: "")
                
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Jan", withString: "01")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Feb", withString: "02")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Mar", withString: "03")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Apr", withString: "04")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("May", withString: "05")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Jun", withString: "06")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Jul", withString: "07")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Aug", withString: "08")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Sep", withString: "09")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Oct", withString: "10")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Nov", withString: "11")
                dateStr = dateStr.stringByReplacingOccurrencesOfString("Dec", withString: "12")
                dateStr = dateStr.substringFromIndex(5)
                date = pubDateFormatter.dateFromString(dateStr as String)
            }
            
            if (date != nil) {
                article.date = date!
            } else {
                article.date = NSDate()
            }
            
            article.detail = item.mDescription
            //Log.d("save article " + article.title! + " "+item.mDate)
            saveArticle(urlString, data: article, setWatched: false, lastModified: lastModified)
        }

        
        func saveArticle(feedLink: String, data: Article, setWatched: Bool, lastModified: String?) {
            if (data.link == nil) {
                return
            }
            let managedContext = getManagedContext()
            
            var currentFeed: NSManagedObject? = getFeedEntity(feedLink, managedContext: managedContext)
            if (currentFeed == nil) {
                let feedEntity = NSEntityDescription.entityForName("FeedEntity", inManagedObjectContext: managedContext)
                currentFeed = NSManagedObject(entity: feedEntity!, insertIntoManagedObjectContext: managedContext)
                currentFeed?.setValue(feedLink, forKey: "link")
            }
            
            if (lastModified != nil) {
                currentFeed?.setValue(lastModified, forKey: "last_modified")
            }
            
            let fetchRequest = NSFetchRequest(entityName: "ArticleEntity")
            fetchRequest.predicate = NSPredicate(format: "link = %@", data.link!)
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.executeFetchRequest(fetchRequest)
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
                let entity = NSEntityDescription.entityForName("ArticleEntity", inManagedObjectContext: managedContext)
                articleObject = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            }
            
            /* Set the name attribute using key-value coding */
            articleObject!.setValue(data.title, forKey: "title")
            articleObject!.setValue(data.link, forKey: "link")
            articleObject!.setValue(data.detail, forKey: "detail")
            articleObject!.setValue(data.date, forKey: "date")
            let obj: AnyObject? = articleObject!.valueForKey("watched")
            if (setWatched) {
                articleObject!.setValue(true, forKey: "watched")
            } else if (obj == nil) {
                articleObject!.setValue(false, forKey: "watched")
            }
            if (currentFeed != nil) {
                let set: NSMutableSet = NSMutableSet()
                set.addObject(currentFeed!)
                articleObject!.setValue(set, forKey: "feed")
            }
            
            let updateSet: NSMutableSet = NSMutableSet()
            let articlesSet: NSSet? = currentFeed?.valueForKey("article") as? NSSet
            if (articlesSet != nil) {
                var all: [AnyObject]? = articlesSet?.allObjects
                if (all != nil) {
                    for i in 0 ..< all!.count {
                        let obj: NSManagedObject? = all![i] as? NSManagedObject
                        if (obj != nil) {
                            updateSet.addObject(obj!)
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
            let fetchRequest = NSFetchRequest(entityName: "ArticleEntity")
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            let sortDescriptors = [sortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.executeFetchRequest(fetchRequest)
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
            let fetchRequest = NSFetchRequest(entityName: "ArticleEntity")
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            let sortDescriptors = [sortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            fetchRequest.fetchOffset = FeedModelClient.ARTICLE_MAX_NUMBER
            
            /* Get result array from ManagedObjectContext */
            let array: [AnyObject]?
            do {
                array = try managedContext.executeFetchRequest(fetchRequest)
            } catch _ as NSError {
                array = nil
            }
            if (array == nil) {
                return
            }
            let deleteObjs = array as! [NSManagedObject]
            for obj in deleteObjs {
                managedContext.deleteObject(obj)
            }
            
            do {
                try managedContext.save()
            } catch let error {
                Log.d("Could not save \(error)")
            }
        }

        func getManagedContext() -> NSManagedObjectContext {
            /* Get ManagedObjectContext from AppDelegate */
            let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext: NSManagedObjectContext = appDelegate.managedObjectContext!
            return managedContext
        }
        
        func downloadWithDataTask(url: NSURL) {
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let task = session.dataTaskWithURL(url, completionHandler: {
                (data: NSData?, response: NSURLResponse?, error: NSError?) in
                if (data != nil && error == nil) {
                    // do something
                }
                session.finishTasksAndInvalidate()
            })
            task.resume()
        }
    }
    
    class MainOperation : NSOperation {
        private var mCallback: () -> Void
        
        init(callback: () -> Void) {
            mCallback = callback
        }
        
        override func main() {
            mCallback()
        }
    }
}