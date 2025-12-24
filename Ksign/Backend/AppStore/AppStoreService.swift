//
//  AppStoreService.swift
//  SwiftSigner Pro
//
//  App Store integration service for importing and downgrading apps
//  Adapted from PancakeStore by Mineek
//

import Foundation
import CommonCrypto
import SwiftUI

// MARK: - SHA1 Helper
class SHA1Helper {
    static func hash(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
}

// MARK: - App Store Search Result
struct AppStoreSearchResult: Identifiable, Codable, Equatable {
    let trackId: Int
    let trackName: String
    let bundleId: String
    let artworkUrl100: String?
    let artworkUrl512: String?
    let version: String
    let fileSizeBytes: String?
    let releaseDate: String?
    let sellerName: String?
    let description: String?
    let primaryGenreName: String?
    let averageUserRating: Double?
    let userRatingCount: Int?
    
    var id: Int { trackId }
    
    var iconURL: URL? {
        if let artwork = artworkUrl512 ?? artworkUrl100 {
            return URL(string: artwork)
        }
        return nil
    }
    
    var appStoreLink: String {
        "https://apps.apple.com/app/id\(trackId)"
    }
    
    var fileSizeFormatted: String {
        guard let bytes = fileSizeBytes, let size = Int64(bytes) else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - App Store Version Info
struct AppStoreVersionInfo: Identifiable {
    let versionId: String
    let bundleVersion: String
    
    var id: String { versionId }
}

// MARK: - App Store Store Client
class AppStoreClient: ObservableObject {
    static let shared = AppStoreClient()
    
    private var session: URLSession
    private var appleId: String = ""
    private var password: String = ""
    private var guid: String?
    private(set) var accountName: String?
    private var authHeaders: [String: String]?
    private var authCookies: [HTTPCookie]?
    
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var needs2FA: Bool = false
    @Published var authError: String?
    
    init() {
        session = URLSession.shared
        // Try to load existing auth
        isAuthenticated = tryLoadAuthInfo()
    }
    
    // MARK: - GUID Generation
    private func generateGuid(appleId: String) -> String {
        let DEFAULT_GUID = "000C2941396B"
        let GUID_DEFAULT_PREFIX = 2
        let GUID_SEED = "CAFEBABE"
        let GUID_POS = 10
        
        let h = SHA1Helper.hash((GUID_SEED + appleId + GUID_SEED).data(using: .utf8)!).map { String(format: "%02x", $0) }.joined()
        let defaultPart = String(DEFAULT_GUID.prefix(GUID_DEFAULT_PREFIX))
        let hashPart = String(h.dropFirst(GUID_POS).prefix(DEFAULT_GUID.count - GUID_DEFAULT_PREFIX))
        return (defaultPart + hashPart).uppercased()
    }
    
    // MARK: - Auth Info Persistence
    private func saveAuthInfo() {
        guard let cookies = authCookies else { return }
        
        // Use NSKeyedArchiver like PancakeStore
        let authCookiesData = NSKeyedArchiver.archivedData(withRootObject: cookies)
        let authCookiesBase64 = authCookiesData.base64EncodedString()
        
        let out: [String: Any] = [
            "appleId": appleId,
            "password": password,
            "guid": guid ?? "",
            "accountName": accountName ?? "",
            "authHeaders": authHeaders ?? [:],
            "authCookies": authCookiesBase64
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: out, options: []) {
            let base64 = data.base64EncodedString()
            UserDefaults.standard.set(base64, forKey: "AppStoreAuthInfo")
        }
    }
    
    private func tryLoadAuthInfo() -> Bool {
        guard let base64 = UserDefaults.standard.string(forKey: "AppStoreAuthInfo"),
              let data = Data(base64Encoded: base64),
              let out = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return false
        }
        
        appleId = out["appleId"] as? String ?? ""
        password = out["password"] as? String ?? ""
        guid = out["guid"] as? String
        accountName = out["accountName"] as? String
        authHeaders = out["authHeaders"] as? [String: String]
        
        // Use NSKeyedUnarchiver like PancakeStore
        if let authCookiesBase64 = out["authCookies"] as? String,
           let authCookiesData = Data(base64Encoded: authCookiesBase64) {
            authCookies = NSKeyedUnarchiver.unarchiveObject(with: authCookiesData) as? [HTTPCookie]
        }
        
        return authHeaders != nil
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "AppStoreAuthInfo")
        appleId = ""
        password = ""
        guid = nil
        accountName = nil
        authHeaders = nil
        authCookies = nil
        isAuthenticated = false
        needs2FA = false
    }
    
    // MARK: - Authentication (matches PancakeStore logic)
    func authenticate(email: String, password: String) async -> Bool {
        await MainActor.run {
            isAuthenticating = true
            authError = nil
        }
        
        self.appleId = email
        self.password = password
        
        if self.guid == nil {
            self.guid = generateGuid(appleId: email)
        }
        
        var req: [String: String] = [
            "appleId": email,
            "password": password,
            "guid": guid!,
            "rmp": "0",
            "why": "signIn"
        ]
        
        var authUrl = URL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate")!
        
        var success = false
        var errorMessage: String?
        
        for attempt in 1...4 {
            req["attempt"] = String(attempt)
            
            var request = URLRequest(url: authUrl)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
                "Accept": "*/*",
                "Content-Type": "application/x-www-form-urlencoded",
                "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: req, options: [])
            
            do {
                let (data, response) = try await session.data(for: request)
                
                // Handle URL redirect - update for next attempt
                if let httpResponse = response as? HTTPURLResponse {
                    print("[AppStoreService] Response URL: \(httpResponse.url?.absoluteString ?? "nil"), Status: \(httpResponse.statusCode)")
                    if let newURL = httpResponse.url {
                        authUrl = newURL
                    }
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[AppStoreService] Raw response (\(data.count) bytes): \(responseString.prefix(500))")
                }
                
                guard !data.isEmpty else {
                    errorMessage = "Empty response from server"
                    continue
                }
                
                // Try to parse as PropertyList
                if let resp = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    if resp["m-allowed"] as? Bool == true {
                        print("[AppStoreService] Authentication successful")
                        
                        if let downloadQueueInfo = resp["download-queue-info"] as? [String: Any],
                           let dsid = downloadQueueInfo["dsid"] as? Int,
                           let httpResponse = response as? HTTPURLResponse,
                           let storeFront = httpResponse.value(forHTTPHeaderField: "x-set-apple-store-front"),
                           let passwordToken = resp["passwordToken"] as? String {
                            
                            print("[AppStoreService] Store front: \(storeFront)")
                            
                            self.authHeaders = [
                                "X-Dsid": String(dsid),
                                "iCloud-Dsid": String(dsid),
                                "X-Apple-Store-Front": storeFront,
                                "X-Token": passwordToken
                            ]
                            self.authCookies = session.configuration.httpCookieStorage?.cookies
                            
                            if let accountInfo = resp["accountInfo"] as? [String: Any],
                               let address = accountInfo["address"] as? [String: String] {
                                self.accountName = (address["firstName"] ?? "") + " " + (address["lastName"] ?? "")
                            }
                            
                            self.saveAuthInfo()
                            success = true
                            break
                        }
                    } else {
                        let message = resp["customerMessage"] as? String ?? "Authentication failed"
                        print("[AppStoreService] Auth failed: \(message)")
                        errorMessage = message
                    }
                } else if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Try JSON fallback
                    print("[AppStoreService] Got JSON response: \(json)")
                    if let customerMessage = json["customerMessage"] as? String {
                        errorMessage = customerMessage
                    }
                } else {
                    // Unknown format
                    let responseStr = String(data: data, encoding: .utf8) ?? "unknown"
                    errorMessage = "Unknown response format: \(responseStr.prefix(100))"
                }
                
            } catch {
                print("[AppStoreService] Request error: \(error)")
                errorMessage = "Request error: \(error.localizedDescription)"
            }
            
            // For first attempt without 2FA code, break to let user enter code
            if attempt == 1 && password.count < 30 {
                // Likely first attempt without 2FA code appended
                break
            }
        }
        
        await MainActor.run {
            isAuthenticated = success
            isAuthenticating = false
            if let msg = errorMessage {
                authError = msg
            }
            if !success {
                needs2FA = true
            }
        }
        
        return success
    }
    
    // MARK: - iTunes Search API
    func searchApps(query: String, limit: Int = 25, offset: Int = 0) async -> [AppStoreSearchResult] {
        // iTunes API doesn't support offset directly, so we request more and skip
        let requestLimit = min(limit + offset, 200) // Max 200
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&entity=software&limit=\(requestLimit)") else {
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
            
            // Skip offset and take limit
            let results = Array(response.results.dropFirst(offset).prefix(limit))
            return results
        } catch {
            print("[AppStoreService] Search error: \(error)")
            return []
        }
    }
    
    func lookupApp(bundleId: String) async -> AppStoreSearchResult? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
            return response.results.first
        } catch {
            print("[AppStoreService] Lookup error: \(error)")
            return nil
        }
    }
    
    func lookupApp(appId: String) async -> AppStoreSearchResult? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
            return response.results.first
        } catch {
            print("[AppStoreService] Lookup error: \(error)")
            return nil
        }
    }
    
    // MARK: - Get App Version List
    func getVersionList(appId: String) async -> [AppStoreVersionInfo] {
        guard isAuthenticated, let authHeaders = authHeaders, let guid = guid else {
            print("[AppStoreService] Not authenticated")
            return []
        }
        
        // Try to get version list from external API first (has more versions)
        let serverURL = "https://apis.bilin.eu.org/history/\(appId)"
        guard let url = URL(string: serverURL) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let versionData = json["data"] as? [[String: Any]] {
                return versionData.compactMap { item in
                    guard let externalId = item["external_identifier"],
                          let bundleVersion = item["bundle_version"] as? String else {
                        return nil
                    }
                    return AppStoreVersionInfo(versionId: "\(externalId)", bundleVersion: bundleVersion)
                }
            }
        } catch {
            print("[AppStoreService] Failed to get versions from server: \(error)")
        }
        
        // Fallback to Apple's API
        return await getVersionListFromApple(appId: appId)
    }
    
    private func getVersionListFromApple(appId: String) async -> [AppStoreVersionInfo] {
        guard let authHeaders = authHeaders, let guid = guid else { return [] }
        
        let req: [String: Any] = [
            "creditDisplay": "",
            "guid": guid,
            "salableAdamId": appId
        ]
        
        guard let url = URL(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(guid)") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: req, options: [])
        
        for (key, value) in authHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if let cookies = authCookies {
            session.configuration.httpCookieStorage?.setCookies(cookies, for: url, mainDocumentURL: nil)
        }
        
        do {
            let (data, _) = try await session.data(for: request)
            if let resp = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let songList = resp["songList"] as? [[String: Any]],
               let downInfo = songList.first,
               let metadata = downInfo["metadata"] as? [String: Any],
               let appVerIds = metadata["softwareVersionExternalIdentifiers"] as? [Int] {
                return appVerIds.map { AppStoreVersionInfo(versionId: "\($0)", bundleVersion: "Version \($0)") }
            }
        } catch {
            print("[AppStoreService] Failed to get versions: \(error)")
        }
        
        return []
    }
    
    // MARK: - Download IPA
    func downloadIPA(appId: String, versionId: String? = nil) async -> URL? {
        guard isAuthenticated, let authHeaders = authHeaders, let guid = guid else {
            print("[AppStoreService] Not authenticated")
            return nil
        }
        
        var req: [String: Any] = [
            "creditDisplay": "",
            "guid": guid,
            "salableAdamId": appId
        ]
        
        if let verId = versionId {
            req["externalVersionId"] = verId
        }
        
        guard let url = URL(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(guid)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: req, options: [])
        
        for (key, value) in authHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if let cookies = authCookies {
            session.configuration.httpCookieStorage?.setCookies(cookies, for: url, mainDocumentURL: nil)
        }
        
        do {
            let (data, _) = try await session.data(for: request)
            
            if let resp = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let songList = resp["songList"] as? [[String: Any]],
               let downInfo = songList.first,
               let downloadURL = downInfo["URL"] as? String {
                
                // Download the IPA
                guard let ipaURL = URL(string: downloadURL) else { return nil }
                
                let tempDir = FileManager.default.temporaryDirectory
                let ipaPath = tempDir.appendingPathComponent("downloaded_\(appId).ipa")
                
                // Remove existing file
                try? FileManager.default.removeItem(at: ipaPath)
                
                let (ipaData, _) = try await URLSession.shared.data(from: ipaURL)
                try ipaData.write(to: ipaPath)
                
                return ipaPath
            }
        } catch {
            print("[AppStoreService] Download failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Methods Using Stored App Store Link
    
    /// Gets the stored App Store link for a bundle ID
    func getStoredAppStoreLink(for bundleId: String) -> String? {
        return UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)")
    }
    
    /// Gets the app ID from a stored App Store link for a bundle ID
    func getStoredAppId(for bundleId: String) -> String? {
        guard let link = getStoredAppStoreLink(for: bundleId) else { return nil }
        return link.extractedAppId
    }
    
    /// Looks up an app using the stored App Store link (if available) or falls back to bundle ID lookup
    func lookupAppUsingStoredLink(bundleId: String) async -> AppStoreSearchResult? {
        // First try to use stored link
        if let storedAppId = getStoredAppId(for: bundleId) {
            print("[AppStoreService] Using stored App Store link with ID: \(storedAppId)")
            if let result = await lookupApp(appId: storedAppId) {
                return result
            }
        }
        
        // Fall back to bundle ID lookup
        print("[AppStoreService] Falling back to bundle ID lookup: \(bundleId)")
        return await lookupApp(bundleId: bundleId)
    }
    
    /// Gets version list using the stored App Store link (if available) or falls back to bundle ID lookup
    func getVersionListUsingStoredLink(bundleId: String) async -> [AppStoreVersionInfo] {
        // First try to use stored link
        if let storedAppId = getStoredAppId(for: bundleId) {
            print("[AppStoreService] Using stored App Store link for versions with ID: \(storedAppId)")
            return await getVersionList(appId: storedAppId)
        }
        
        // Need to look up the app first to get its ID
        if let appInfo = await lookupApp(bundleId: bundleId) {
            print("[AppStoreService] Looked up app ID: \(appInfo.trackId)")
            return await getVersionList(appId: String(appInfo.trackId))
        }
        
        print("[AppStoreService] Could not find app for bundle ID: \(bundleId)")
        return []
    }
    
    /// Downloads an IPA using the stored App Store link (if available) or falls back to bundle ID lookup
    func downloadIPAUsingStoredLink(bundleId: String, versionId: String? = nil) async -> URL? {
        // First try to use stored link
        if let storedAppId = getStoredAppId(for: bundleId) {
            print("[AppStoreService] Using stored App Store link for download with ID: \(storedAppId)")
            return await downloadIPA(appId: storedAppId, versionId: versionId)
        }
        
        // Need to look up the app first to get its ID
        if let appInfo = await lookupApp(bundleId: bundleId) {
            print("[AppStoreService] Looked up app ID for download: \(appInfo.trackId)")
            // Store the link for future use
            UserDefaults.standard.set(appInfo.appStoreLink, forKey: "AppStoreLink_\(bundleId)")
            return await downloadIPA(appId: String(appInfo.trackId), versionId: versionId)
        }
        
        print("[AppStoreService] Could not find app for bundle ID: \(bundleId)")
        return nil
    }
    
    /// Stores an App Store link for a bundle ID
    func storeAppStoreLink(_ link: String, for bundleId: String) {
        UserDefaults.standard.set(link, forKey: "AppStoreLink_\(bundleId)")
        print("[AppStoreService] Stored App Store link for \(bundleId): \(link)")
    }
    
    /// Removes the stored App Store link for a bundle ID
    func removeStoredAppStoreLink(for bundleId: String) {
        UserDefaults.standard.removeObject(forKey: "AppStoreLink_\(bundleId)")
        print("[AppStoreService] Removed stored App Store link for \(bundleId)")
    }
}

// MARK: - iTunes Search Response
private struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [AppStoreSearchResult]
}

// MARK: - App ID Parsing Helper
extension String {
    /// Extracts app ID from an App Store link
    var extractedAppId: String? {
        // Handle URLs like https://apps.apple.com/app/id123456789
        if let range = self.range(of: "id", options: .caseInsensitive) {
            var appId = String(self[range.upperBound...])
            // Remove any non-numeric characters after the ID
            var numericId = ""
            for char in appId {
                if char.isNumber {
                    numericId.append(char)
                } else {
                    break
                }
            }
            if !numericId.isEmpty {
                return numericId
            }
        }
        return nil
    }
}
