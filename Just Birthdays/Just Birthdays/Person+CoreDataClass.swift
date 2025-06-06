import Foundation
import CoreData

@objc(Person)
public class Person: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "birthday")
        setPrimitiveValue("", forKey: "name")
    }
}
