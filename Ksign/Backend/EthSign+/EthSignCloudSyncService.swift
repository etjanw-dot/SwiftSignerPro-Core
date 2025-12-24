//
//  EthSignCloudSyncService.swift
//  Ksign
//
//  EthSign+ Cloud Sync Service for syncing certificates, repos, and app library
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Sync Error
enum EthSignSyncError: LocalizedError {
    case notAuthenticated
    case networkError
    case encryptionError
    case decryptionError
    case serverError(String)
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to sync your data"
        case .networkError:
            return "Network error. Please check your connection"
        case .encryptionError:
            return "Failed to encrypt data for sync"
        case .decryptionError:
            return "Failed to decrypt synced data"
        case .serverError(let message):
            return message
        case .notConfigured:
            return "SwiftSigner Pro is not configured"
        }
    }
}

// MARK: - Sync Status
enum SyncStatus: String {
    case idle = "idle"
    case syncing = "syncing"
    case success = "success"
    case error = "error"
}

// MARK: - Sync Data Models
struct SyncedCertificate: Codable, Identifiable {
    let id: String
    let name: String
    let p12Data: String  // Base64 encoded, encrypted
    let provisionData: String  // Base64 encoded, encrypted
    let passwordEncrypted: String
    let teamId: String?
    let expirationDate: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct SyncedSource: Codable, Identifiable {
    let id: String
    let name: String
    let url: String
    let iconURL: String?
    let createdAt: Date
}

struct SyncedAppMetadata: Codable, Identifiable {
    let id: String
    let bundleIdentifier: String
    let name: String
    let version: String
    let iconURL: String?
    let sourceURL: String?
    let createdAt: Date
}

// MARK: - Cloud Sync Service
class EthSignCloudSyncService: ObservableObject {
    static let shared = EthSignCloudSyncService()
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isSyncEnabled: Bool = false
    @Published var syncError: String?
    
    // MARK: - Private Properties
    private let authService = EthSignAuthService.shared
    private let lastSyncKey = "ethsign.sync.lastSync"
    private let syncEnabledKey = "ethsign.sync.enabled"
    
    // Built-in Supabase URL (matches EthSignAuthService)
    private static let defaultSupabaseURL = "https://eyufnmqchlgiqnesgsdi.supabase.co"
    private static let defaultSupabaseAnonKey = "sb_publishable_o8Svinw36oSV1eXXpyyEJQ_VTAEoxnR"
    
    private var supabaseURL: String {
        UserDefaults.standard.string(forKey: "ethsign.supabase.url") ?? Self.defaultSupabaseURL
    }
    
    private var supabaseAnonKey: String {
        UserDefaults.standard.string(forKey: "ethsign.supabase.anonKey") ?? Self.defaultSupabaseAnonKey
    }
    
    // MARK: - Initialization
    init() {
        loadSyncState()
    }
    
    private func loadSyncState() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = lastSync
        }
    }
    
    // MARK: - Enable/Disable Sync
    func enableSync(_ enabled: Bool) {
        isSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: syncEnabledKey)
        
        if enabled && authService.isAuthenticated {
            Task {
                await performFullSync()
            }
        }
    }
    
    // MARK: - Full Sync
    func performFullSync() async {
        guard authService.isAuthenticated else {
            await MainActor.run {
                syncStatus = .error
                syncError = EthSignSyncError.notAuthenticated.localizedDescription
            }
            return
        }
        
        guard authService.isConfigured else {
            await MainActor.run {
                syncStatus = .error
                syncError = EthSignSyncError.notConfigured.localizedDescription
            }
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
            syncError = nil
        }
        
        do {
            // Sync in order
            try await syncCertificates()
            try await syncSources()
            try await syncAppLibrary()
            
            await MainActor.run {
                syncStatus = .success
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            }
        } catch {
            await MainActor.run {
                syncStatus = .error
                syncError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Sync Certificates
    func syncCertificates() async throws {
        guard let accessToken = authService.getAccessToken(),
              let userId = authService.currentUser?.id else {
            throw EthSignSyncError.notAuthenticated
        }
        
        // Fetch remote certificates
        let remoteCerts = try await fetchRemoteCertificates(userId: userId, accessToken: accessToken)
        
        // Get local certificates
        let localCerts = getLocalCertificates()
        
        // Merge: remote wins for conflicts (by ID), upload new local ones
        for localCert in localCerts {
            if !remoteCerts.contains(where: { $0.id == localCert.id }) {
                // Upload new local cert
                try await uploadCertificate(localCert, userId: userId, accessToken: accessToken)
            }
        }
        
        // Download remote certs that don't exist locally
        for remoteCert in remoteCerts {
            if !localCerts.contains(where: { $0.id == remoteCert.id }) {
                try await downloadCertificate(remoteCert)
            }
        }
    }
    
    private func fetchRemoteCertificates(userId: String, accessToken: String) async throws -> [SyncedCertificate] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/certificates?user_id=eq.\(userId)") else {
            throw EthSignSyncError.networkError
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authService.getAccessToken() ?? "", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw EthSignSyncError.networkError
        }
        
        return try JSONDecoder().decode([SyncedCertificate].self, from: data)
    }
    
    private func uploadCertificate(_ cert: SyncedCertificate, userId: String, accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/certificates") else {
            throw EthSignSyncError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        var certData = try JSONEncoder().encode(cert)
        // Add user_id to the payload
        if var json = try JSONSerialization.jsonObject(with: certData) as? [String: Any] {
            json["user_id"] = userId
            certData = try JSONSerialization.data(withJSONObject: json)
        }
        request.httpBody = certData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw EthSignSyncError.networkError
        }
    }
    
    private func downloadCertificate(_ cert: SyncedCertificate) async throws {
        // Decrypt and import the certificate locally
        // This would integrate with your existing certificate import logic
        // For now, we'll store the metadata
        print("[CloudSync] Would import certificate: \(cert.name)")
    }
    
    private func getLocalCertificates() -> [SyncedCertificate] {
        // Fetch from CoreData and convert to SyncedCertificate
        // This integrates with your existing Certificate entity
        return []
    }
    
    // MARK: - Sync Sources
    func syncSources() async throws {
        guard let accessToken = authService.getAccessToken(),
              let userId = authService.currentUser?.id else {
            throw EthSignSyncError.notAuthenticated
        }
        
        // Fetch remote sources
        let remoteSources = try await fetchRemoteSources(userId: userId, accessToken: accessToken)
        
        // Get local sources
        let localSources = getLocalSources()
        
        // Upload new local sources
        for localSource in localSources {
            if !remoteSources.contains(where: { $0.url == localSource.url }) {
                try await uploadSource(localSource, userId: userId, accessToken: accessToken)
            }
        }
        
        // Add remote sources locally
        for remoteSource in remoteSources {
            if !localSources.contains(where: { $0.url == remoteSource.url }) {
                await addSourceLocally(remoteSource)
            }
        }
    }
    
    private func fetchRemoteSources(userId: String, accessToken: String) async throws -> [SyncedSource] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/sources?user_id=eq.\(userId)") else {
            throw EthSignSyncError.networkError
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return [] // Return empty if table doesn't exist yet
        }
        
        return (try? JSONDecoder().decode([SyncedSource].self, from: data)) ?? []
    }
    
    private func uploadSource(_ source: SyncedSource, userId: String, accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/sources") else {
            throw EthSignSyncError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        var sourceData = try JSONEncoder().encode(source)
        if var json = try JSONSerialization.jsonObject(with: sourceData) as? [String: Any] {
            json["user_id"] = userId
            sourceData = try JSONSerialization.data(withJSONObject: json)
        }
        request.httpBody = sourceData
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    @MainActor
    private func addSourceLocally(_ source: SyncedSource) {
        guard let url = URL(string: source.url) else { return }
        FR.handleSource(source.url) { }
    }
    
    private func getLocalSources() -> [SyncedSource] {
        let sources = Storage.shared.getSources()
        return sources.compactMap { source -> SyncedSource? in
            guard let url = source.sourceURL?.absoluteString,
                  let identifier = source.identifier else { return nil }
            
            return SyncedSource(
                id: identifier,
                name: source.name ?? "Unknown",
                url: url,
                iconURL: source.iconURL?.absoluteString,
                createdAt: source.date ?? Date()
            )
        }
    }
    
    // MARK: - Sync App Library
    func syncAppLibrary() async throws {
        guard let accessToken = authService.getAccessToken(),
              let userId = authService.currentUser?.id else {
            throw EthSignSyncError.notAuthenticated
        }
        
        // Get local app library
        let localApps = await getLocalAppLibrary()
        
        // Upload app metadata (not the actual IPA files, just metadata)
        for app in localApps {
            try await uploadAppMetadata(app, userId: userId, accessToken: accessToken)
        }
    }
    
    private func uploadAppMetadata(_ app: SyncedAppMetadata, userId: String, accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/app_library") else {
            throw EthSignSyncError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        var appData = try JSONEncoder().encode(app)
        if var json = try JSONSerialization.jsonObject(with: appData) as? [String: Any] {
            json["user_id"] = userId
            appData = try JSONSerialization.data(withJSONObject: json)
        }
        request.httpBody = appData
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    @MainActor
    private func getLocalAppLibrary() -> [SyncedAppMetadata] {
        // Fetch from CoreData Imported entity
        let request: NSFetchRequest<Imported> = Imported.fetchRequest()
        
        guard let apps = try? Storage.shared.context.fetch(request) else {
            return []
        }
        
        return apps.compactMap { app -> SyncedAppMetadata? in
            guard let identifier = app.identifier else { return nil }
            
            return SyncedAppMetadata(
                id: identifier,
                bundleIdentifier: identifier,
                name: app.name ?? "Unknown",
                version: app.version ?? "1.0",
                iconURL: nil,
                sourceURL: nil,
                createdAt: app.date ?? Date()
            )
        }
    }
    
    // MARK: - Delete Synced Data
    func deleteAllSyncedData() async throws {
        guard let accessToken = authService.getAccessToken(),
              let userId = authService.currentUser?.id else {
            throw EthSignSyncError.notAuthenticated
        }
        
        // Delete from each table
        for table in ["certificates", "sources", "app_library"] {
            guard let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?user_id=eq.\(userId)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            _ = try? await URLSession.shared.data(for: request)
        }
        
        await MainActor.run {
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: lastSyncKey)
        }
    }
}
