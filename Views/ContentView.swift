import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = DataStore()
    @Environment(\.modelContext) private var modelContext
    @Query private var allFiles: [FileModel]
    @Query private var allSets: [SetModel]
    @State private var selectedDataItem: FileModel?
    @State private var selectedSetForAction: SetModel?
    @State private var ListType = 0
    @State private var showingDocumentPicker = false
    @State private var showingSetCreation = false
    @State private var newSetName = ""
    @State private var selectedFileForAction: FileModel?
    @State private var searchText = ""
    @State private var showingRenameDialog = false
    @State private var newFileName = ""

    var body: some View {
        NavigationSplitView {
            VStack {
                Picker("View Type", selection: $ListType) {
                    Text("All").tag(0)
                    Text("Sets").tag(1)
                    Text("Liked").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch ListType {
                case 0:
                    List(
                        allFiles.filter {
                            searchText.isEmpty
                                ? true : $0.name.localizedCaseInsensitiveContains(searchText)
                        }
                    ) { item in
                        FileRowView(file: item) {
                            selectedDataItem = nil
                            DispatchQueue.main.async {
                                selectedDataItem = item
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                dataStore.toggleLike(for: item)
                            }) {
                                Label(
                                    item.isLiked ? "Unlike" : "Like",
                                    systemImage: item.isLiked ? "heart.fill" : "heart")
                            }

                            Button(action: {
                                selectedFileForAction = item
                                showingSetCreation = true
                            }) {
                                Label("Add to Set", systemImage: "folder.badge.plus")
                            }

                            Button(action: {
                                selectedFileForAction = item
                                showingRenameDialog = true
                                newFileName = item.name
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button(action: {
                                dataStore.removeFile(item)
                                selectedDataItem = nil
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .alert("Rename)", isPresented: $showingRenameDialog) {
                        TextField("New name", text: $newFileName)
                        Button("OK") {
                            if !newFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            {
                                if let file = selectedFileForAction {
                                    dataStore.renameFile(file, to: newFileName)
                                }
                                newFileName = ""
                            }
                        }
                        .disabled(
                            newFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button("Cancel", role: .cancel) {}
                    }
                     .searchable(text: $searchText)
                    .simultaneousGesture(
                        DragGesture().onChanged({ _ in
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                                for: nil)
                        }))

                case 1:
                    List(
                        allSets.filter {
                            searchText.isEmpty
                                ? true : $0.name.localizedCaseInsensitiveContains(searchText)
                        }
                    ) { set in
                        DisclosureGroup(set.name) {
                            ForEach(set.files) { item in
                                FileRowView(file: item) {
                                    selectedDataItem = nil
                                    DispatchQueue.main.async {
                                        selectedDataItem = item
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        dataStore.toggleLike(for: item)
                                    }) {
                                        Label(
                                            item.isLiked ? "Unlike" : "Like",
                                            systemImage: item.isLiked ? "heart.fill" : "heart")
                                    }

                                    Button(action: {
                                        selectedFileForAction = item
                                        showingSetCreation = true
                                    }) {
                                        Label("Add to Set", systemImage: "folder.badge.plus")
                                    }

                                    Button(action: {
                                        selectedFileForAction = item
                                        showingRenameDialog = true
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }

                                    Button(action: {
                                        dataStore.deleteFileFromSet(item, in: set)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation {
                                    dataStore.removeSet(set)

                                    selectedDataItem = nil
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                            Button(action: {
                                selectedSetForAction = set
                                newFileName = set.name
                                showingRenameDialog = true
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .alert("Rename", isPresented: $showingRenameDialog) {
                        TextField("New name", text: $newFileName)
                        Button("OK") {
                            if !newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            {
                                if let set = selectedSetForAction {

                                    dataStore.renameSet(set, to: newFileName)
                                    selectedSetForAction = nil
                                } else if let file = selectedFileForAction {

                                    dataStore.renameFile(file, to: newFileName)
                                    selectedFileForAction = nil
                                }
                                newFileName = ""
                            }
                        }
                        .disabled(
                            newFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button("Cancel", role: .cancel) {
                            selectedSetForAction = nil
                            selectedFileForAction = nil
                        }
                    } message: {
                        if selectedSetForAction != nil {
                            Text("Rename Set")
                        } else if selectedFileForAction != nil {
                            Text("Rename File")
                        }
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged({ _ in
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                                for: nil)
                        }))
                case 2:
                    List(allFiles.filter { $0.isLiked }) { item in
                        FileRowView(file: item) {
                            selectedDataItem = nil
                            DispatchQueue.main.async {
                                selectedDataItem = item
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                dataStore.toggleLike(for: item)
                            }) {
                                Label(
                                    item.isLiked ? "Unlike" : "Like",
                                    systemImage: item.isLiked ? "heart.fill" : "heart")
                            }
                            Button(action: {
                                selectedFileForAction = item
                                showingSetCreation = true
                            }) {
                                Label("Add to Set", systemImage: "folder.badge.plus")
                            }
                        }
                    }

                default:
                    EmptyView()
                }
                Button(action: { showingDocumentPicker = true }) {
                    Text("Upload PDF")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                }
                .padding()
            }
            .navigationTitle("NoteStation")
        } detail: {
            if let selectedItem = selectedDataItem {
                DocumentViewer(url: selectedItem.url)
                    .navigationTitle(selectedItem.name)
            } else {
                Text("Select a PDF")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                if let url = url {
                    addPDF(url: url)
                }
            }
        }
        .sheet(isPresented: $showingSetCreation) {
            AddToSetView(setName: $newSetName) { setName in
                if let file = selectedFileForAction {
                    dataStore.addToSet(file, setName: setName)
                }
                selectedFileForAction = nil
            }
        }
    }

    private func addPDF(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }

        dataStore.addFile(name: url.lastPathComponent, url: url.absoluteString)
        url.stopAccessingSecurityScopedResource()
    }
}

struct FileRowView: View {
    let file: FileModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(file.name)
                if file.isLiked {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                Spacer()
            }
        }
        .foregroundColor(.primary)
    }
}

struct AddToSetView: View {
    @StateObject private var dataStore = DataStore()
    @Binding var setName: String
    let onAdd: (String) -> Void
    @Query private var allSets: [SetModel]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Create new set")) {
                    HStack {
                        TextField("New set name", text: $setName)
                        Button("Add") {
                            onAdd(setName)
                            setName = ""
                            dismiss()
                        }
                        .disabled(setName.isEmpty)
                    }
                }
                Section(header: Text("Existing sets")) {
                    ForEach(allSets) { set in
                        Button(action: {
                            onAdd(set.name)
                            dismiss()
                        }) {
                            Text(set.name)
                        }
                    }
                }
            }
            .navigationTitle("Add to Set")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}
