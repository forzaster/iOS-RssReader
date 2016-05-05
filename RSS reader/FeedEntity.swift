//
//  FeedEntity.swift
//  RSS reader
//
//  Created by n-naka on 2015/05/16.
//  Copyright (c) 2015年 forzaster. All rights reserved.
//

import Foundation
import CoreData

class FeedEntity: NSManagedObject {

    @NSManaged var date_added: NSDate?
    @NSManaged var last_modified: String?
    @NSManaged var link: String
    @NSManaged var page_link: String
    @NSManaged var title: String
    @NSManaged var article: NSSet?

}
