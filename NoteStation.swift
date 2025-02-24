import SwiftData
import SwiftUI

@main
struct NoteStation: App {
    let container: ModelContainer
    init() {
        do {
            container = try ModelContainer(for: FileModel.self, SetModel.self)
        } catch {
            fatalError("Failed to initialize ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
