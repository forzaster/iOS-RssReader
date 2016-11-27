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
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true);
        context?.setShouldAntialias(true);
        
        let h = self.bounds.height
        let p: CGFloat = 8
        let rr = h - 2*p
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
    }
}
