//
//  PArticleItemAdapter.swift
//  RSSreader
//
//  Created by n-naka on 2015/07/12.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import UIKit

protocol PArticleItemAdapter {
    func getCount(section: Int) -> Int
    
    func getItemHeight(tableView: UITableView, indexPath: NSIndexPath) -> CGFloat

    func getItemView(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell
    
    func didSelect(tableView: UITableView, indexPath: NSIndexPath) -> (String?, String?, String?)
    
    func update(callback: () -> Void)
}