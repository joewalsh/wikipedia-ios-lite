//
//  Group+CoreDataProperties.swift
//  lite
//
//  Created by Natalia Harateh on 2/22/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//
//

import Foundation
import CoreData


extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    @NSManaged public var items: Item?

}
