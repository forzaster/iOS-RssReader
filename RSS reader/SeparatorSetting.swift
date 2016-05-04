//
//  SeparatorSetting.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/29.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

class SeparatorSetting {
    
    internal static func setTableView(tableView: UITableView) {
        if (tableView.respondsToSelector(Selector("separatorInset"))) {
            tableView.separatorInset = UIEdgeInsetsZero;
        }
        if (tableView.respondsToSelector(Selector("layoutMargins"))) {
            tableView.layoutMargins = UIEdgeInsetsZero;
        }
    }
    internal static func setCell(cell: UITableViewCell) {
        if (cell.respondsToSelector(Selector("separatorInset"))) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell.respondsToSelector(Selector("preservesSuperviewLayoutMargins"))) {
            cell.preservesSuperviewLayoutMargins = false;
        }
        if (cell.respondsToSelector(Selector("layoutMargins"))) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }
}