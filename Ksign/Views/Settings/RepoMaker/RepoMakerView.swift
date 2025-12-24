//
//  RepoMakerView.swift
//  Ksign
//
//  Custom Repository Maker for generating AltStore-compatible JSON
//

import SwiftUI
import NimbleViews
import NimbleJSON
import AltSourceKit
import UniformTypeIdentifiers
import ZIPFoundation

// MARK: - App Entry for Repo
struct RepoAppEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var version: String
    var versionDescription: String
    var downloadURL: String
    var iconURL: String
    var size: Int
    var developerName: String
    var localizedDescription: String
    var subtitle: String
    var screenshotURLs: [String]
    var tintColor: String
    
    init(id: UUID = UUID(), name: String = "", bundleIdentifier: String = "", version: String = "1.0", versionDescription: String = "", downloadURL: String = "", iconURL: String = "", size: Int = 0, developerName: String = "", localizedDescription: String = "", subtitle: String = "", screenshotURLs: [String] = [], tintColor: String = "#4A90D9") {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.versionDescription = versionDescription
        self.downloadURL = downloadURL
        self.iconURL = iconURL
        self.size = size
        self.developerName = developerName
        self.localizedDescription = localizedDescription
        self.subtitle = subtitle
        self.screenshotURLs = screenshotURLs
        self.tintColor = tintColor
    }
}

// MARK: - View
struct RepoMakerView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Repository Info
    @State private var repoName: String = ""
    @State private var repoIdentifier: String = ""
    @State private var repoSubtitle: String = ""
    @State private var repoDescription: String = ""
    @State private var repoIconURL: String = ""
    @State private var repoWebsite: String = ""
    @State private var repoTintColor: String = "#4A90D9"
    
    // Apps
    @State private var apps: [RepoAppEntry] = []
    @State private var showAddAppSheet = false
    @State private var editingApp: RepoAppEntry? = nil
    
    // Export
    @State private var showExportSheet = false
    @State private var generatedJSON: String = ""
    @State private var showCopiedAlert = false
    
    // Import
    @State private var showImportPicker = false
    @State private var showIPAPicker = false
    @State private var extractedApp: RepoAppEntry? = nil
    
    // Saved Repos
    @State private var savedRepos: [URL] = []
    @State private var showSavedRepos = false
    
    // Import IPA from Library
    @State private var showLibraryIPAPicker = false
    
    // MARK: - Repos Folder Helper
    private static var reposFolderURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let reposFolder = documentsPath.appendingPathComponent("JSON Repos", isDirectory: true)
        
        // Create folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: reposFolder.path) {
            do {
                try FileManager.default.createDirectory(at: reposFolder, withIntermediateDirectories: true, attributes: nil)
                print("[RepoMaker] Created JSON Repos folder at: \(reposFolder.path)")
            } catch {
                print("[RepoMaker] Failed to create JSON Repos folder: \(error)")
            }
        }
        
        return reposFolder
    }
    
    var body: some View {
        NBNavigationView(.localized("Repo Maker"), displayMode: .inline) {
            Form {
                // Header Section
                Section {
                    _repoHeaderPreview()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Repository Info
                NBSection(.localized("Repository Info")) {
                    _iconTextField(
                        icon: "tag.fill",
                        iconColor: .blue,
                        placeholder: .localized("Repository Name"),
                        text: $repoName
                    )
                    
                    _iconTextField(
                        icon: "textformat",
                        iconColor: .purple,
                        placeholder: .localized("Identifier (e.g., com.example.repo)"),
                        text: $repoIdentifier
                    )
                    
                    _iconTextField(
                        icon: "text.quote",
                        iconColor: .orange,
                        placeholder: .localized("Subtitle"),
                        text: $repoSubtitle
                    )
                    
                    _iconTextField(
                        icon: "doc.text",
                        iconColor: .green,
                        placeholder: .localized("Description"),
                        text: $repoDescription
                    )
                    
                    _iconTextField(
                        icon: "photo",
                        iconColor: .pink,
                        placeholder: .localized("Icon URL"),
                        text: $repoIconURL
                    )
                    .keyboardType(.URL)
                    
                    _iconTextField(
                        icon: "globe",
                        iconColor: .cyan,
                        placeholder: .localized("Website URL"),
                        text: $repoWebsite
                    )
                    .keyboardType(.URL)
                }
                
                // Apps Section
                NBSection(.localized("Apps (\(apps.count))")) {
                    ForEach(apps) { app in
                        _appRow(app: app)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingApp = app
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        apps.removeAll { $0.id == app.id }
                                    }
                                } label: {
                                    Label(.localized("Delete"), systemImage: "trash")
                                }
                            }
                    }
                    
                    // Add from IPA
                    Button {
                        showIPAPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "doc.zipper")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Add from IPA"))
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.medium)
                                Text(.localized("Pick IPA to extract info"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Add IPA from Library - with plus sign pattern like LibraryView
                    Button {
                        showLibraryIPAPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Import IPA from Library"))
                                    .foregroundColor(.purple)
                                    .fontWeight(.medium)
                                Text(.localized("Select IPA files from device"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Add manually
                    Button {
                        showAddAppSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "pencil")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(.localized("Add Manually"))
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                    }
                }
                
                // Quick Add IPA Links
                NBSection(.localized("Quick Add IPA Links")) {
                    Button {
                        _addQuickIPALinks()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "link.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Add IPA Links from Clipboard"))
                                    .foregroundColor(.primary)
                                Text(.localized("Paste multiple IPA URLs, one per line"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Actions
                NBSection(.localized("Actions")) {
                    // Generate JSON
                    Button {
                        _generateJSON()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: "doc.badge.gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Text(.localized("Generate Repository JSON"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(repoName.isEmpty || apps.isEmpty)
                    
                    // Create Repository
                    Button {
                        _exportJSONToFile()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Text(.localized("Create Repository"))
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                    }
                    .disabled(repoName.isEmpty || apps.isEmpty)
                    
                    // Import JSON
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                            
                            Text(.localized("Import Existing Repository"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    // Add to Sources - takes the last saved repo and adds it as a source
                    Button {
                        _addCreatedRepoToSources()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Add to Sources"))
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                Text(.localized("Add this repo to your Sources list"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .disabled(savedRepos.isEmpty)
                    
                    // Clear All
                    Button(role: .destructive) {
                        _clearAll()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            
                            Text(.localized("Clear All"))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                    }
                }
                
                // Saved Repos Section
                if !savedRepos.isEmpty {
                    NBSection(.localized("Saved Repos (\(savedRepos.count))")) {
                        ForEach(savedRepos, id: \.absoluteString) { repoURL in
                            Button {
                                _loadRepoFromFile(repoURL)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.accentColor.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "doc.text.fill")
                                            .font(.title2)
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(repoURL.deletingPathExtension().lastPathComponent)
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                        Text(repoURL.lastPathComponent)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    _deleteRepoFile(repoURL)
                                } label: {
                                    Label(.localized("Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Save repo before dismissing if there's content
                        if !repoName.isEmpty && !apps.isEmpty {
                            _saveRepo()
                        }
                        dismiss()
                    } label: {
                        Text(.localized("Done"))
                    }
                }
            }
        }
        .sheet(isPresented: $showAddAppSheet) {
            RepoAppEditorView(app: nil) { newApp in
                apps.append(newApp)
            }
        }
        .sheet(item: $editingApp) { app in
            RepoAppEditorView(app: app) { updatedApp in
                if let index = apps.firstIndex(where: { $0.id == app.id }) {
                    apps[index] = updatedApp
                }
            }
        }
        .sheet(item: $extractedApp) { app in
            RepoAppEditorView(app: app) { updatedApp in
                apps.append(updatedApp)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            RepoExportView(json: generatedJSON, repoName: repoName)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [
                .json,
                UTType(filenameExtension: "json")!,
                .data,
                .text,
                .plainText,
                UTType(mimeType: "application/json") ?? .json
            ],
            allowsMultipleSelection: false
        ) { result in
            _handleImport(result)
        }
        .fileImporter(
            isPresented: $showIPAPicker,
            allowedContentTypes: [
                .ipa,
                .tipa,
                UTType(filenameExtension: "ipa")!,
                .data,
                .archive,
                .zip
            ],
            allowsMultipleSelection: false
        ) { result in
            _handleIPAImport(result)
        }
        .sheet(isPresented: $showLibraryIPAPicker) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                allowsMultipleSelection: true,
                onDocumentsPicked: { urls in
                    guard !urls.isEmpty else { return }
                    for url in urls {
                        _handleIPAImportFromLibrary(url)
                    }
                }
            )
        }
        .onAppear {
            _loadSavedRepos()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func _repoHeaderPreview() -> some View {
        VStack(spacing: 16) {
            // Icon Preview
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                if repoIconURL.isEmpty {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                } else {
                    AsyncImage(url: URL(string: repoIconURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            
            // Repo Name
            Text(repoName.isEmpty ? .localized("Repository Name") : repoName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(repoName.isEmpty ? .secondary : .primary)
            
            // Subtitle
            if !repoSubtitle.isEmpty {
                Text(repoSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            HStack(spacing: 20) {
                _statBadge(icon: "app.fill", value: "\(apps.count)", label: .localized("Apps"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func _statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(.accentColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func _iconTextField(icon: String, iconColor: Color, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }
            
            TextField(placeholder, text: text)
        }
    }
    
    @ViewBuilder
    private func _appRow(app: RepoAppEntry) -> some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if !app.iconURL.isEmpty {
                    AsyncImage(url: URL(string: app.iconURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "app.fill")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "app.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name.isEmpty ? .localized("Untitled App") : app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(app.bundleIdentifier.isEmpty ? "com.example.app" : app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !app.downloadURL.isEmpty {
                    Text("v\(app.version)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            // Edit Button (pen icon)
            Button {
                editingApp = app
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func _addQuickIPALinks() {
        guard let clipboardContent = UIPasteboard.general.string else {
            UIAlertController.showAlertWithOk(
                title: .localized("No Content"),
                message: .localized("Clipboard is empty. Copy IPA URLs first.")
            )
            return
        }
        
        let urls = clipboardContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasPrefix("http") }
        
        if urls.isEmpty {
            UIAlertController.showAlertWithOk(
                title: .localized("No URLs Found"),
                message: .localized("No valid IPA URLs found in clipboard.")
            )
            return
        }
        
        for url in urls {
            let fileName = URL(string: url)?.lastPathComponent ?? "app.ipa"
            let appName = fileName.replacingOccurrences(of: ".ipa", with: "")
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            
            let newApp = RepoAppEntry(
                name: appName,
                bundleIdentifier: "com.example.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))",
                version: "1.0",
                downloadURL: url
            )
            apps.append(newApp)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func _generateJSON() {
        let json = _createRepositoryJSON()
        generatedJSON = json
        showExportSheet = true
    }
    
    private func _saveRepo() {
        guard !repoName.isEmpty else {
            UIAlertController.showAlertWithOk(
                title: .localized("Save Failed"),
                message: .localized("Please enter a repository name before saving.")
            )
            return
        }
        
        let json = _createRepositoryJSON()
        
        // Sanitize filename
        let safeName = repoName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        let fileName = "\(safeName).json"
        
        // Ensure the JSON Repos folder exists
        let reposFolder = Self.reposFolderURL
        if !FileManager.default.fileExists(atPath: reposFolder.path) {
            do {
                try FileManager.default.createDirectory(at: reposFolder, withIntermediateDirectories: true, attributes: nil)
                print("[RepoMaker] Created JSON Repos folder at: \(reposFolder.path)")
            } catch {
                print("[RepoMaker] Failed to create folder: \(error)")
                UIAlertController.showAlertWithOk(
                    title: .localized("Save Failed"),
                    message: .localized("Could not create the JSON Repos folder: \(error.localizedDescription)")
                )
                return
            }
        }
        
        // Save to JSON Repos folder
        let fileURL = reposFolder.appendingPathComponent(fileName)
        
        do {
            try json.write(to: fileURL, atomically: true, encoding: .utf8)
            _loadSavedRepos()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            print("[RepoMaker] Saved repo to: \(fileURL.path)")
        } catch {
            print("[RepoMaker] Save error: \(error)")
            UIAlertController.showAlertWithOk(
                title: .localized("Save Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func _exportJSONToFile() {
        let json = _createRepositoryJSON()
        let fileName = "\(repoName.isEmpty ? "Repository" : repoName.replacingOccurrences(of: " ", with: "_")).json"
        
        // Save to JSON Repos folder
        let fileURL = Self.reposFolderURL.appendingPathComponent(fileName)
        
        do {
            try json.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Refresh saved repos list
            _loadSavedRepos()
            
            // Present share sheet
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else { return }
                
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Export Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func _createRepositoryJSON() -> String {
        var repoDict: [String: Any] = [
            "name": repoName,
            "identifier": repoIdentifier.isEmpty ? "com.custom.\(repoName.lowercased().replacingOccurrences(of: " ", with: ""))" : repoIdentifier,
            "subtitle": repoSubtitle,
            "description": repoDescription,
            "iconURL": repoIconURL,
            "website": repoWebsite,
            "tintColor": repoTintColor
        ]
        
        var appsArray: [[String: Any]] = []
        for app in apps {
            let appDict: [String: Any] = [
                "name": app.name,
                "bundleIdentifier": app.bundleIdentifier,
                "developerName": app.developerName.isEmpty ? "Unknown Developer" : app.developerName,
                "subtitle": app.subtitle,
                "localizedDescription": app.localizedDescription,
                "iconURL": app.iconURL,
                "tintColor": app.tintColor,
                "screenshotURLs": app.screenshotURLs,
                "versions": [[
                    "version": app.version,
                    "date": ISO8601DateFormatter().string(from: Date()),
                    "localizedDescription": app.versionDescription,
                    "downloadURL": app.downloadURL,
                    "size": app.size
                ]]
            ]
            appsArray.append(appDict)
        }
        
        repoDict["apps"] = appsArray
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: repoDict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func _clearAll() {
        repoName = ""
        repoIdentifier = ""
        repoSubtitle = ""
        repoDescription = ""
        repoIconURL = ""
        repoWebsite = ""
        apps = []
    }
    
    private func _handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "RepoMaker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                // Parse repository info
                repoName = json["name"] as? String ?? ""
                repoIdentifier = json["identifier"] as? String ?? ""
                repoSubtitle = json["subtitle"] as? String ?? ""
                repoDescription = json["description"] as? String ?? ""
                repoIconURL = json["iconURL"] as? String ?? ""
                repoWebsite = json["website"] as? String ?? ""
                repoTintColor = json["tintColor"] as? String ?? "#4A90D9"
                
                // Parse apps
                if let appsArray = json["apps"] as? [[String: Any]] {
                    apps = appsArray.compactMap { appDict in
                        let versions = appDict["versions"] as? [[String: Any]] ?? []
                        let latestVersion = versions.first
                        
                        return RepoAppEntry(
                            name: appDict["name"] as? String ?? "",
                            bundleIdentifier: appDict["bundleIdentifier"] as? String ?? "",
                            version: latestVersion?["version"] as? String ?? "1.0",
                            versionDescription: latestVersion?["localizedDescription"] as? String ?? "",
                            downloadURL: latestVersion?["downloadURL"] as? String ?? "",
                            iconURL: appDict["iconURL"] as? String ?? "",
                            size: latestVersion?["size"] as? Int ?? 0,
                            developerName: appDict["developerName"] as? String ?? "",
                            localizedDescription: appDict["localizedDescription"] as? String ?? "",
                            subtitle: appDict["subtitle"] as? String ?? "",
                            screenshotURLs: appDict["screenshotURLs"] as? [String] ?? [],
                            tintColor: appDict["tintColor"] as? String ?? "#4A90D9"
                        )
                    }
                }
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIAlertController.showAlertWithOk(
                    title: .localized("Import Successful"),
                    message: .localized("Imported repository '\(repoName)' with \(apps.count) apps.")
                )
                
            } catch {
                UIAlertController.showAlertWithOk(
                    title: .localized("Import Failed"),
                    message: error.localizedDescription
                )
            }
            
        case .failure(let error):
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func _handleIPAImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                UIAlertController.showAlertWithOk(
                    title: .localized("Import Failed"),
                    message: .localized("Could not access the selected file.")
                )
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Extract info from IPA
            let fileName = url.deletingPathExtension().lastPathComponent
            var appName = fileName
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            
            // Get file size
            var fileSize: Int = 0
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int {
                fileSize = size
            }
            
            // Try to extract bundle ID and other info from IPA
            var bundleId = "com.example.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))"
            var extractedVersion = "1.0"
            var developerName = ""
            
            // Use ZIPFoundation to peek into IPA if available
            if let archive = try? ZIPFoundation.Archive(url: url, accessMode: .read) {
                for entry in archive {
                    if entry.path.contains(".app/Info.plist") {
                        var plistData = Data()
                        _ = try? archive.extract(entry) { data in
                            plistData.append(data)
                        }
                        if let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                            if let cfBundleId = plist["CFBundleIdentifier"] as? String {
                                bundleId = cfBundleId
                            }
                            if let version = plist["CFBundleShortVersionString"] as? String {
                                extractedVersion = version
                            }
                            if let displayName = plist["CFBundleDisplayName"] as? String {
                                appName = displayName
                            } else if let bundleName = plist["CFBundleName"] as? String {
                                appName = bundleName
                            }
                            if let developer = plist["CFBundleGetInfoString"] as? String {
                                developerName = developer
                            }
                        }
                        break
                    }
                }
            }
            
            // Create app entry with extracted info
            let newApp = RepoAppEntry(
                name: appName,
                bundleIdentifier: bundleId,
                version: extractedVersion,
                downloadURL: "", // User needs to provide this
                size: fileSize,
                developerName: developerName
            )
            
            // Open editor to let user edit/complete the info
            extractedApp = newApp
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        case .failure(let error):
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func _handleIPAImportFromLibrary(_ url: URL) {
        // Access security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        // Extract info from IPA
        let fileName = url.deletingPathExtension().lastPathComponent
        let appName = fileName
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        
        // Get file size
        var fileSize: Int = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            fileSize = size
        }
        
        // Try to extract bundle ID from IPA (basic extraction)
        var bundleId = "com.example.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))"
        var extractedVersion = "1.0"
        var developerName = ""
        
        // Use ZIPFoundation to peek into IPA if available
        if let archive = try? ZIPFoundation.Archive(url: url, accessMode: .read) {
            for entry in archive {
                if entry.path.contains(".app/Info.plist") {
                    var plistData = Data()
                    _ = try? archive.extract(entry) { data in
                        plistData.append(data)
                    }
                    if let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                        if let cfBundleId = plist["CFBundleIdentifier"] as? String {
                            bundleId = cfBundleId
                        }
                        if let version = plist["CFBundleShortVersionString"] as? String {
                            extractedVersion = version
                        }
                        if let developer = plist["CFBundleGetInfoString"] as? String {
                            developerName = developer
                        }
                    }
                    break
                }
            }
        }
        
        // Create app entry with extracted info
        let newApp = RepoAppEntry(
            name: appName,
            bundleIdentifier: bundleId,
            version: extractedVersion,
            downloadURL: "", // User needs to provide this
            size: fileSize,
            developerName: developerName
        )
        
        // Open editor to let user edit/complete the info
        extractedApp = newApp
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    // MARK: - Saved Repos Helpers
    
    private func _loadSavedRepos() {
        let fileManager = FileManager.default
        let reposFolder = Self.reposFolderURL
        
        do {
            let files = try fileManager.contentsOfDirectory(at: reposFolder, includingPropertiesForKeys: [.creationDateKey])
            // Filter for JSON files only and sort by filename
            savedRepos = files
                .filter { $0.pathExtension.lowercased() == "json" }
                .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            savedRepos = []
        }
    }
    
    private func _loadRepoFromFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "RepoMaker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
            }
            
            // Parse repository info
            repoName = json["name"] as? String ?? ""
            repoIdentifier = json["identifier"] as? String ?? ""
            repoSubtitle = json["subtitle"] as? String ?? ""
            repoDescription = json["description"] as? String ?? ""
            repoIconURL = json["iconURL"] as? String ?? ""
            repoWebsite = json["website"] as? String ?? ""
            repoTintColor = json["tintColor"] as? String ?? "#4A90D9"
            
            // Parse apps
            if let appsArray = json["apps"] as? [[String: Any]] {
                apps = appsArray.compactMap { appDict in
                    let versions = appDict["versions"] as? [[String: Any]] ?? []
                    let latestVersion = versions.first
                    
                    return RepoAppEntry(
                        name: appDict["name"] as? String ?? "",
                        bundleIdentifier: appDict["bundleIdentifier"] as? String ?? "",
                        version: latestVersion?["version"] as? String ?? "1.0",
                        versionDescription: latestVersion?["localizedDescription"] as? String ?? "",
                        downloadURL: latestVersion?["downloadURL"] as? String ?? "",
                        iconURL: appDict["iconURL"] as? String ?? "",
                        size: latestVersion?["size"] as? Int ?? 0,
                        developerName: appDict["developerName"] as? String ?? "",
                        localizedDescription: appDict["localizedDescription"] as? String ?? "",
                        subtitle: appDict["subtitle"] as? String ?? "",
                        screenshotURLs: appDict["screenshotURLs"] as? [String] ?? [],
                        tintColor: appDict["tintColor"] as? String ?? "#4A90D9"
                    )
                }
            }
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Load Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func _deleteRepoFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            _loadSavedRepos()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Delete Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    // MARK: - Add to Sources
    
    private func _addCreatedRepoToSources() {
        // If there's no saved repo, save current first
        if savedRepos.isEmpty && !repoName.isEmpty && !apps.isEmpty {
            _saveRepo()
            _loadSavedRepos()
        }
        
        guard let lastRepoURL = savedRepos.last else {
            UIAlertController.showAlertWithOk(
                title: .localized("No Repo Found"),
                message: .localized("Please create and save a repository first by clicking 'Create Repository'.")
            )
            return
        }
        
        // Use NBFetchService to load and parse the repo JSON (mirrors SourcesAddView pattern)
        let dataService = NBFetchService()
        
        typealias RepositoryDataHandler = Result<ASRepository, Error>
        
        dataService.fetch(from: lastRepoURL) { (result: RepositoryDataHandler) in
            switch result {
            case .success(let repo):
                Storage.shared.addSources(repos: [lastRepoURL: repo]) { error in
                    if let error = error {
                        UIAlertController.showAlertWithOk(
                            title: .localized("Failed to Add Source"),
                            message: error.localizedDescription
                        )
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        UIAlertController.showAlertWithOk(
                            title: .localized("Success"),
                            message: .localized("Repository '\(repo.name ?? repoName)' added to Sources! You can now browse and download apps from it in the Sources tab.")
                        )
                    }
                }
            case .failure(let error):
                UIAlertController.showAlertWithOk(
                    title: .localized("Failed to Add Source"),
                    message: error.localizedDescription
                )
            }
        }
    }
}

// MARK: - App Editor View
struct RepoAppEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingApp: RepoAppEntry?
    let onSave: (RepoAppEntry) -> Void
    
    @State private var name: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var version: String = "1.0"
    @State private var versionDescription: String = ""
    @State private var downloadURL: String = ""
    @State private var iconURL: String = ""
    @State private var size: String = ""
    @State private var developerName: String = ""
    @State private var localizedDescription: String = ""
    @State private var subtitle: String = ""
    @State private var tintColor: String = "#4A90D9"
    
    init(app: RepoAppEntry?, onSave: @escaping (RepoAppEntry) -> Void) {
        self.existingApp = app
        self.onSave = onSave
        
        if let app = app {
            _name = State(initialValue: app.name)
            _bundleIdentifier = State(initialValue: app.bundleIdentifier)
            _version = State(initialValue: app.version)
            _versionDescription = State(initialValue: app.versionDescription)
            _downloadURL = State(initialValue: app.downloadURL)
            _iconURL = State(initialValue: app.iconURL)
            _size = State(initialValue: app.size > 0 ? String(app.size) : "")
            _developerName = State(initialValue: app.developerName)
            _localizedDescription = State(initialValue: app.localizedDescription)
            _subtitle = State(initialValue: app.subtitle)
            _tintColor = State(initialValue: app.tintColor)
        }
    }
    
    var body: some View {
        NBNavigationView(existingApp == nil ? .localized("Add App") : .localized("Edit App"), displayMode: .inline) {
            Form {
                NBSection(.localized("Basic Info")) {
                    TextField(.localized("App Name"), text: $name)
                    TextField(.localized("Bundle Identifier"), text: $bundleIdentifier)
                        .textInputAutocapitalization(.never)
                    TextField(.localized("Developer Name"), text: $developerName)
                }
                
                NBSection(.localized("Version")) {
                    TextField(.localized("Version"), text: $version)
                    TextField(.localized("Version Description"), text: $versionDescription)
                }
                
                NBSection(.localized("URLs")) {
                    TextField(.localized("Download URL (IPA)"), text: $downloadURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField(.localized("Icon URL"), text: $iconURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                
                NBSection(.localized("Additional Info")) {
                    TextField(.localized("Subtitle"), text: $subtitle)
                    TextField(.localized("Description"), text: $localizedDescription)
                    TextField(.localized("Size (bytes)"), text: $size)
                        .keyboardType(.numberPad)
                    TextField(.localized("Tint Color (hex)"), text: $tintColor)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Save")) {
                        _saveApp()
                    }
                    .disabled(name.isEmpty || downloadURL.isEmpty)
                }
            }
        }
    }
    
    private func _saveApp() {
        let app = RepoAppEntry(
            id: existingApp?.id ?? UUID(),
            name: name,
            bundleIdentifier: bundleIdentifier,
            version: version,
            versionDescription: versionDescription,
            downloadURL: downloadURL,
            iconURL: iconURL,
            size: Int(size) ?? 0,
            developerName: developerName,
            localizedDescription: localizedDescription,
            subtitle: subtitle,
            screenshotURLs: existingApp?.screenshotURLs ?? [],
            tintColor: tintColor
        )
        
        onSave(app)
        dismiss()
    }
}

// MARK: - Export View
struct RepoExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    let json: String
    let repoName: String
    
    @State private var showShareSheet = false
    
    var body: some View {
        NBNavigationView(.localized("Generated Repository"), displayMode: .inline) {
            VStack(spacing: 0) {
                // Preview Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(repoName)
                            .font(.headline)
                        Text("\(json.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Copy Button
                    Button {
                        UIPasteboard.general.string = json
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        UIAlertController.showAlertWithOk(
                            title: .localized("Copied!"),
                            message: .localized("Repository JSON copied to clipboard.")
                        )
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .padding(12)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                
                // JSON Preview
                ScrollView {
                    Text(json)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemBackground))
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        _saveToFile()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text(.localized("Save to Files"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(.localized("Share"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = json.data(using: .utf8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(repoName).json")
                let _ = try? data.write(to: tempURL)
                ActivityViewController(activityItems: [tempURL])
            }
        }
    }
    
    private func _saveToFile() {
        guard let data = json.data(using: .utf8) else { return }
        
        let fileName = "\(repoName.replacingOccurrences(of: " ", with: "_")).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(documentPicker, animated: true)
            }
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: error.localizedDescription
            )
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
