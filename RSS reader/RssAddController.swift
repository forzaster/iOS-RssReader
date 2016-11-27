//
//  RssAddController.swift
//  RSSreader
//
//  Created by n-naka on 2016/04/29.
//  Copyright © 2016年 forzaster. All rights reserved.
//

import UIKit

class RssAddController {
    func start(_ vc: UIViewController) {
        let alertController = RssAddDialogController.create(nil, url: nil, callback: {
            (text) -> Void in
            self.saveFeed(vc, url: text)
        })
        vc.present(alertController, animated: true, completion: nil)
    }
    
    func saveFeed(_ vc: UIViewController, url: String) {
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
    
    func showMessage(_ vc: UIViewController, title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .default) {
            action in
        }
        alertController.addAction(okAction)
        vc.present(alertController, animated: true, completion: nil)
    }
    
}
