//
//  Localization.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/11.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation

class Localization {
    // TODO localization
    
    static let OK: String = "Ok"
    static let ERROR: String = "Error"
    static let CANCEL: String = "Cancel"
    static let CHANNELS: String = "Channels"
    static let ARTICLES: String = "Articles"
    static let ADD_FEED: String = "AddFeed"
    static let INPUT_FEED_URL: String = "InputFeedUrl"
    static let PULL_TO_UPDATE: String = "PullToUpdate"
    static let UPDATING: String = "Updating"
    static let CAN_NOT_ADD: String = "CanNotAdd"
    static let SUCCESSFULLY_ADDED: String = "SuccessfullyAdded"
    static let DONE: String = "Done"
    static let ALREADY_ADDED: String = "AlreadyAdded"
    static let CAN_NOT_GET_ARTICLES: String = "CanNotGetArticles"
    static let CAN_NOT_ADD_ERROR_DESCRIPTION: String = "CanNotAddErrorDescription"
    static let BACK: String = "Back"
    static let FORWARD: String = "Forward"
    static let FEED_CHECK_RESULT: String = "FeedCheckResult"
    static let DELETE: String = "Delete"
    static let SHARE: String = "Share"
    
    static func get(str: String) -> String {
        return NSLocalizedString(str, tableName: "Localization", comment: str)
    }
    
    static func getTitlePlusMessage(title: String?, str: String) -> String {
        let message = get(str)
        var ret = message
        if (title != nil) {
            ret = "[" + title! + "] : " + message
        }
        return ret
    }
}