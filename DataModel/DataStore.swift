import SwiftData
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    @Published private var filesCount: Int = 0

    init() {
        let schema = Schema([FileModel.self, SetModel.self])
        do {
            modelContainer = try ModelContainer(for: schema)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }

    func getAllFiles() -> [FileModel] {
        let descriptor = FetchDescriptor<FileModel>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getAllSets() -> [SetModel] {
        let descriptor = FetchDescriptor<SetModel>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addToSet(_ file: FileModel, setName: String) {
        let setDescriptor = FetchDescriptor<SetModel>(
            predicate: #Predicate<SetModel> { $0.name == setName }
        )

        do {
            if let existingSet = try modelContext.fetch(setDescriptor).first {
                existingSet.files.append(file)
                file.sets.append(existingSet)
            } else {
                let newSet = SetModel(name: setName)
                newSet.files.append(file)
                file.sets.append(newSet)
                modelContext.insert(newSet)
            }
            try modelContext.save()
        } catch {
            print("Failed to add to set: \(error)")
        }
    }

    func toggleLike(for file: FileModel) {
        file.isLiked.toggle()
        try? modelContext.save()
    }

    func removeFile(_ file: FileModel) {
        for set in file.sets {
            set.files.removeAll { $0.id == file.id }
        }

        modelContext.delete(file)

        do {
            try modelContext.save()
            filesCount -= 1
        } catch {
            print("Failed to delete file from database: \(error)")
        }
    }

    func removeSet(_ set: SetModel) {
        for file in set.files {
            file.sets.removeAll { $0.id == set.id }
        }
        modelContext.delete(set)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete set: \(error)")
        }
    }

    func renameSet(_ set: SetModel, to newName: String) {
        set.name = newName
        try? modelContext.save()
    }

    func renameFile(_ file: FileModel, to newName: String) {
        file.name = newName
        try? modelContext.save()
    }

    func deleteFileFromSet(_ file: FileModel, in set: SetModel) {
        set.files.removeAll { $0.id == file.id }
        file.sets.removeAll { $0.id == set.id }
        try? modelContext.save()
    }

    func addFile(name: String, url: String) {
        let file = FileModel(name: name, url: url)
        modelContext.insert(file)
        try? modelContext.save()
        filesCount += 1
    }
}
