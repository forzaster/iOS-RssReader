//
//  TableItemView.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/20.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

open class TableItemView : UITableViewCell {
    fileprivate struct Constants {
        static let TITLE_FONT: CGFloat = 16.0
        static let SUB_TEXT_FONT: CGFloat = 12.0
        static let PADDING: Int = 10
        static let GAP_L: Int = 6
        static let GAP_S: Int = 4
    }
    
    var mTitle = UILabel()
    var mSubText1 = UILabel()
    var mSubText2 = UILabel()
    var mDetail = UILabel()
    var mThumb = UIView()
    //var mMark1 = UILabel()
    //var mMark2 = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        //First Call Super
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(mThumb)
        
        /*
        mMark1.text = ""
        mMark1.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        self.addSubview(mMark1)
        mMark2.text = ""
        mMark2.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        self.addSubview(mMark2)
         */

        mTitle.text = ""
        mTitle.font = UIFont.systemFont(ofSize: Constants.TITLE_FONT)
        mTitle.numberOfLines = 2
        mTitle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        self.addSubview(mTitle)
        
        mSubText1.text = ""
        mSubText1.font = UIFont.systemFont(ofSize: Constants.SUB_TEXT_FONT)
        self.addSubview(mSubText1)

        mSubText2.text = ""
        mSubText2.font = UIFont.systemFont(ofSize: Constants.SUB_TEXT_FONT)
        self.addSubview(mSubText2)

        mDetail.text = ""
        mDetail.font = UIFont.systemFont(ofSize: Constants.SUB_TEXT_FONT)
        mDetail.textColor = UIColor.gray
        mDetail.numberOfLines = 2
        mDetail.lineBreakMode = NSLineBreakMode.byTruncatingTail
        self.addSubview(mDetail)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width
        let height = self.bounds.height

        let colorBarWidth = Constants.PADDING
        let viewWidth = Int(width) - Constants.PADDING*2 - colorBarWidth
        
        let subHeight = Int(Constants.SUB_TEXT_FONT)
        
        let xPos = Constants.PADDING + colorBarWidth// + Int(height)
        let padding = Constants.PADDING
        
        mThumb.frame = CGRect(x: 0, y: 0, width: CGFloat(colorBarWidth), height: height)
        
        /*
        let markSize = (Int(height) - 2 * Constants.PADDING) / 2
        mMark1.frame = CGRect(x: Constants.PADDING, y: Constants.PADDING, width: markSize, height: markSize)
        mMark1.font = UIFont.boldSystemFontOfSize(CGFloat(markSize))
        mMark2.frame = CGRect(x: Constants.PADDING + markSize, y: Constants.PADDING + markSize, width: markSize, height: markSize)
        mMark2.font = UIFont.boldSystemFontOfSize(CGFloat(markSize - Constants.PADDING/2))
        */
        
        var y = padding
        mSubText1.frame = CGRect(x: xPos, y: y, width: viewWidth,  height: subHeight)
        y += subHeight + Constants.GAP_L

        let titleFrame = mTitle.frame
        mTitle.frame = CGRect(x: xPos, y: y, width: viewWidth, height: Int(titleFrame.height + 0.5))
        y += Int(mTitle.frame.height + 0.5) + Constants.GAP_S
        
        let detailFrame = mDetail.frame
        mDetail.frame = CGRect(x: xPos, y: y, width: viewWidth,  height: Int(detailFrame.height))
        y += Int(mDetail.frame.height + 0.5) + Constants.GAP_S
        
        mSubText2.frame = CGRect(x: xPos, y: y, width: viewWidth,  height: subHeight)

        //Log.d("layoutSubView " + String(hash) + ". " + String(y + Int(mDetail.frame.height)))
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        mTitle.sizeToFit()
        mDetail.sizeToFit()
        let ret: CGSize = CGSize(width: size.width, height: calcHeight())
        return ret
    }
    
    fileprivate func calcHeight() -> CGFloat {
        var height:CGFloat = 0.0
        let subHeight = CGFloat(Constants.SUB_TEXT_FONT)
        height += CGFloat(Constants.PADDING * 2)
        height += subHeight
        height += CGFloat(Constants.GAP_L)
        height += mTitle.frame.height
        height += CGFloat(Constants.GAP_S)
        height += subHeight
        height += CGFloat(Constants.GAP_S)
        height += mDetail.frame.height
        return height
    }
    
    open static func getHeight() -> CGFloat {
        let text = "temp" as NSString
        var height:CGFloat = 0.0
        height += text.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: Constants.TITLE_FONT)]).height
        let size = text.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: Constants.SUB_TEXT_FONT)])
        height += size.height * 2
        height += CGFloat(Constants.PADDING * 2)
        height += CGFloat(Constants.GAP_S + Constants.GAP_L)
        return height
    }
    
    open func setMark(_ text: String) {
        let size = text.characters.count
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        if (size <= 0) {
            //mMark1.text = ""
            //mMark2.text = ""
            mThumb.backgroundColor = UIColor.lightGray
            return
        }

        let hash = text.hashValue
        r = CGFloat(hash >> 16 & 0xff) / 255.0
        g = CGFloat(hash >> 8 & 0xff) / 255.0
        b = CGFloat(hash >> 0 & 0xff) / 255.0
        mThumb.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 0.6)
        
        /*
        let aaa = text[text.startIndex]
        mMark1.text = String(aaa)

        if (size < 2) {
            mMark2.text = ""
            return
        }
        let bbb = text[text.startIndex.advancedBy(1)]
        mMark2.text = String(bbb)
         */
    }
    
    
    
}
