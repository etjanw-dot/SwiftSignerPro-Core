//
//  ImportFromRepoView.swift
//  Ksign
//
//  Import apps from repositories into the library
//

import SwiftUI
import NimbleViews
import NukeUI
import AltSourceKit
import Combine
import CoreData

// Helper struct to pair app with its source repository
struct ImportAppWithSource: Identifiable {
    var id: String { app.uuid.uuidString }
    let app: ASRepository.App
    let repoName: String
    let repoIconURL: URL?
}

// MARK: - View
struct ImportFromRepoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel = SourcesViewModel.shared
    @ObservedObject private var downloadManager = DownloadManager.shared
    
    @State private var selectedSource: AltSource?
    @State private var searchText = ""
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>
    
    private var allApps: [ImportAppWithSource] {
        if let source = selectedSource,
           let repo = viewModel.sources[source] {
            return repo.apps.map { ImportAppWithSource(app: $0, repoName: source.name ?? "Unknown", repoIconURL: source.iconURL) }
        }
        
        var apps: [ImportAppWithSource] = []
        for (source, repo) in viewModel.sources {
            for app in repo.apps {
                apps.append(ImportAppWithSource(app: app, repoName: source.name ?? "Unknown", repoIconURL: source.iconURL))
            }
        }
        return apps
    }
    
    private var filteredApps: [ImportAppWithSource] {
        if searchText.isEmpty {
            return allApps
        }
        return allApps.filter { appWithSource in
            (appWithSource.app.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (appWithSource.app.id ?? "").localizedCaseInsensitiveContains(searchText) ||
            appWithSource.repoName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NBNavigationView(.localized("Import from Repo"), displayMode: .inline) {
            VStack(spacing: 0) {
                // Source Filter
                _sourceFilterPicker()
                
                // Apps List
                if !viewModel.isFinished {
                    // Show skeleton loading that matches the app cards layout
                    SkeletonBulkDownloadView()
                } else if filteredApps.isEmpty {
                    _emptyState()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredApps) { appWithSource in
                                ImportFromRepoAppCard(appWithSource: appWithSource)
                            }
                        }
                        .padding()
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text(.localized("Search apps...")))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await viewModel.fetchSources(sources, refresh: true)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func _sourceFilterPicker() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Sources option
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSource = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption)
                        Text(.localized("All"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedSource == nil ? Color.accentColor : Color.secondary.opacity(0.15))
                    )
                    .foregroundColor(selectedSource == nil ? .white : .primary)
                }
                
                // Individual Sources
                ForEach(sources, id: \.identifier) { source in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSource = source
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let iconURL = source.iconURL {
                                LazyImage(url: iconURL) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Image(systemName: "app.dashed")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 16, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Text(source.name ?? .localized("Unknown"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedSource?.identifier == source.identifier ? Color.accentColor : Color.secondary.opacity(0.15))
                        )
                        .foregroundColor(selectedSource?.identifier == source.identifier ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private func _emptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(.localized("No Apps Available"))
                .font(.headline)
            
            Text(.localized("Add repositories in the Sources tab to see apps here."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - App Card with Download Tracking (mirrors DownloadButtonView pattern)
struct ImportFromRepoAppCard: View {
    let appWithSource: ImportAppWithSource
    
    private var app: ASRepository.App { appWithSource.app }
    
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    
    // Check if app exists in library (by bundle identifier)
    @FetchRequest private var importedApps: FetchedResults<Imported>
    
    init(appWithSource: ImportAppWithSource) {
        self.appWithSource = appWithSource
        
        // Create fetch request to check if app with this bundle ID exists
        let request: NSFetchRequest<Imported> = Imported.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", appWithSource.app.id ?? "")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
        request.fetchLimit = 1
        _importedApps = FetchRequest(fetchRequest: request)
    }
    
    private var isInLibrary: Bool {
        !importedApps.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.2))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 13.5))
            } else {
                RoundedRectangle(cornerRadius: 13.5)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "app.dashed")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.currentName)
                    .font(.headline)
                    .lineLimit(1)
                
                // Repository source badge
                HStack(spacing: 4) {
                    if let repoIconURL = appWithSource.repoIconURL {
                        LazyImage(url: repoIconURL) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 8))
                            }
                        }
                        .frame(width: 12, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(appWithSource.repoName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
                
                HStack(spacing: 4) {
                    Text(app.currentVersion ?? "1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let size = app.size {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Download Button
            _downloadButton()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onAppear(perform: setupObserver)
        .onDisappear { cancellable?.cancel() }
        .onChange(of: downloadManager.downloads.description) { _ in
            setupObserver()
        }
        .animation(.easeInOut(duration: 0.3), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
        .animation(.easeInOut(duration: 0.3), value: isInLibrary)
    }
    
    @ViewBuilder
    private func _downloadButton() -> some View {
        if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
            // Downloading state - circular progress (mirrors DownloadButtonView)
            _downloadingButton(currentDownload)
        } else if isInLibrary {
            // Downloaded/In Library state - checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        } else {
            // Download button - Get button style
            Button {
                _downloadApp()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(.localized("Get"))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.borderless)
        }
    }
    
    @ViewBuilder
    private func _downloadingButton(_ currentDownload: Download) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .trim(from: 0, to: downloadProgress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)
                    .animation(.smooth, value: downloadProgress)
                
                if downloadProgress >= 0.75 {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(.tint)
                        .font(.system(size: 10, weight: .bold))
                } else {
                    Image(systemName: "square.fill")
                        .foregroundStyle(.tint)
                        .font(.system(size: 8))
                }
            }
            
            Text("\(Int(downloadProgress * 100))%")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.15))
        )
        .onTapGesture {
            if downloadProgress <= 0.75 {
                downloadManager.cancelDownload(currentDownload)
            }
        }
    }
    
    private func _downloadApp() {
        guard let downloadURL = app.currentDownloadUrl else {
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: .localized("Invalid download URL")
            )
            return
        }
        
        // Create a unique download ID
        let downloadId = UUID()
        
        // Add to DownloadingAppsManager so it shows in Library
        let downloadingApp = DownloadingApp(
            id: downloadId,
            name: app.currentName,
            bundleId: app.id ?? "unknown",
            iconURL: app.iconURL,
            status: .waiting,
            progress: 0
        )
        DownloadingAppsManager.shared.addDownload(downloadingApp)
        
        // Use app.currentUniqueId as the download ID (matches DownloadButtonView pattern)
        let download = downloadManager.startDownload(from: downloadURL, id: app.currentUniqueId)
        
        // Observe download progress and update DownloadingAppsManager
        Task {
            // Update status to downloading
            await MainActor.run {
                DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .downloading)
            }
            
            // Monitor progress
            var lastProgress: Double = 0
            while downloadManager.getDownload(by: app.currentUniqueId) != nil {
                if let dl = downloadManager.getDownload(by: app.currentUniqueId) {
                    let progress = dl.overallProgress
                    if abs(progress - lastProgress) > 0.01 {
                        lastProgress = progress
                        await MainActor.run {
                            DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: progress)
                            
                            if progress >= 0.75 {
                                DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .extracting)
                            }
                        }
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            
            // Download completed or failed
            await MainActor.run {
                // Check if app is now in library
                let fetchRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "identifier == %@", app.id ?? "")
                fetchRequest.fetchLimit = 1
                
                if let count = try? Storage.shared.container.viewContext.count(for: fetchRequest), count > 0 {
                    DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 1.0)
                    DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .completed)
                } else {
                    DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .failed("Download failed"))
                }
                
                // Remove after a delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                    await MainActor.run {
                        DownloadingAppsManager.shared.removeDownload(id: downloadId)
                    }
                }
            }
        }
    }
    
    private func setupObserver() {
        cancellable?.cancel()
        guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
            downloadProgress = 0
            return
        }
        downloadProgress = download.overallProgress
        
        let publisher = Publishers.CombineLatest(
            download.$progress,
            download.$unpackageProgress
        )
        
        cancellable = publisher.sink { _, _ in
            downloadProgress = download.overallProgress
        }
    }
}
