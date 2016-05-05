//
//  ArticleEntity.swift
//  
//
//  Created by n-naka on 2015/07/12.
//
//

import Foundation
import CoreData

class ArticleEntity: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var detail: String?
    @NSManaged var link: String
    @NSManaged var media_mime: String?
    @NSManaged var media_url: String?
    @NSManaged var title: String
    @NSManaged var watched: NSNumber?
    @NSManaged var feed: NSSet?

}
