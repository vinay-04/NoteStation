import Foundation
import SwiftData

@Model
final class FileModel {
    @Attribute(.unique) let id: UUID
    var name: String
    let url: String
    var isLiked: Bool
    @Relationship(inverse: \SetModel.files) var sets: [SetModel]
    
    init(name: String, url: String, isLiked: Bool = false) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.isLiked = isLiked
        self.sets = []
    }
}
