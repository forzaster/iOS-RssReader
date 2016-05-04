//
//  WebButtons.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/23.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

public class WebButtons : UIView {
    private struct Constants {
        static let BUTTON_WIDTH: CGFloat = 16.0
        static let BUTTON_HEIGHT: CGFloat = 20.0
        static let PADDING: Int = 0
        static let GAP: Int = 2
        static let EDGE_MARGIN_V: CGFloat = 0.0
        static let EDGE_MARGIN_H: CGFloat = 0.0
    }
    
    private let mLeftButton = WButton(isLeft: true)
    private let mRightButton = WButton(isLeft: false)
    private var mLeftCallback = {() -> Void in
    }
    private var mRightCallback = {() -> Void in
    }

    init() {
        super.init(frame: CGRectZero)
        setupButtons()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width
        let height = self.bounds.height
        
        let buttonWidth: Int = (Int(width) - Constants.PADDING*2) / 2
        let buttonHeight: Int = Int(height) - Constants.PADDING*2
        
        mLeftButton.frame = CGRect(x: Constants.PADDING, y: Constants.PADDING, width: buttonWidth, height: buttonHeight)
        mRightButton.frame = CGRect(x: Constants.PADDING + Constants.GAP + buttonWidth, y: Constants.PADDING, width: buttonWidth, height: buttonHeight)

    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        Log.d("change " + keyPath!)
    }
    
    func addClickEvent(leftCallback: () -> Void, rightCallback: () -> Void) {
        mLeftCallback = leftCallback
        mRightCallback = rightCallback
    }
    
    func setEnable(isEnableLeft : Bool, isEnableRight: Bool) {
        mLeftButton.enabled = isEnableLeft
        //mLeftButton.backgroundColor = isEnableLeft ? UIColor.blueColor() : UIColor.lightGrayColor()
        mLeftButton.updateColor()
        mRightButton.enabled = isEnableRight
        //mRightButton.backgroundColor = isEnableRight ? UIColor.redColor() : UIColor.lightGrayColor()
        mRightButton.updateColor()
    }
    
    func onLeftClick() {
        Log.d("onLeftClick")
        mLeftCallback()
    }
    
    func onRightClick() {
        Log.d("onRightClick")
        mRightCallback()
    }
    
    private func setupButtons() {
        mLeftButton.addTarget(self, action: #selector(WebButtons.onLeftClick), forControlEvents: UIControlEvents.TouchUpInside)
        mRightButton.addTarget(self, action: #selector(WebButtons.onRightClick), forControlEvents: UIControlEvents.TouchUpInside)
        //mLeftButton.setTitle(Localization.getString(Localization.BACK), forState: .Normal)
        //mRightButton.setTitle(Localization.getString(Localization.FORWARD), forState: .Normal)
        //mLeftButton.backgroundColor = UIColor.lightGrayColor()
        //mRightButton.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(mLeftButton)
        self.addSubview(mRightButton)
    }
    
    private class WButton : UIButton {
        
        private var mColor: CGColorRef
        private let mLeftArrow: Bool
        
        init(isLeft: Bool) {
            mColor = UIColor.blackColor().CGColor
            mLeftArrow = isLeft
            super.init(frame: CGRectZero)
            self.layer.cornerRadius = 5
            self.layer.borderColor = mColor
            self.layer.borderWidth = 1
            self.layer.backgroundColor = UIColor.whiteColor().CGColor

            self.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            self.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Disabled)
            self.enabled = false
            self.updateColor()
        }
        
        required init?(coder: NSCoder) {
            mColor = UIColor.blackColor().CGColor
            mLeftArrow = false
            super.init(coder: coder)
        }

        override func drawRect(rect: CGRect) {
            super.drawRect(rect)

            let context = UIGraphicsGetCurrentContext()

            let w = self.bounds.width
            let h = self.bounds.height
            let top: CGFloat = 8
            let side: CGFloat = 20
            
            CGContextSetStrokeColorWithColor(context, mColor)
            CGContextSetLineWidth(context, 2)
            if (mLeftArrow) {
                CGContextMoveToPoint(context, w - side, top)
                CGContextAddLineToPoint(context, side, h / 2)
                CGContextAddLineToPoint(context, w - side, h - top)
            } else {
                CGContextMoveToPoint(context, side, top)
                CGContextAddLineToPoint(context, w - side, h / 2)
                CGContextAddLineToPoint(context, side, h - top)
            }
            CGContextStrokePath(context)
        }
        
        func updateColor() {
            let color: CGColorRef = self.enabled ? UIColor.blackColor().CGColor : UIColor.lightGrayColor().CGColor
            if (!CGColorEqualToColor(mColor, color)) {
                mColor = color
                self.layer.borderColor = mColor
                setNeedsDisplay()
            }
        }
    }
    
}