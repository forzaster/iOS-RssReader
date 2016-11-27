//
//  RssXmlParser.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/06.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation

class RssXmlParser: NSObject, XMLParserDelegate {
    class Item {
        var mTitle: String = ""
        var mLink: String = ""
        var mDescription: String = ""
        var mDate: String = ""
        var mPubDate: String = ""
        var mMediaUrl: String = ""
        var mMediaMime: String = ""
    }
    
    fileprivate let ROOT_TAG: [String] = ["rss", "rdf:RDF"]
    
    fileprivate var mParser: XMLParser
    
    fileprivate var mCurrentItem: Item? = nil
    
    fileprivate var mCurrentTag: String? = nil
    
    fileprivate var mItems: [Item] = []
    
    fileprivate var mTitle: String? = nil
    
    fileprivate var mLink: String? = nil
    
    fileprivate var mParseTitle: Bool = false
    
    fileprivate var mRootTagOk: Bool = false
    
    init(data: Data) {
        //Log.d(NSString(data:data, encoding:NSUTF8StringEncoding) as! String);
        mParser = XMLParser(data: data)
    }
    
    func parse() -> Bool {
        mParser.delegate = self
        let ret: Bool = mParser.parse()
        if (!ret) {
            return getCount() > 0 && mRootTagOk
        }
        return ret && mRootTagOk
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if (!mRootTagOk) {
            for i in 0 ..< ROOT_TAG.count {
                if (ROOT_TAG[i] == elementName) {
                    mRootTagOk = true
                    break
                }
            }
        }
        if (elementName == "item") {
            mCurrentItem = Item()
        }
        mCurrentTag = elementName
        if (mTitle == nil && mCurrentTag == "title") {
            mParseTitle = true
        }
        if (mCurrentItem != nil && mCurrentTag == "enclosure") {
            mCurrentItem?.mMediaUrl = attributeDict["url"]!
            mCurrentItem?.mMediaMime = attributeDict ["type"]!
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (mCurrentItem != nil) {
            if (mCurrentTag == "title") {
                mCurrentItem?.mTitle += string
            } else if (mCurrentTag == "link") {
                mCurrentItem?.mLink += string
            } else if (mCurrentTag == "description") {
                mCurrentItem?.mDescription += string
            } else if (mCurrentTag == "dc:date") {
                mCurrentItem?.mDate += string
            } else if (mCurrentTag == "pubDate") {
                mCurrentItem?.mPubDate += string
            }
        } else {
            if (mParseTitle) {
                if (mTitle == nil) {
                    mTitle = string
                } else {
                    mTitle = mTitle! + string
                }
            }
            if (mCurrentTag == "link") {
                mLink = string;
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName == "item" && mCurrentItem != nil) {
            mItems.append(mCurrentItem!)
            mCurrentItem = nil
        }
        if (mParseTitle) {
            mParseTitle = false
        }
        mCurrentTag = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        Log.d("!!!!!!ERR : " + error.localizedDescription)
    }
    
    func getItem(_ pos: Int) -> Item? {
        if (pos < 0 || pos >= mItems.count) {
            return nil;
        }
        return mItems[pos]
    }
    
    func getCount() -> Int {
        return mItems.count
    }
    
    func getTitle() -> String? {
        return mTitle
    }
    
    func getLink() -> String? {
        return mLink;
    }
}
