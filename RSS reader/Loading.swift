//
//  Loading.swift
//  RSSreader
//
//  Created by n-naka on 2015/08/08.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

open class Loading : UIView {
    fileprivate var mDisplayLink : CADisplayLink? = nil
    fileprivate var mEndAngle : CGFloat = CGFloat(-Double.pi/2.0)
    fileprivate var mDelta: CGFloat = CGFloat(-1)
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.setAllowsAntialiasing(true);
        context.setShouldAntialias(true);
        
        let h = self.bounds.height
        let p: CGFloat = 8
        let rr = h - 2*p
        let r = rr/2
        
        let center = CGPoint(x: p+r, y: p+r)
        context.setFillColor(UIColor.gray.cgColor)
        context.move(to: center)
        context.addArc(center: center, radius: r,
                       startAngle: CGFloat(-Double.pi/2.0), endAngle: mEndAngle,
                       clockwise: false)
        context.fillPath()
/*
        context?.setStrokeColor(UIColor.blue.cgColor)
        context?.setLineWidth(1)
        let rect = CGRect(x: p, y: p, width: rr, height: rr)
        context?.addEllipse(in: rect)
        context?.strokePath()
        

        context?.move(to: CGPoint(x: p + rr/2, y: p))
        context?.addLine(to: CGPoint(x: p + rr/2 - rr/6, y: p + rr/4))
        context?.strokePath()
        
        context?.move(to: CGPoint(x: p + rr/2, y: p + rr))
        context?.addLine(to: CGPoint(x: p + rr/2 + rr/6, y: p + rr - rr/4))
        context?.strokePath()
*/
    }
    
    func startAnim() {
        mDisplayLink = CADisplayLink(target: self, selector: #selector(update))
        mDisplayLink?.add(to: .current, forMode: .defaultRunLoopMode)
        mEndAngle = CGFloat(-Double.pi/2.0)
        setNeedsDisplay()
    }
    
    func update(displaylink: CADisplayLink) {
        if (mDelta <= 0) {
            let TIME = 3.0
            let d = TIME / (mDisplayLink?.duration)!
            mDelta = CGFloat(Double.pi * 2.0 / d)
        }
        mEndAngle += mDelta
        if (mEndAngle > CGFloat(Double.pi*3.0/2.0)) {
            mEndAngle = CGFloat(-Double.pi/2.0)
        }
        setNeedsDisplay()
    }
    
    func stopAnim() {
        mEndAngle = CGFloat(-Double.pi/2.0)
        mDisplayLink?.invalidate()
    }
}
