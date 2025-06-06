//
//  Person+CoreDataProperties.swift
//  Just Birthdays
//
//  Created by Colin Wright on 6/5/25.
//
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var birthday: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var socialMediaURL: String?
    @NSManaged public var yearIsKnown: Bool
    @NSManaged public var emailAddress: String?

}

extension Person : Identifiable {

}
