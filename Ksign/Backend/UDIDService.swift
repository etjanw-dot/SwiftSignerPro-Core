//
//  UDIDService.swift
//  EthSign
//
//  Centralized UDID management service for retrieving and storing device UDIDs
//

import SwiftUI
import UIKit

/// Centralized UDID Service for managing device identifier retrieval
/// This service handles:
/// - Opening the UDID retrieval website
/// - Saving and retrieving the verified UDID
/// - Checking UDID verification status
final class UDIDService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = UDIDService()
    
    // MARK: - Constants
    
    /// The URL scheme for the app
    static let appScheme = "ksign"
    
    /// The UserDefaults key for storing the verified UDID
    static let udidStorageKey = "SwiftSignerPro.verifiedUDID"
    
    /// The URL of the UDID retrieval website
    /// Note: iOS 17+ requires signed profiles. Using alternative method
    /// that shows UDID for user to copy, then redirects back to app
    static let udidWebsiteURL = "https://udid.io"
    
    // MARK: - Published Properties
    
    @Published var currentUDID: String?
    @Published var isVerified: Bool = false
    @Published var showUDIDPrompt: Bool = false
    
    /// Key for tracking if user has been prompted for UDID
    private static let hasPromptedForUDIDKey = "SwiftSignerPro.hasPromptedForUDID"
    
    // MARK: - Initialization
    
    private init() {
        loadStoredUDID()
    }
    
    // MARK: - Auto-Prompt Methods
    
    /// Check if we should prompt the user to fetch their UDID (on first launch without verified UDID)
    var shouldPromptForUDID: Bool {
        return !hasVerifiedUDID() && !UserDefaults.standard.bool(forKey: Self.hasPromptedForUDIDKey)
    }
    
    /// Call this on app launch to check and prompt for UDID if needed
    func checkAndPromptForUDID() {
        if shouldPromptForUDID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showUDIDPrompt = true
            }
        }
    }
    
    /// Mark that we've prompted the user (so we don't ask every launch)
    func markPromptShown() {
        UserDefaults.standard.set(true, forKey: Self.hasPromptedForUDIDKey)
    }
    
    /// Reset the prompt flag (for testing or settings)
    func resetPromptFlag() {
        UserDefaults.standard.removeObject(forKey: Self.hasPromptedForUDIDKey)
    }
    
    // MARK: - Public Methods
    
    /// Opens the UDID retrieval website in Safari
    /// The website uses a configuration profile to get the true device UDID
    /// and returns it to the app via the ksign://udid?value=XXXX URL scheme
    func openUDIDWebsite() {
        guard let url = URL(string: Self.udidWebsiteURL) else {
            print("❌ Invalid UDID website URL")
            return
        }
        
        UIApplication.shared.open(url) { success in
            if success {
                print("✅ Opened UDID website: \(Self.udidWebsiteURL)")
            } else {
                print("❌ Failed to open UDID website")
            }
        }
    }
    
    /// Saves the UDID received from the web callback
    /// - Parameter udid: The device UDID to save
    func saveUDID(_ udid: String) {
        let cleanUDID = udid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanUDID.isEmpty else { return }
        
        UserDefaults.standard.set(cleanUDID, forKey: Self.udidStorageKey)
        currentUDID = cleanUDID
        isVerified = true
        
        print("✅ UDID saved: \(cleanUDID)")
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .udidDidChange, object: cleanUDID)
    }
    
    /// Gets the current UDID (either verified or fallback to identifierForVendor)
    /// - Returns: The UDID string
    func getUDID() -> String {
        if let storedUDID = currentUDID {
            return storedUDID
        }
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    /// Checks if the user has a verified (real) UDID stored
    /// - Returns: True if a verified UDID exists
    func hasVerifiedUDID() -> Bool {
        return currentUDID != nil
    }
    
    /// Clears the stored UDID
    func clearUDID() {
        UserDefaults.standard.removeObject(forKey: Self.udidStorageKey)
        currentUDID = nil
        isVerified = false
        
        print("🗑️ UDID cleared")
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .udidDidChange, object: nil)
    }
    
    /// Copies the current UDID to clipboard
    /// - Returns: The UDID that was copied
    @discardableResult
    func copyUDIDToClipboard() -> String {
        let udid = getUDID()
        UIPasteboard.general.string = udid
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        return udid
    }
    
    // MARK: - Private Methods
    
    private func loadStoredUDID() {
        if let storedUDID = UserDefaults.standard.string(forKey: Self.udidStorageKey) {
            currentUDID = storedUDID
            isVerified = true
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let udidDidChange = Notification.Name("UDIDService.udidDidChange")
}

// MARK: - URL Handler Extension

extension UDIDService {
    
    /// Handles the ksign://udid?value=XXXX URL callback
    /// - Parameter url: The URL received from the web callback
    /// - Returns: True if the URL was handled successfully
    @discardableResult
    func handleUDIDCallback(url: URL) -> Bool {
        guard url.scheme == Self.appScheme,
              url.host == "udid" else {
            return false
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let udidParam = components.queryItems?.first(where: { $0.name == "value" })?.value else {
            print("❌ Missing UDID value in URL")
            return false
        }
        
        saveUDID(udidParam)
        
        // Show success alert
        DispatchQueue.main.async {
            UIAlertController.showAlertWithOk(
                title: "✅ " + String.localized("Success"),
                message: String.localized("Your device UDID has been saved successfully.") + "\n\n" + udidParam.uppercased()
            )
        }
        
        return true
    }
}

// MARK: - SwiftUI View Modifier

struct UDIDButtonModifier: ViewModifier {
    @StateObject private var udidService = UDIDService.shared
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .udidDidChange)) { notification in
                // UI will auto-update due to @StateObject
            }
    }
}

extension View {
    func udidAware() -> some View {
        modifier(UDIDButtonModifier())
    }
}
