//
//  Loading.swift
//  RSSreader
//
//  Created by n-naka on 2015/08/08.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

public class Loading : UIView {
    
    init() {
        super.init(frame: CGRectZero)
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetShouldAntialias(context, true);
        
        let h = self.bounds.height
        let p: CGFloat = 8
        let rr = h - 2*p
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
        CGContextSetLineWidth(context, 1)
        let rect = CGRectMake(p, p, rr, rr)
        CGContextAddEllipseInRect(context,rect)
        CGContextStrokePath(context)

        CGContextMoveToPoint(context, p + rr/2, p)
        CGContextAddLineToPoint(context, p + rr/2 - rr/6, p + rr/4)
        CGContextStrokePath(context)
        
        CGContextMoveToPoint(context, p + rr/2, p + rr)
        CGContextAddLineToPoint(context, p + rr/2 + rr/6, p + rr - rr/4)
        CGContextStrokePath(context)
    }
}
