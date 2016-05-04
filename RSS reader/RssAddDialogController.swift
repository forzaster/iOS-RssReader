//
//  RssAddDialogController.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/23.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

class RssAddDialogController {

    static func create(msg: String?, url: String?, callback: (text: String) -> Void) -> UIAlertController {
        var message: String;
        if (msg != nil) {
            message = msg! + Localization.get(Localization.INPUT_FEED_URL)
        } else {
            message = Localization.get(Localization.INPUT_FEED_URL)
        }
        let alertController = UIAlertController(title: Localization.get(Localization.ADD_FEED), message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: Localization.get(Localization.OK), style: .Default) {
            action in
                let textFields:Array<UITextField>? =  alertController.textFields 
                if textFields != nil {
                    for textField:UITextField in textFields! {
                        Log.d(textField.text!)
                        callback(text: textField.text!)
                    }
                }
        }
        let cancelAction = UIAlertAction(title: Localization.get(Localization.CANCEL), style: .Cancel) {
            action in
                Log.d("Pushed CANCEL!")
        }

        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        alertController.addTextFieldWithConfigurationHandler({
            (text: UITextField) -> Void in
            text.keyboardType = UIKeyboardType.URL
            if (url == nil) {
                text.text = "http://"
            } else {
                text.text = url
            }
        })
        return alertController
    }
}