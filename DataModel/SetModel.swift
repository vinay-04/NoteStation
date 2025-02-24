import SwiftData
import Foundation

@Model
final class SetModel {
    var name: String
    @Relationship(deleteRule: .nullify) var files: [FileModel]
    
    init(name: String) {
        self.name = name
        self.files = []
    }
}
