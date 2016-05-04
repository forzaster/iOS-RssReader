//
//  HttpGetClient.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/06.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation

class HttpGetClient {

    func get(urlStr: String, callback: (NSData?, NSHTTPURLResponse?, NSError?) -> Void) {
        let targetUrl: NSURL = NSURL(string: urlStr)!
        let session: NSURLSession = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(targetUrl, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            let httpResponse = response as? NSHTTPURLResponse
            if (error != nil) {
                Log.d((error?.description)!)
            }
            if (httpResponse != nil) {
                Log.d("status=" + String(stringInterpolationSegment: httpResponse?.statusCode))
                if (httpResponse!.MIMEType != nil) {
                    Log.d("type=" + httpResponse!.MIMEType!)
                }
            }

            NSOperationQueue.mainQueue().addOperation(NSBlockOperation(block: { () -> Void in
                callback(data, httpResponse, error)
            }))
        })
        task.resume()
    }
}