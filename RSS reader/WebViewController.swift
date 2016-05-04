//
//  WebViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/09.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit


protocol RssUrlRetriever {
    func retrieve(url: NSURL) -> String?
}

class WebViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate {
    
    private let DEFAULT_URL = "http://www.google.com"
    
    @IBOutlet weak var mWebView: UIWebView!
    
    var mUrlString: String? = nil
    
    var mTitle: String? = nil
    
    private var mAddButton: UIBarButtonItem?  = nil

    private var mActionButton: UIBarButtonItem?  = nil
    
    private var mRssUrl: String? = nil
    
    private var mAddressField: UITextField? = nil
    
    private var mWebButtons: WebButtons?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mAddButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(WebViewController.onAddClick(_:)))
        mActionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(WebViewController.onActionClick(_:)))
        
        self.navigationItem.rightBarButtonItems = [
            mAddButton!,
            UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(WebViewController.onSearchClick(_:))),
            mActionButton!
        ]
        
        mAddressField = UITextField()
        let margin: CGFloat = 5.0
        let w = self.navigationController?.navigationBar.frame.width
        let h = self.navigationController?.navigationBar.frame.height
        mAddressField!.frame = CGRect(x: 0, y: margin, width: w!, height: h! / 2)
        mAddressField!.font = UIFont.systemFontOfSize(h! / 2 - 4)
        mAddressField!.borderStyle = UITextBorderStyle.RoundedRect
        mAddressField!.placeholder = mUrlString
        mAddressField!.backgroundColor = UIColor.whiteColor()
        mAddressField!.keyboardType = UIKeyboardType.URL
        mAddressField!.returnKeyType = UIReturnKeyType.Go
        mAddressField!.clearButtonMode = UITextFieldViewMode.WhileEditing
        mAddressField!.delegate = self
        mWebView.delegate = self
        
        self.navigationItem.titleView = mAddressField
        
        FeedModelClient.sInstance.fetchFeeds({
            (Int) -> Void in
                Log.d("fetchFeeds done")
        })
        
        if (mUrlString == nil) {
            mUrlString = DEFAULT_URL
        }

        mWebButtons = WebButtons()
        mWebButtons!.addClickEvent(
            {() -> Void in
                self.back()
            },
            rightCallback: {() -> Void in
                self.forward()
            })

        self.view.addSubview(mWebButtons!)
        
        let url = NSURL(string: mUrlString!)
        let req = NSURLRequest(URL: url!)
        mWebView.loadRequest(req)
    }
    
    override func viewDidLayoutSubviews() {
        var bottomSize: CGFloat = 0
        if (!self.hidesBottomBarWhenPushed) {
            bottomSize = CGFloat(self.bottomLayoutGuide.length)
            
        }
        self.bottomLayoutGuide.length
        let padding: CGFloat = 4
        let bw: Int = 90
        let bh: Int = 30
        let bx: Int = Int(mWebView.frame.origin.x + mWebView.frame.width - CGFloat(bw) - padding)
        let webViewBottom: CGFloat = mWebView.frame.origin.y + mWebView.frame.height
        let by: Int = Int(webViewBottom - CGFloat(bh) - padding - bottomSize)
        mWebButtons!.frame = CGRect(x: bx, y: by, width: bw, height: bh)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        Log.d(error!.description)
        if (error!.code != 102) {
            Log.d("load error")
            return
        }
        let url = mAddressField!.text
        Log.d("re-load " + url!)
        HttpGetClient().get(url!, callback: {(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            var rssLoaded = false
            if (response != nil && response!.statusCode == 200 && data != nil) {
                Log.d("GET mime=" + response!.MIMEType!)
                let mime = response!.MIMEType
                if (mime != nil) {
                    let range1 = mime!.rangeOfString("xml", options: .CaseInsensitiveSearch)
                    let range2 = mime!.rangeOfString("rss", options: .CaseInsensitiveSearch)
                     if ((range1 != nil && !range1!.isEmpty) && (range2 != nil && !range2!.isEmpty)) {
                        //Log.d(NSString(data:data!, encoding:NSUTF8StringEncoding) as! String)
                        var xmlString = NSString(data:data!, encoding:NSUTF8StringEncoding) as! String
                        xmlString = "<pre>" + xmlString + "</pre>"
                        //self.mWebView.loadData(data!, MIMEType: "text/xml", textEncodingName: "utf-8", baseURL: nil)
                        self.mWebView.loadHTMLString(xmlString, baseURL: NSURL(string: url!))
                        rssLoaded = true
                    }
                }
            }
            if (!rssLoaded) {
                self.mWebView.loadHTMLString("Load error", baseURL: nil)
            }
        })
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let str = request.mainDocumentURL?.description
        if (str != nil) {
            Log.d("Start Load " + str!);
        }
        mRssUrl = URLChecker.check(request.mainDocumentURL, addButton: mAddButton!)
        if (mRssUrl != nil) {
            Log.d("RSS candidate=" + mRssUrl!)
        }
        if (request.URL?.scheme == "about") {
            Log.d("empty url request")
            return true
        }
        if (str != nil && request.URL?.scheme == "feed") {
            let newUrl = str?.stringByReplacingOccurrencesOfString("feed://", withString: "http://", options: [], range: nil)
            if (newUrl != nil) {
                HttpGetClient().get(newUrl!,
                    callback: {(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in
                        if (response != nil && response!.statusCode == 200 && data != nil) {
                            let xmlString = NSString(data:data!, encoding:NSUTF8StringEncoding) as! String
                            Log.d("result = " + xmlString)
                            self.mWebView.loadHTMLString("<pre>" + xmlString + "</pre>", baseURL: NSURL(string: newUrl!))
                        }
                    })
            }
            return false
        }
        
        mUrlString = request.mainDocumentURL?.description
        mAddressField?.text = mUrlString
        if (navigationType == UIWebViewNavigationType.LinkClicked) {
            mTitle = nil
        }
        mActionButton!.enabled = mUrlString != nil
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Log.d("start load");
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        mWebButtons?.setEnable(webView.canGoBack, isEnableRight: webView.canGoForward)
        Log.d("finish load");
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let text = textField.text
        textField.resignFirstResponder()
        if (text == nil || text == "") {
            return false
        }
        mUrlString = text
        let url = NSURL(string: text!)
        let req = NSURLRequest(URL: url!)
        Log.d("load " + text!)
        mWebView.loadRequest(req)
        return true
    }
    
    func back() {
        if (mWebView.canGoBack) {
            mWebView.goBack()
        }
    }
    
    func forward() {
        if (mWebView.canGoForward) {
            mWebView.goForward()
        }
    }
    
    func onSearchClick(sender: UIButton) {
        let url = NSURL(string: DEFAULT_URL)
        let req = NSURLRequest(URL: url!)
        mWebView.loadRequest(req)
    }
    
    func onAddClick(sender: UIButton) {
        var url = mRssUrl
        if (url == nil) {
            url = mUrlString
        }
        if (url == nil) {
            showErrorMessage(createErrorString(Localization.get(Localization.CAN_NOT_ADD)))
            return
        }
        FeedModelClient.sInstance.saveFeed(url!, callback: {(error: Int, title: String?) -> Void in
            if (error == FeedModelClient.RET_SUCCESS) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.SUCCESSFULLY_ADDED)
                self.showMessage(Localization.get(Localization.DONE), message: message)
            } else if (error == FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.ALREADY_ADDED)
                self.showErrorMessage(message)
            } else {
                let alertController = RssAddDialogController.create(Localization.get(Localization.FEED_CHECK_RESULT), url: url, callback: {
                    (text) -> Void in
                        self.saveFeed(text)
                })
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }

    func saveFeed(url: String) {
        FeedModelClient.sInstance.saveFeed(url, callback: {(error: Int, title: String?) -> Void in
            if (error == FeedModelClient.RET_SUCCESS) {
                self.showMessage(Localization.get(Localization.DONE), message: Localization.get(Localization.SUCCESSFULLY_ADDED))
            } else if (error == FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED) {
                self.showErrorMessage(Localization.get(Localization.ALREADY_ADDED))
            } else {
                self.showErrorMessage(self.createErrorString(url))
            }
        })
    }
    
    func createErrorString(error: String) -> String {
        return error + "\n" + Localization.get(Localization.CAN_NOT_ADD_ERROR_DESCRIPTION)
    }
    
    func showErrorMessage(message: String) {
        showMessage(Localization.get(Localization.ERROR), message: message)
    }

    func showMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
            action in
        }
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func onActionClick(sender: UIButton) {
        guard let urlStr = mUrlString else {
            self.showErrorMessage(Localization.get(Localization.SHARE) + " " + Localization.get(Localization.ERROR))
            return
        }
        guard let url = NSURL(string: urlStr) else {
            self.showErrorMessage(Localization.get(Localization.SHARE) + " " + Localization.get(Localization.ERROR))
            return
        }
        var title = mTitle
        if (title == nil) {
            title = mWebView.stringByEvaluatingJavaScriptFromString("document.title")
        }
        var items: [AnyObject]
        if let t = title {
            items = [t, url]
        } else {
            items = [url]
        }
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePostToWeibo,
                                                        UIActivityTypeSaveToCameraRoll]
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    class URLChecker {
        
        class LiveDoorRss : RssUrlRetriever {
            func retrieve(url: NSURL) -> String? {
                Log.d("retrieve livedoor blog " + url.absoluteString)
                var path: [AnyObject]? = url.pathComponents
                if (path == nil) {
                    return nil
                }
                if (path!.count > 1) {
                    let name: AnyObject = path![1]
                    let nameString: String? = name as? String
                    if (nameString != nil) {
                        return "http://blog.livedoor.jp/" + nameString! + "/index.rdf"
                    }
                }
                return nil
            }
        }
        
        class AmebloRss : RssUrlRetriever {
            func retrieve(url: NSURL) -> String? {
                Log.d("retrieve ameblo blog " + url.absoluteString)
                var path: [AnyObject]? = url.pathComponents
                if (path == nil) {
                    return nil
                }
                if (path!.count > 1) {
                    let name: AnyObject = path![1]
                    let nameString: String? = name as? String
                    if (nameString != nil) {
                        return "http://rssblog.ameba.jp/" + nameString! + "/rss.html"
                    }
                }
                return nil
            }
        }
        
        class HatenaRss : RssUrlRetriever {
            func retrieve(url: NSURL) -> String? {
                Log.d("retrieve hatena blog " + url.absoluteString)
                Log.d("host=" + url.host!)
                
                let host : String? = url.host
                let scheme : String? = url.scheme
                if (host != nil && scheme != nil) {
                    Log.d(scheme! + "://" + host! + "/rss")
                    return scheme! + "://" + host! + "/rss"
                }
                return nil
            }
        }

        static var SUPPORT_URLS: [String] = [
            "http://blog.livedoor.jp/",
            "http://ameblo.jp/",
            "http://s.ameblo.jp/",
        ]
        static var RETRIEVERS: [RssUrlRetriever] = [
            LiveDoorRss(),
            AmebloRss(),
            AmebloRss()
        ]

        static var SUPPORT_URLS_REGEX: [String] = [
            "http://(.*)\\.hatenablog\\.com/.*"
        ]
        static var RETRIEVERS_REGEX: [RssUrlRetriever] = [
            HatenaRss(),
        ]
        
        static func check(url: NSURL?, addButton: UIBarButtonItem) -> String? {
            if (url == nil) {
                Log.d("Unsupport nil")
                addButton.enabled = false
                return nil;
            }
            let urlString: String? = url?.absoluteString
            if (urlString == nil) {
                Log.d("Unsupport nil")
                addButton.enabled = false
                return nil;
            }
            for i in 0 ..< SUPPORT_URLS.count {
                if ((urlString!).characters.startsWith(SUPPORT_URLS[i].characters)) {
                    Log.d("Support " + urlString!)
                    addButton.enabled = true
                    return RETRIEVERS[i].retrieve(url!)
                }
            }
            for i in 0 ..< SUPPORT_URLS_REGEX.count {
                let regex = try? NSRegularExpression(pattern: SUPPORT_URLS_REGEX[i], options: [])
                let range = NSMakeRange(0, (urlString! as NSString).length)
                let matches = regex?.matchesInString(urlString!, options: [], range: range)
                if (matches?.count > 0) {
                    Log.d("Support regex !!! " + urlString!);
                    addButton.enabled = true
                    return RETRIEVERS_REGEX[i].retrieve(url!)
                }
            }
            Log.d("Unsupport " + urlString!)
            //addButton.enabled = false
            addButton.enabled = true
            return nil
        }
    }
    
}