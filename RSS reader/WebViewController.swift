//
//  WebViewController.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/09.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



protocol RssUrlRetriever {
    func retrieve(_ url: URL) -> String?
}

class WebViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate {
    
    fileprivate let DEFAULT_URL = "http://www.google.com"
    
    @IBOutlet weak var mWebView: UIWebView!
    
    var mUrlString: String? = nil
    
    var mTitle: String? = nil
    
    fileprivate var mAddButton: UIBarButtonItem?  = nil

    fileprivate var mActionButton: UIBarButtonItem?  = nil
    
    fileprivate var mRssUrl: String? = nil
    
    fileprivate var mAddressField: UITextField? = nil
    
    fileprivate var mWebButtons: WebButtons?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mAddButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(WebViewController.onAddClick(_:)))
        mActionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebViewController.onActionClick(_:)))
        
        self.navigationItem.rightBarButtonItems = [
            mAddButton!,
            UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(WebViewController.onSearchClick(_:))),
            mActionButton!
        ]
        
        mAddressField = UITextField()
        let margin: CGFloat = 5.0
        let w = self.navigationController?.navigationBar.frame.width
        let h = self.navigationController?.navigationBar.frame.height
        mAddressField!.frame = CGRect(x: 0, y: margin, width: w!, height: h! / 2)
        mAddressField!.font = UIFont.systemFont(ofSize: h! / 2 - 4)
        mAddressField!.borderStyle = UITextBorderStyle.roundedRect
        mAddressField!.placeholder = mUrlString
        mAddressField!.backgroundColor = UIColor.white
        mAddressField!.keyboardType = UIKeyboardType.URL
        mAddressField!.returnKeyType = UIReturnKeyType.go
        mAddressField!.clearButtonMode = UITextFieldViewMode.whileEditing
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
        
        let url = URL(string: mUrlString!)
        let req = URLRequest(url: url!)
        mWebView.loadRequest(req)
    }
    
    override func viewDidLayoutSubviews() {
        var bottomSize: CGFloat = 0
        if (!self.hidesBottomBarWhenPushed) {
            bottomSize = CGFloat(self.bottomLayoutGuide.length)
            
        }
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
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        Log.d(error.localizedDescription)
        if  (error as NSError).code == NSURLErrorCancelled {
            Log.d("load error")
            return
        }
        let url = mAddressField!.text
        Log.d("re-load " + url!)
        HttpGetClient().get(url!, callback: {(data: Data?, response: HTTPURLResponse?, error: NSError?) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            var rssLoaded = false
            if (response != nil && response!.statusCode == 200 && data != nil) {
                Log.d("GET mime=" + response!.mimeType!)
                let mime = response!.mimeType
                if (mime != nil) {
                    let range1 = mime!.range(of: "xml", options: .caseInsensitive)
                    let range2 = mime!.range(of: "rss", options: .caseInsensitive)
                     if ((range1 != nil && !range1!.isEmpty) && (range2 != nil && !range2!.isEmpty)) {
                        //Log.d(NSString(data:data!, encoding:NSUTF8StringEncoding) as! String)
                        var xmlString = NSString(data:data!, encoding:String.Encoding.utf8.rawValue) as! String
                        xmlString = "<pre>" + xmlString + "</pre>"
                        //self.mWebView.loadData(data!, MIMEType: "text/xml", textEncodingName: "utf-8", baseURL: nil)
                        self.mWebView.loadHTMLString(xmlString, baseURL: URL(string: url!))
                        rssLoaded = true
                    }
                }
            }
            if (!rssLoaded) {
                self.mWebView.loadHTMLString("Load error", baseURL: nil)
            }
        })
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let str = request.mainDocumentURL?.description
        if (str != nil) {
            Log.d("Start Load " + str!);
        }
        mRssUrl = URLChecker.check(request.mainDocumentURL, addButton: mAddButton!)
        if (mRssUrl != nil) {
            Log.d("RSS candidate=" + mRssUrl!)
        }
        if (request.url?.scheme == "about") {
            Log.d("empty url request")
            return true
        }
        if (str != nil && request.url?.scheme == "feed") {
            let newUrl = str?.replacingOccurrences(of: "feed://", with: "http://", options: [], range: nil)
            if (newUrl != nil) {
                HttpGetClient().get(newUrl!,
                    callback: {(data: Data?, response: HTTPURLResponse?, error: NSError?) -> Void in
                        if (response != nil && response!.statusCode == 200 && data != nil) {
                            let xmlString = NSString(data:data!, encoding:String.Encoding.utf8.rawValue) as! String
                            Log.d("result = " + xmlString)
                            self.mWebView.loadHTMLString("<pre>" + xmlString + "</pre>", baseURL: URL(string: newUrl!))
                        }
                    })
            }
            return false
        }
        
        mUrlString = request.mainDocumentURL?.description
        mAddressField?.text = mUrlString
        if (navigationType == UIWebViewNavigationType.linkClicked) {
            mTitle = nil
        }
        mActionButton!.isEnabled = mUrlString != nil
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Log.d("start load");
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        mWebButtons?.setEnable(webView.canGoBack, isEnableRight: webView.canGoForward)
        Log.d("finish load");
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let text = textField.text
        textField.resignFirstResponder()
        if (text == nil || text == "") {
            return false
        }
        mUrlString = text
        let url = URL(string: text!)
        let req = URLRequest(url: url!)
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
    
    func onSearchClick(_ sender: UIButton) {
        let url = URL(string: DEFAULT_URL)
        let req = URLRequest(url: url!)
        mWebView.loadRequest(req)
    }
    
    func onAddClick(_ sender: UIButton) {
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
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }

    func saveFeed(_ url: String) {
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
    
    func createErrorString(_ error: String) -> String {
        return error + "\n" + Localization.get(Localization.CAN_NOT_ADD_ERROR_DESCRIPTION)
    }
    
    func showErrorMessage(_ message: String) {
        showMessage(Localization.get(Localization.ERROR), message: message)
    }

    func showMessage(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .default) {
            action in
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func onActionClick(_ sender: UIButton) {
        guard let urlStr = mUrlString else {
            self.showErrorMessage(Localization.get(Localization.SHARE) + " " + Localization.get(Localization.ERROR))
            return
        }
        guard let url = URL(string: urlStr) else {
            self.showErrorMessage(Localization.get(Localization.SHARE) + " " + Localization.get(Localization.ERROR))
            return
        }
        var title = mTitle
        if (title == nil) {
            title = mWebView.stringByEvaluatingJavaScript(from: "document.title")
        }
        var items: [AnyObject]
        if let t = title {
            items = [t as AnyObject, url as AnyObject]
        } else {
            items = [url as AnyObject]
        }
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.postToWeibo,
                                                        UIActivityType.saveToCameraRoll]
        present(activityViewController, animated: true, completion: nil)
    }
    
    class URLChecker {
        
        class LiveDoorRss : RssUrlRetriever {
            func retrieve(_ url: URL) -> String? {
                Log.d("retrieve livedoor blog " + url.absoluteString)
                var path: [AnyObject]? = url.pathComponents as [AnyObject]?
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
            func retrieve(_ url: URL) -> String? {
                Log.d("retrieve ameblo blog " + url.absoluteString)
                var path: [AnyObject]? = url.pathComponents as [AnyObject]?
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
            func retrieve(_ url: URL) -> String? {
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
        
        static func check(_ url: URL?, addButton: UIBarButtonItem) -> String? {
            if (url == nil) {
                Log.d("Unsupport nil")
                addButton.isEnabled = false
                return nil;
            }
            let urlString: String? = url?.absoluteString
            if (urlString == nil) {
                Log.d("Unsupport nil")
                addButton.isEnabled = false
                return nil;
            }
            for i in 0 ..< SUPPORT_URLS.count {
                if ((urlString!).characters.starts(with: SUPPORT_URLS[i].characters)) {
                    Log.d("Support " + urlString!)
                    addButton.isEnabled = true
                    return RETRIEVERS[i].retrieve(url!)
                }
            }
            for i in 0 ..< SUPPORT_URLS_REGEX.count {
                let regex = try? NSRegularExpression(pattern: SUPPORT_URLS_REGEX[i], options: [])
                let range = NSMakeRange(0, (urlString! as NSString).length)
                let matches = regex?.matches(in: urlString!, options: [], range: range)
                if (matches?.count > 0) {
                    Log.d("Support regex !!! " + urlString!);
                    addButton.isEnabled = true
                    return RETRIEVERS_REGEX[i].retrieve(url!)
                }
            }
            Log.d("Unsupport " + urlString!)
            //addButton.enabled = false
            addButton.isEnabled = true
            return nil
        }
    }
    
}
