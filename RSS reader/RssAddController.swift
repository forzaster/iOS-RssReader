//
//  RssAddController.swift
//  RSSreader
//
//  Created by n-naka on 2016/04/29.
//  Copyright © 2016年 forzaster. All rights reserved.
//

import UIKit

class RssAddController {
    func start(vc: UIViewController) {
        let alertController = RssAddDialogController.create(nil, url: nil, callback: {
            (text) -> Void in
            self.saveFeed(vc, url: text)
        })
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func saveFeed(vc: UIViewController, url: String) {
        FeedModelClient.sInstance.saveFeed(url, callback: {(error: Int, title: String?) -> Void in
            if (error == FeedModelClient.RET_SUCCESS) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.SUCCESSFULLY_ADDED)
                self.showMessage(vc, title: Localization.get(Localization.DONE), message: message)
            } else if (error == FeedModelClient.RET_SAVE_FEED_ALREADY_ADDED) {
                let message = Localization.getTitlePlusMessage(title, str: Localization.ALREADY_ADDED)
                self.showMessage(vc, title: Localization.get(Localization.DONE), message: message)
            } else {
                self.showMessage(vc, title: Localization.get(Localization.ERROR), message: Localization.get(Localization.CAN_NOT_ADD))
            }
        })
    }
    
    func showMessage(vc: UIViewController, title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
            action in
        }
        alertController.addAction(okAction)
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
    
}