//
//  Log.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/16.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation

class Log {
    static let mDebug = false
    
    static func d(_ message: String) {
        if (mDebug) {
            print(message)
        }
    }
}
