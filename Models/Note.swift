import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    
}

extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }
    
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var id: UUID?
    
    public var wrappedContent: String {
        content ?? ""
    }
    
    public var wrappedCreatedAt: Date {
        createdAt ?? Date()
    }
    
    public var wrappedModifiedAt: Date {
        modifiedAt ?? Date()
    }
    
    public var wrappedId: UUID {
        id ?? UUID()
    }
}

extension Note : Identifiable {

}