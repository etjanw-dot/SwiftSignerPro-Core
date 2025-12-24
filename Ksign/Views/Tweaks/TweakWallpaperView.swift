//
//  TweakWallpaperView.swift
//  Ksign
//
//  Wallpaper tweak view - wrapper around WallpaperView for the Tweaks category.
//

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import NimbleViews

struct TweakWallpaperView: View {
    @StateObject private var manager = WallpaperManager.shared
    
    @State private var showTendiesImporter: Bool = false
    @State private var checkingForHash: Bool = false
    @State private var hashCheckTask: Task<Void, any Error>? = nil
    @State private var showApplyAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    var body: some View {
        List {
            // Hash Configuration Section
            hashSection
            
            // Import Section
            importSection
            
            // Selected Tendies Section
            if !manager.selectedTendies.isEmpty {
                selectedTendiesSection
            }
            
            // Actions Section
            if !manager.posterBoardHash.isEmpty {
                actionsSection
            }
            
            // Links Section
            linksSection
            
            // Help Section
            helpSection
        }
        .navigationTitle(.localized("Wallpaper"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let wpURL = URL(string: WallpaperManager.WallpapersURL) {
                    Link(destination: wpURL) {
                        Image(systemName: "safari")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showTendiesImporter,
            allowedContentTypes: [UTType(filenameExtension: "tendies", conformingTo: .data)!],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .alert(alertTitle, isPresented: $showApplyAlert) {
            Button(.localized("OK"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if manager.isApplying {
                applyingOverlay
            }
        }
        .onAppear {
            // Try to auto-detect hash on appear if empty
            if manager.posterBoardHash.isEmpty {
                checkForExistingHash()
            }
        }
    }
    
    // MARK: - Hash Section
    
    private var hashSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lock.app.dashed")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("PosterBoard App Hash"))
                            .font(.headline)
                        Text(.localized("Required for wallpaper application"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField(.localized("Enter PosterBoard App Hash"), text: $manager.posterBoardHash)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: manager.posterBoardHash) { newValue in
                        manager.saveHash(newValue)
                    }
                
                HStack {
                    // Auto-detect button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        autoDetectHash()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text(.localized("Auto-Detect"))
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    Spacer()
                    
                    // Wait for Nugget button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        startWaitForHash()
                    } label: {
                        HStack(spacing: 6) {
                            if checkingForHash {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text(checkingForHash ? .localized("Detecting...") : .localized("Via Nugget"))
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .disabled(checkingForHash)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label(.localized("Configuration"), systemImage: "gearshape.fill")
        } footer: {
            Text(.localized("Use Auto-Detect to automatically find the hash, or connect to Nugget on your computer."))
        }
    }
    
    // MARK: - Import Section
    
    private var importSection: some View {
        Section {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showTendiesImporter.toggle()
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Import Wallpaper Files"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(.localized("Select .tendies files"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label(.localized("Import"), systemImage: "square.and.arrow.down.fill")
        }
    }
    
    // MARK: - Selected Tendies Section
    
    private var selectedTendiesSection: some View {
        Section {
            ForEach(manager.selectedTendies, id: \.self) { tendie in
                HStack {
                    Image(systemName: "photo.artframe")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .font(.title3)
                    
                    VStack(alignment: .leading) {
                        Text(tendie.deletingPathExtension().lastPathComponent)
                            .font(.body)
                        Text(".tendies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: manager.removeTendie)
        } header: {
            HStack {
                Label(.localized("Selected Wallpapers"), systemImage: "photo.stack.fill")
                Spacer()
                Text("\(manager.selectedTendies.count)/\(WallpaperManager.MaxTendies)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            // Apply Button
            if !manager.selectedTendies.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    applyWallpapers()
                } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Apply Wallpapers"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(.localized("Install selected wallpapers"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Reset Collections Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                resetCollections()
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.2), .orange.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Reset Collections"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(.localized("Fix wallpaper display issues"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label(.localized("Actions"), systemImage: "hammer.fill")
        }
    }
    
    // MARK: - Links Section
    
    private var linksSection: some View {
        Section {
            if let wpURL = URL(string: WallpaperManager.WallpapersURL) {
                Link(destination: wpURL) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.title3)
                        
                        Text(.localized("Browse Wallpapers"))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            if let scURL = URL(string: WallpaperManager.ShortcutURL) {
                Link(destination: scURL) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.title3)
                        
                        Text(.localized("Download Fallback Shortcut"))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        } header: {
            Label(.localized("Resources"), systemImage: "link")
        }
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                stepRow(number: "1", color: .blue, title: .localized("Get Hash"), description: .localized("Use Auto-Detect or Nugget to get the PosterBoard hash"))
                stepRow(number: "2", color: .green, title: .localized("Download"), description: .localized("Get .tendies files from the wallpaper website"))
                stepRow(number: "3", color: .purple, title: .localized("Apply"), description: .localized("Import files and tap Apply to install"))
            }
            .padding(.vertical, 8)
        } header: {
            Label(.localized("How It Works"), systemImage: "questionmark.circle.fill")
        }
    }
    
    private func stepRow(number: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Applying Overlay
    
    private var applyingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(.localized("Applying Wallpapers..."))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(manager.applyProgress)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Functions
    
    private func checkForExistingHash() {
        // Check if hash file exists from a previous Nugget connection
        let filePath = WallpaperSymHandler.getPosterBoardHashURL()
        if FileManager.default.fileExists(atPath: filePath.path) {
            if let contents = try? String(contentsOf: filePath, encoding: .utf8) {
                let hash = contents.trimmingCharacters(in: .whitespacesAndNewlines)
                if !hash.isEmpty {
                    manager.saveHash(hash)
                    try? FileManager.default.removeItem(at: filePath)
                }
            }
        }
    }
    
    private func autoDetectHash() {
        // Try to find the PosterBoard hash automatically
        let possiblePaths = [
            "/var/mobile/Containers/Data/Application",
            "/private/var/mobile/Containers/Data/Application"
        ]
        
        for basePath in possiblePaths {
            if let apps = try? FileManager.default.contentsOfDirectory(atPath: basePath) {
                for app in apps {
                    let posterBoardPath = "\(basePath)/\(app)/Library/Application Support/PRBPosterExtensionDataStore"
                    if FileManager.default.fileExists(atPath: posterBoardPath) {
                        manager.saveHash(app)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        alertTitle = .localized("Hash Found!")
                        alertMessage = .localized("PosterBoard hash has been automatically detected.")
                        showApplyAlert = true
                        return
                    }
                }
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        alertTitle = .localized("Hash Not Found")
        alertMessage = .localized("Could not auto-detect the hash. Try using Nugget on your computer instead.")
        showApplyAlert = true
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if manager.selectedTendies.count + urls.count > WallpaperManager.MaxTendies {
                alertTitle = .localized("Max Wallpapers Reached")
                alertMessage = String(format: .localized("You can only apply %d wallpapers at a time."), WallpaperManager.MaxTendies)
                showApplyAlert = true
            } else {
                manager.selectedTendies.append(contentsOf: urls)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        case .failure(let error):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            alertTitle = .localized("Import Failed")
            alertMessage = error.localizedDescription
            showApplyAlert = true
        }
    }
    
    private func startWaitForHash() {
        checkingForHash = true
        hashCheckTask = Task {
            let filePath = WallpaperSymHandler.getPosterBoardHashURL()
            
            var attempts = 0
            while !FileManager.default.fileExists(atPath: filePath.path) && attempts < 120 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                try Task.checkCancellation()
                attempts += 1
            }
            
            if FileManager.default.fileExists(atPath: filePath.path) {
                do {
                    let contents = try String(contentsOf: filePath, encoding: .utf8)
                    try? FileManager.default.removeItem(at: filePath)
                    await MainActor.run {
                        manager.saveHash(contents.trimmingCharacters(in: .whitespacesAndNewlines))
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        alertTitle = .localized("Hash Detected!")
                        alertMessage = .localized("PosterBoard hash has been automatically configured.")
                        showApplyAlert = true
                    }
                } catch {
                    await MainActor.run {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        alertTitle = .localized("Detection Failed")
                        alertMessage = error.localizedDescription
                        showApplyAlert = true
                    }
                }
            } else {
                await MainActor.run {
                    alertTitle = .localized("Detection Timeout")
                    alertMessage = .localized("Could not detect the hash. Make sure Nugget is connected.")
                    showApplyAlert = true
                }
            }

            await MainActor.run {
                checkingForHash = false
                hashCheckTask = nil
            }
        }
    }
    
    private func applyWallpapers() {
        Task {
            do {
                try await manager.applyTendies()
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    alertTitle = .localized("Success!")
                    alertMessage = .localized("Wallpapers have been applied. The PosterBoard app will now open.")
                    showApplyAlert = true
                    
                    if !manager.openPosterBoard() {
                        manager.runShortcut(named: "PosterBoard")
                    }
                }
            } catch {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    alertTitle = .localized("Apply Failed")
                    alertMessage = error.localizedDescription
                    showApplyAlert = true
                }
            }
        }
    }
    
    private func resetCollections() {
        if #available(iOS 18.0, *) {
            guard let lang = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first else {
                return
            }
            
            if manager.setSystemLanguage(to: lang) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                alertTitle = .localized("Collections Reset!")
                alertMessage = .localized("Your PosterBoard will refresh automatically.")
                showApplyAlert = true
            } else {
                alertTitle = .localized("Reset Failed")
                alertMessage = .localized("The API failed to call correctly.")
                showApplyAlert = true
            }
        } else {
            alertTitle = .localized("Not Supported")
            alertMessage = .localized("Reset Collections requires iOS 18.0 or later.")
            showApplyAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        TweakWallpaperView()
    }
}
#endif
