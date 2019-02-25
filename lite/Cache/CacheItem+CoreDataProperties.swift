//
//  Item+CoreDataProperties.swift
//  lite
//
//  Created by Natalia Harateh on 2/22/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//
//

import Foundation
import CoreData


extension CacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheItem> {
        return NSFetchRequest<CacheItem>(entityName: "CacheItem")
    }

    @NSManaged public var key: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var cacheGroups: CacheGroup?

}
