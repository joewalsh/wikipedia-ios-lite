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


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var key: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var groups: Group?

}
