//
//  ImportFromAppStoreView.swift
//  SwiftSigner Pro
//
//  Modal view to search and import apps from the App Store
//

import SwiftUI
import NukeUI
import NimbleViews

struct ImportFromAppStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeClient = AppStoreClient.shared
    @ObservedObject private var downloadManager = DownloadManager.shared
    
    @State private var searchText = ""
    @State private var searchResults: [AppStoreSearchResult] = []
    @State private var isSearching = false
    @State private var selectedApp: AppStoreSearchResult?
    @State private var showLoginSheet = false
    @State private var showVersionPicker = false
    @State private var availableVersions: [AppStoreVersionInfo] = []
    @State private var isLoadingVersions = false
    @State private var downloadingAppId: Int?
    @State private var showDataResetWarning = false
    @State private var pendingDownload: (appId: String, versionId: String?)?
    @State private var searchOffset = 0
    @State private var hasMoreResults = true
    
    var body: some View {
        NBNavigationView(.localized("Import from App Store"), displayMode: .inline) {
            VStack(spacing: 0) {
                if !storeClient.isAuthenticated {
                    _loginPromptView()
                } else {
                    _searchResultsView()
                }
            }
            .searchable(text: $searchText, prompt: Text(.localized("Search App Store...")))
            .onChange(of: searchText) { _, newValue in
                _performSearch(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                if storeClient.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                storeClient.logout()
                            } label: {
                                Label(.localized("Logout"), systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            AppStoreLoginView()
        }
        .sheet(isPresented: $showVersionPicker) {
            if let app = selectedApp {
                AppVersionPickerView(
                    app: app,
                    versions: availableVersions,
                    isLoading: isLoadingVersions,
                    onSelect: { versionId in
                        _startDownloadWithWarning(appId: String(app.trackId), versionId: versionId)
                    }
                )
            }
        }
        .alert(.localized("Data Reset Warning"), isPresented: $showDataResetWarning) {
            Button(.localized("Cancel"), role: .cancel) {
                pendingDownload = nil
            }
            Button(.localized("Continue"), role: .destructive) {
                if let download = pendingDownload {
                    _performDownload(appId: download.appId, versionId: download.versionId)
                }
            }
        } message: {
            Text(.localized("Downloading a different version may reset all app data. Are you sure you want to continue?"))
        }
    }
    
    // MARK: - Login Prompt View
    @ViewBuilder
    private func _loginPromptView() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "apple.logo")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(.localized("Sign in with Apple ID"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(.localized("Login to your Apple ID to search and download apps from the App Store."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showLoginSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                    Text(.localized("Sign In"))
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Search Results View
    @ViewBuilder
    private func _searchResultsView() -> some View {
        if isSearching {
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text(.localized("Searching..."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Spacer()
            }
        } else if searchResults.isEmpty && !searchText.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text(.localized("No apps found"))
                    .font(.headline)
                Text(.localized("Try a different search term"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else if searchResults.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text(.localized("Search the App Store"))
                    .font(.headline)
                Text(.localized("Enter an app name to search"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(searchResults) { app in
                        _appCardView(app)
                            .onAppear {
                                // Infinite scroll - load more when near end
                                if app == searchResults.last {
                                    _loadMoreResults()
                                }
                            }
                    }
                    
                    if isSearching && !searchResults.isEmpty {
                        HStack {
                            ProgressView()
                            Text(.localized("Loading more..."))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - App Card View (like Repo Card)
    @ViewBuilder
    private func _appCardView(_ app: AppStoreSearchResult) -> some View {
        let isDownloading = downloadingAppId == app.trackId
        
        VStack(alignment: .leading, spacing: 0) {
            // Header with Icon and Basic Info
            HStack(spacing: 14) {
                // App Icon
                if let iconURL = app.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.2))
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "app.dashed")
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                }
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.trackName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(app.sellerName ?? "Unknown Developer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("v\(app.version)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                        
                        Text(app.fileSizeFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let rating = app.averageUserRating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            
            // Description
            if let description = app.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            
            // Bundle ID and Genre
            HStack(spacing: 12) {
                Label(app.bundleId, systemImage: "shippingbox")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if let genre = app.primaryGenreName {
                    Text(genre)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.8))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                // Download Latest Button
                Button {
                    _handleAppTap(app)
                } label: {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "icloud.and.arrow.down.fill")
                        }
                        Text(.localized("Download"))
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(isDownloading)
                
                // Older Versions Button
                Button {
                    selectedApp = app
                    _loadVersions(for: app)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text(.localized("Versions"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - App Row View
    @ViewBuilder
    private func _appRowView(_ app: AppStoreSearchResult) -> some View {
        let isDownloading = downloadingAppId == app.trackId
        
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
                .clipShape(RoundedRectangle(cornerRadius: 13))
            } else {
                RoundedRectangle(cornerRadius: 13)
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
                Text(app.trackName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(app.sellerName ?? "Unknown Developer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("v\(app.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(app.fileSizeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let rating = app.averageUserRating {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Download Button
            if isDownloading {
                ProgressView()
                    .frame(width: 28, height: 28)
            } else {
                Button {
                    _handleAppTap(app)
                } label: {
                    Image(systemName: "icloud.and.arrow.down.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                _handleAppTap(app)
            } label: {
                Label(.localized("Download Latest"), systemImage: "arrow.down.circle")
            }
            
            Button {
                selectedApp = app
                _loadVersions(for: app)
            } label: {
                Label(.localized("Download Older Version"), systemImage: "clock.arrow.circlepath")
            }
            
            Divider()
            
            Button {
                UIPasteboard.general.string = app.appStoreLink
            } label: {
                Label(.localized("Copy App Store Link"), systemImage: "doc.on.doc")
            }
            
            Button {
                UIPasteboard.general.string = app.bundleId
            } label: {
                Label(.localized("Copy Bundle ID"), systemImage: "number")
            }
        }
    }
    
    // MARK: - Actions
    private func _performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            searchOffset = 0
            hasMoreResults = true
            return
        }
        
        // Debounce
        let searchQuery = query
        isSearching = true
        searchOffset = 0
        hasMoreResults = true
        
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            // Check if still the current search
            guard searchQuery == searchText else { return }
            
            let results = await storeClient.searchApps(query: query, limit: 25, offset: 0)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
                searchOffset = results.count
                hasMoreResults = results.count >= 25
            }
        }
    }
    
    private func _loadMoreResults() {
        guard !isSearching && hasMoreResults && !searchText.isEmpty else { return }
        
        isSearching = true
        
        Task {
            let results = await storeClient.searchApps(query: searchText, limit: 25, offset: searchOffset)
            
            await MainActor.run {
                // Append new results, avoiding duplicates
                let newApps = results.filter { newApp in
                    !searchResults.contains { $0.trackId == newApp.trackId }
                }
                searchResults.append(contentsOf: newApps)
                isSearching = false
                searchOffset += results.count
                hasMoreResults = results.count >= 25
            }
        }
    }
    
    private func _handleAppTap(_ app: AppStoreSearchResult) {
        selectedApp = app
        _startDownloadWithWarning(appId: String(app.trackId), versionId: nil)
    }
    
    private func _loadVersions(for app: AppStoreSearchResult) {
        showVersionPicker = true
        isLoadingVersions = true
        
        Task {
            let versions = await storeClient.getVersionList(appId: String(app.trackId))
            await MainActor.run {
                availableVersions = versions
                isLoadingVersions = false
            }
        }
    }
    
    private func _startDownloadWithWarning(appId: String, versionId: String?) {
        if versionId != nil {
            // Show warning for downgrade
            pendingDownload = (appId, versionId)
            showDataResetWarning = true
        } else {
            _performDownload(appId: appId, versionId: versionId)
        }
    }
    
    private func _performDownload(appId: String, versionId: String?) {
        guard let app = selectedApp else { return }
        
        downloadingAppId = app.trackId
        showVersionPicker = false
        
        // Add to downloading apps manager to show in Library
        let downloadId = UUID()
        let downloadingApp = DownloadingApp(
            id: downloadId,
            name: app.trackName,
            bundleId: app.bundleId,
            iconURL: app.iconURL,
            status: .waiting,
            progress: 0.0,
            version: app.version,
            seller: app.sellerName
        )
        DownloadingAppsManager.shared.addDownload(downloadingApp)
        
        // Dismiss the sheet immediately so user can see progress in Library
        dismiss()
        
        Task {
            // Update status to downloading
            await MainActor.run {
                DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .downloading)
            }
            
            if let ipaURL = await storeClient.downloadIPA(appId: appId, versionId: versionId) {
                // Update status to extracting
                await MainActor.run {
                    DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 0.8)
                    DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .extracting)
                }
                
                // Import the IPA
                let dl = downloadManager.startArchive(from: ipaURL, id: downloadId.uuidString)
                
                // Store the App Store link for this app
                UserDefaults.standard.set(app.appStoreLink, forKey: "AppStoreLink_\(app.bundleId)")
                
                // Update status to importing
                await MainActor.run {
                    DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 0.9)
                    DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .importing)
                }
                
                downloadManager.handlePachageFile(url: ipaURL, dl: dl) { error in
                    DispatchQueue.main.async {
                        downloadingAppId = nil
                        if error == nil {
                            DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 1.0)
                            DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .completed)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .failed(error?.localizedDescription ?? "Unknown error"))
                            // Remove failed download after 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                DownloadingAppsManager.shared.removeDownload(id: downloadId)
                            }
                        }
                    }
                }
            } else {
                await MainActor.run {
                    downloadingAppId = nil
                    DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .failed("Failed to download from App Store"))
                    // Remove failed download after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        DownloadingAppsManager.shared.removeDownload(id: downloadId)
                    }
                }
            }
        }
    }
}

// MARK: - App Store Login View
struct AppStoreLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeClient = AppStoreClient.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var twoFACode = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 48))
                        .foregroundColor(.primary)
                    
                    Text(.localized("Apple ID"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    TextField(.localized("Apple ID Email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    HStack {
                        if showPassword {
                            TextField(.localized("Password"), text: $password)
                        } else {
                            SecureField(.localized("Password"), text: $password)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    if storeClient.needs2FA {
                        TextField(.localized("2FA Code"), text: $twoFACode)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        Text(.localized("Enter the verification code sent to your trusted devices. If you didn't receive one, enter any 6 random digits."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                if let error = storeClient.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Login Button
                Button {
                    _authenticate()
                } label: {
                    HStack {
                        if storeClient.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(storeClient.needs2FA ? .localized("Verify") : .localized("Sign In"))
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(email.isEmpty || password.isEmpty || storeClient.isAuthenticating)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
            }
            .onChange(of: storeClient.isAuthenticated) { _, isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }
    
    private func _authenticate() {
        Task {
            // Append 2FA code to password like PancakeStore does
            let finalPassword = storeClient.needs2FA ? password + twoFACode : password
            _ = await storeClient.authenticate(email: email, password: finalPassword)
        }
    }
}

// MARK: - Version Picker View
struct AppVersionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let app: AppStoreSearchResult
    let versions: [AppStoreVersionInfo]
    let isLoading: Bool
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(.localized("Loading versions..."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if versions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(.localized("No versions available"))
                            .font(.headline)
                        Text(.localized("This app may not have older versions accessible"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            // Header with app info
                            HStack(spacing: 12) {
                                if let iconURL = app.iconURL {
                                    LazyImage(url: iconURL) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.secondary.opacity(0.2))
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.trackName)
                                        .font(.headline)
                                    Text(.localized("Select a version to download"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section(.localized("Available Versions")) {
                            ForEach(versions) { version in
                                Button {
                                    onSelect(version.versionId)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(version.bundleVersion)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text("ID: \(version.versionId)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.down.circle")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(.localized("Select Version"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ImportFromAppStoreView()
}
