import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var appGroupIdentifier: String {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            fatalError("AppGroupIdentifier not found in Info.plist")
        }
        return identifier
    }
    static var cloudKitContainerIdentifier: String {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String else {
            fatalError("CloudKitContainerIdentifier not found in Info.plist")
        }
        return identifier
    }

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Just_Birthdays")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)?.appendingPathComponent("Just_Birthdays.sqlite") else {
                fatalError("Failed to find shared container URL.")
            }
            
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerIdentifier)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
