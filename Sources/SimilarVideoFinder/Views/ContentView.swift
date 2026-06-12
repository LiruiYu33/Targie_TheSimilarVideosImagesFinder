import SwiftUI

struct ContentView: View {
    @StateObject private var model = ScanViewModel()
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.defaultLanguage.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .defaultLanguage
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            GroupDetailView(model: model)
                .navigationSplitViewColumnWidth(min: 440, ideal: 590)
        } detail: {
            InspectorView(model: model)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 390)
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { model.chooseFolder(language: language) }) {
                    Label(L10n.chooseFolder(language), systemImage: "folder.badge.plus")
                }
                Button(action: model.startScan) {
                    Label(L10n.startScan(language), systemImage: "sparkle.magnifyingglass")
                }
                .disabled(model.selectedFolder == nil || model.isScanning)
                Menu {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            languageRawValue = option.rawValue
                        } label: {
                            if option == language {
                                Label(option.menuLabel, systemImage: "checkmark")
                            } else {
                                Text(option.menuLabel)
                            }
                        }
                    }
                } label: {
                    Label(L10n.language(language), systemImage: "globe")
                }
            }
        }
        .sheet(item: $model.deletePrompt) { _ in
            DeleteConfirmationView(model: model)
        }
        .alert(L10n.operationFailed(language), isPresented: Binding(
            get: { model.presentedError != nil },
            set: { if !$0 { model.presentedError = nil } }
        )) {
            Button(L10n.ok(language)) { model.presentedError = nil }
        } message: {
            Text(model.localizedError(language) ?? L10n.unknownError(language))
        }
        .onDeleteCommand {
            if let video = model.selectedVideo { model.requestDeletion(of: video) }
        }
        .environment(\.appLanguage, language)
        .background(WindowTitleUpdater(title: L10n.appName(language)))
    }
}

private struct WindowTitleUpdater: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { view.window?.title = title }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { view.window?.title = title }
    }
}
