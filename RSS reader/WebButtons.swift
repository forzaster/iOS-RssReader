//
//  WebButtons.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/23.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

open class WebButtons : UIView {
    fileprivate struct Constants {
        static let BUTTON_WIDTH: CGFloat = 16.0
        static let BUTTON_HEIGHT: CGFloat = 20.0
        static let PADDING: Int = 0
        static let GAP: Int = 2
        static let EDGE_MARGIN_V: CGFloat = 0.0
        static let EDGE_MARGIN_H: CGFloat = 0.0
    }
    
    fileprivate let mLeftButton = WButton(isLeft: true)
    fileprivate let mRightButton = WButton(isLeft: false)
    fileprivate var mLeftCallback = {() -> Void in
    }
    fileprivate var mRightCallback = {() -> Void in
    }

    init() {
        super.init(frame: CGRect.zero)
        setupButtons()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width
        let height = self.bounds.height
        
        let buttonWidth: Int = (Int(width) - Constants.PADDING*2) / 2
        let buttonHeight: Int = Int(height) - Constants.PADDING*2
        
        mLeftButton.frame = CGRect(x: Constants.PADDING, y: Constants.PADDING, width: buttonWidth, height: buttonHeight)
        mRightButton.frame = CGRect(x: Constants.PADDING + Constants.GAP + buttonWidth, y: Constants.PADDING, width: buttonWidth, height: buttonHeight)

    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        Log.d("change " + keyPath!)
    }
    
    func addClickEvent(_ leftCallback: @escaping () -> Void, rightCallback: @escaping () -> Void) {
        mLeftCallback = leftCallback
        mRightCallback = rightCallback
    }
    
    func setEnable(_ isEnableLeft : Bool, isEnableRight: Bool) {
        mLeftButton.isEnabled = isEnableLeft
        //mLeftButton.backgroundColor = isEnableLeft ? UIColor.blueColor() : UIColor.lightGrayColor()
        mLeftButton.updateColor()
        mRightButton.isEnabled = isEnableRight
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
    
    fileprivate func setupButtons() {
        mLeftButton.addTarget(self, action: #selector(WebButtons.onLeftClick), for: UIControlEvents.touchUpInside)
        mRightButton.addTarget(self, action: #selector(WebButtons.onRightClick), for: UIControlEvents.touchUpInside)
        //mLeftButton.setTitle(Localization.getString(Localization.BACK), forState: .Normal)
        //mRightButton.setTitle(Localization.getString(Localization.FORWARD), forState: .Normal)
        //mLeftButton.backgroundColor = UIColor.lightGrayColor()
        //mRightButton.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(mLeftButton)
        self.addSubview(mRightButton)
    }
    
    fileprivate class WButton : UIButton {
        
        fileprivate var mColor: CGColor
        fileprivate let mLeftArrow: Bool
        
        init(isLeft: Bool) {
            mColor = UIColor.black.cgColor
            mLeftArrow = isLeft
            super.init(frame: CGRect.zero)
            self.layer.cornerRadius = 5
            self.layer.borderColor = mColor
            self.layer.borderWidth = 1
            self.layer.backgroundColor = UIColor.white.cgColor

            self.setTitleColor(UIColor.black, for: UIControlState())
            self.setTitleColor(UIColor.lightGray, for: UIControlState.disabled)
            self.isEnabled = false
            self.updateColor()
        }
        
        required init?(coder: NSCoder) {
            mColor = UIColor.black.cgColor
            mLeftArrow = false
            super.init(coder: coder)
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)

            let context = UIGraphicsGetCurrentContext()

            let w = self.bounds.width
            let h = self.bounds.height
            let top: CGFloat = 8
            let side: CGFloat = 20
            
            context?.setStrokeColor(mColor)
            context?.setLineWidth(2)
            if (mLeftArrow) {
                context?.move(to: CGPoint(x: w - side, y: top))
                context?.addLine(to: CGPoint(x: side, y: h / 2))
                context?.addLine(to: CGPoint(x: w - side, y: h - top))
            } else {
                context?.move(to: CGPoint(x: side, y: top))
                context?.addLine(to: CGPoint(x: w - side, y: h / 2))
                context?.addLine(to: CGPoint(x: side, y: h - top))
            }
            context?.strokePath()
        }
        
        func updateColor() {
            let color: CGColor = self.isEnabled ? UIColor.black.cgColor : UIColor.lightGray.cgColor
            if (mColor != color) {
                mColor = color
                self.layer.borderColor = mColor
                setNeedsDisplay()
            }
        }
    }
    
}
