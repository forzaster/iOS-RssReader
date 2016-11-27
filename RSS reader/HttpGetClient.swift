//
//  HttpGetClient.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/06.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation

class HttpGetClient {

    func get(_ urlStr: String, callback: @escaping (Data?, HTTPURLResponse?, NSError?) -> Void) {
        let targetUrl: URL = URL(string: urlStr)!
        let session: URLSession = URLSession.shared
        let task = session.dataTask(with: targetUrl, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
            let httpResponse = response as? HTTPURLResponse
            if (error != nil) {
                Log.d((error?.description)!)
            }
            if (httpResponse != nil) {
                Log.d("status=" + String(stringInterpolationSegment: httpResponse?.statusCode))
                if (httpResponse!.mimeType != nil) {
                    Log.d("type=" + httpResponse!.mimeType!)
                }
            }

            OperationQueue.main.addOperation(BlockOperation(block: { () -> Void in
                callback(data, httpResponse, error)
            }))
        } as! (Data?, URLResponse?, Error?) -> Void)
        task.resume()
    }
}
