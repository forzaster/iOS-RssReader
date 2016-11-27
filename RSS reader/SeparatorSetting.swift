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
    
    internal static func setTableView(_ tableView: UITableView) {
        if (tableView.responds(to: #selector(getter: UITableViewCell.separatorInset))) {
            tableView.separatorInset = UIEdgeInsets.zero;
        }
        if (tableView.responds(to: #selector(getter: UIView.layoutMargins))) {
            tableView.layoutMargins = UIEdgeInsets.zero;
        }
    }
    internal static func setCell(_ cell: UITableViewCell) {
        if (cell.responds(to: #selector(getter: UITableViewCell.separatorInset))) {
            cell.separatorInset = UIEdgeInsets.zero;
        }
        if (cell.responds(to: #selector(getter: UIView.preservesSuperviewLayoutMargins))) {
            cell.preservesSuperviewLayoutMargins = false;
        }
        if (cell.responds(to: #selector(getter: UIView.layoutMargins))) {
            cell.layoutMargins = UIEdgeInsets.zero;
        }
    }
}
