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
    func getCount(_ section: Int) -> Int
    
    func getItemHeight(_ tableView: UITableView, indexPath: IndexPath) -> CGFloat

    func getItemView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell
    
    func didSelect(_ tableView: UITableView, indexPath: IndexPath) -> (String?, String?, String?)
    
    func update(_ callback: @escaping () -> Void)
}
