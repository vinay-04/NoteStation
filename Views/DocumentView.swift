import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct DocumentViewer: View {
    let url: String
    @State private var document: PDFDocument?
    @State private var isLoading = true
    @State private var pdfView: PDFView?
    @State private var isVisible = false
    @State var detector: HandGestureDetector? = nil
    @State private var scrollDirection: Int = 0

    var body: some View {
        VStack {
            Group {
                if let document = document {
                    DocumentKitView(
                        document: document,
                        onViewCreated: { view in
                            self.pdfView = view
                        })
                    HStack {
                        PlaybackControls(pdfView: pdfView, scrollDirection: $scrollDirection)
                            .font(.headline)
                            .foregroundColor(.purple)
                        Button(action: {
                            isVisible.toggle()
                            if isVisible {
                                detector = HandGestureDetector()
                                detector?.startDetection { gesture in
                                    //                                    print("\(gesture)")
                                    self.scrollDirection = gesture
                                }
                            } else {
                                detector?.stopDetection()
                                detector = nil
                                self.scrollDirection = 0
                            }
                        }) {
                            Image(systemName: isVisible ? "eye" : "eye.slash")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        Button(action: {
                            let alert = UIAlertController(
                                title: "Information",
                                message:
                                    "Use the play button to auto-scroll or enable hand gestures with the eye button. Show plam to scroll-down or fist to scroll-up",
                                preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            let windowScene =
                                UIApplication.shared.connectedScenes.first as? UIWindowScene
                            let window = windowScene?.windows.first?.rootViewController
                            window?.present(alert, animated: true)
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.purple)
                        }
                        .padding()
                    }
                } else if isLoading {
                    ProgressView("Loading PDF...")
                } else {
                    Text("Failed to load PDF")
                        .foregroundColor(.red)
                }
            }
        }
        .task {
            isLoading = true
            if let url = URL(string: url) {
                document = await loadPDF(from: url)
            }
            isLoading = false
        }
    }

    private func loadPDF(from url: URL) async -> PDFDocument? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let document = PDFDocument(url: url)
                DispatchQueue.main.async {
                    continuation.resume(returning: document)
                }
            }
        }
    }

}

struct PlaybackControls: View {
    let pdfView: PDFView?
    @State private var isPlaying = false
    @State private var scrollSpeed: Double = 1.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @Binding var scrollDirection: Int

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }

                Slider(value: $scrollSpeed, in: 0.1...5.0)
                    .frame(width: 200)
                Text("Speed: \(scrollSpeed, specifier: "%.1f")x")
            }
            .padding()
        }
        .onReceive(timer) { _ in
            if let pdfView = pdfView,
                let scrollView = pdfView.subviews.first as? UIScrollView
            {
                let currentPoint = scrollView.contentOffset
                if isPlaying {
                    scrollView.setContentOffset(
                        CGPoint(
                            x: currentPoint.x,
                            y: currentPoint.y + scrollSpeed), animated: false)
                } else if scrollDirection != 0 {
                    let scrollAmount = scrollDirection * Int(scrollSpeed * 5)
                    scrollView.setContentOffset(
                        CGPoint(
                            x: currentPoint.x,
                            y: currentPoint.y + CGFloat(scrollAmount)), animated: false)
                }
            }
        }
    }
}

extension UIView {
    fileprivate func recursiveSubviews() -> [UIView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews() }
    }
}

struct DocumentKitView: UIViewRepresentable {
    let document: PDFDocument
    let onViewCreated: (PDFView) -> Void

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        onViewCreated(pdfView)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])  // TODO: Support more file formats
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController, context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
            print("Coordinator initialized")
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else {
                print("No URL selected")
                return
            }

            if url.startAccessingSecurityScopedResource() {
                print("Successfully accessed URL: \(url)")
                parent.onPick(url)
                url.stopAccessingSecurityScopedResource()
            } else {
                print("Failed to access URL: \(url)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Picker cancelled")
        }
    }
}
