//
//  UDIDVerification.swift
//  EthSign
//
//  Created for device whitelisting verification.
//

import SwiftUI
import UIKit

// MARK: - UDID Manager
class UDIDManager: ObservableObject {
    static let shared = UDIDManager()
    
    // Whitelisted UDIDs - only these devices can use the app
    private let whitelistedUDIDs: [String] = [
        "00008140-000429001142801C"
    ]
    
    @Published var isVerified: Bool = false
    @Published var showVerificationSheet: Bool = false
    @Published var showFailureAlert: Bool = false
    @Published var enteredUDID: String = ""
    @Published var failureMessage: String = ""
    
    private let udidStorageKey = "SwiftSignerPro.verifiedUDID"
    
    private init() {
        // UDID verification is disabled - all devices are allowed
        isVerified = true
    }
    
    // MARK: - Automatic Device ID Check
    func getDeviceIdentifier() -> String? {
        // Note: This returns identifierForVendor, not the true UDID
        // The true UDID requires special entitlements or manual entry
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    // MARK: - Verification Methods
    func checkVerification() {
        // UDID verification is disabled - always verified
        isVerified = true
        // Don't show verification sheet
    }
    
    func verifyUDID(_ udid: String) -> Bool {
        let cleanUDID = udid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if whitelistedUDIDs.contains(cleanUDID) {
            // Store verified UDID
            UserDefaults.standard.set(cleanUDID, forKey: udidStorageKey)
            isVerified = true
            showVerificationSheet = false
            
            // Install bundled certificates for this UDID
            installBundledCertificates(for: cleanUDID)
            
            return true
        } else {
            failureMessage = "UDID '\(cleanUDID)' is not authorized to use this app.\n\nPlease contact the developer for access."
            showFailureAlert = true
            return false
        }
    }
    
    // MARK: - Bundled Certificates
    
    /// Certificate bundles for whitelisted UDIDs
    private struct BundledCertificate {
        let name: String
        let developmentZipPath: String
        let distributionZipPath: String
        let password: String
    }
    
    private let bundledCertificates: [String: BundledCertificate] = [
        "00008140-000429001142801C": BundledCertificate(
            name: "EthFR",
            developmentZipPath: "cert_00008140-000429001142801C_development",
            distributionZipPath: "cert_00008140-000429001142801C_distribution",
            password: "kravasign"
        )
    ]
    
    private let installedCertsKey = "SwiftSignerPro.installedBundledCerts"
    
    private func installBundledCertificates(for udid: String) {
        guard let certBundle = bundledCertificates[udid] else { return }
        
        // Check if already installed
        let installedCerts = UserDefaults.standard.stringArray(forKey: installedCertsKey) ?? []
        
        // Install Development Certificate
        let devCertId = "\(udid)_dev"
        if !installedCerts.contains(devCertId) {
            installCertificateFromBundle(
                zipName: certBundle.developmentZipPath,
                certificateName: "\(certBundle.name)'s Dev Cert",
                password: certBundle.password,
                certId: devCertId
            )
        }
        
        // Install Distribution Certificate
        let distCertId = "\(udid)_dist"
        if !installedCerts.contains(distCertId) {
            installCertificateFromBundle(
                zipName: certBundle.distributionZipPath,
                certificateName: "\(certBundle.name)'s Dist Cert",
                password: certBundle.password,
                certId: distCertId
            )
        }
    }
    
    private func installCertificateFromBundle(zipName: String, certificateName: String, password: String, certId: String) {
        // Try to find the zip in the bundle
        guard let zipURL = Bundle.main.url(forResource: zipName, withExtension: "zip") else {
            print("⚠️ Certificate bundle not found: \(zipName).zip")
            return
        }
        
        // Create temp directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Extract the zip file
            let extractedFiles = try extractZipFile(at: zipURL, to: tempDir)
            
            // Find p12 and mobileprovision files
            var p12URL: URL?
            var provisionURL: URL?
            
            for file in extractedFiles {
                if file.pathExtension.lowercased() == "p12" {
                    p12URL = file
                } else if file.pathExtension.lowercased() == "mobileprovision" {
                    provisionURL = file
                }
            }
            
            guard let p12 = p12URL, let provision = provisionURL else {
                print("⚠️ Certificate files not found in zip: \(zipName)")
                return
            }
            
            // Install the certificate using FR handler
            FR.handleCertificateFiles(
                p12URL: p12,
                provisionURL: provision,
                p12Password: password,
                certificateName: certificateName
            ) { error in
                if error == nil {
                    // Mark as installed
                    var installedCerts = UserDefaults.standard.stringArray(forKey: self.installedCertsKey) ?? []
                    installedCerts.append(certId)
                    UserDefaults.standard.set(installedCerts, forKey: self.installedCertsKey)
                    print("✅ Successfully installed certificate: \(certificateName)")
                } else {
                    print("❌ Failed to install certificate: \(certificateName) - \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            // Cleanup temp directory
            try? FileManager.default.removeItem(at: tempDir)
            
        } catch {
            print("❌ Error extracting certificate zip: \(error)")
            try? FileManager.default.removeItem(at: tempDir)
        }
    }
    
    private func extractZipFile(at sourceURL: URL, to destinationURL: URL) throws -> [URL] {
        var extractedFiles: [URL] = []
        let fileManager = FileManager.default
        
        // Use iOS's built-in zip extraction via file coordinator
        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator()
        
        // Use the decompression option to extract the zip
        coordinator.coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &coordinatorError) { tempURL in
            // The tempURL is already unzipped when using .forUploading option on a zip file
            // Copy contents to our destination
            do {
                let contents = try fileManager.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil)
                for item in contents {
                    let destItem = destinationURL.appendingPathComponent(item.lastPathComponent)
                    try? fileManager.copyItem(at: item, to: destItem)
                    extractedFiles.append(destItem)
                }
            } catch {
                print("Error reading temp directory: \(error)")
            }
        }
        
        if let error = coordinatorError {
            print("Coordinator error: \(error)")
        }
        
        // If no files extracted via coordinator, try direct extraction approach
        if extractedFiles.isEmpty {
            // Try using Archive framework if available (iOS 16+)
            if #available(iOS 16.0, *) {
                do {
                    // Read the zip data
                    let zipData = try Data(contentsOf: sourceURL)
                    
                    // Create a temporary file for the zip
                    let tempZipPath = destinationURL.appendingPathComponent("temp.zip")
                    try zipData.write(to: tempZipPath)
                    
                    // Scan the bundle for matching cert files
                    let certName = sourceURL.deletingPathExtension().lastPathComponent
                    let bundlePath = Bundle.main.bundlePath
                    
                    if let bundleContents = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
                        for file in bundleContents {
                            // Check for matching p12 or mobileprovision files
                            if file.lowercased().contains(certName.lowercased()) ||
                               file.hasSuffix(".p12") || file.hasSuffix(".mobileprovision") {
                                let sourcePath = URL(fileURLWithPath: bundlePath).appendingPathComponent(file)
                                let destPath = destinationURL.appendingPathComponent(file)
                                try? fileManager.copyItem(at: sourcePath, to: destPath)
                                extractedFiles.append(destPath)
                            }
                        }
                    }
                    
                    // Clean up temp zip
                    try? fileManager.removeItem(at: tempZipPath)
                } catch {
                    print("Archive extraction error: \(error)")
                }
            }
        }
        
        // Final fallback: Look for pre-extracted files in bundle Resources folder
        if extractedFiles.isEmpty {
            let certName = sourceURL.deletingPathExtension().lastPathComponent
            
            // Check in the bundle's resource path
            if let resourcePath = Bundle.main.resourcePath {
                let resourceURL = URL(fileURLWithPath: resourcePath)
                
                if let contents = try? fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) {
                    for item in contents {
                        let itemName = item.lastPathComponent.lowercased()
                        let certNameLower = certName.lowercased()
                        
                        // Match files that belong to this certificate
                        if itemName.contains(certNameLower) ||
                           (itemName.hasSuffix(".p12") && itemName.contains("ethfr")) ||
                           (itemName.hasSuffix(".mobileprovision") && itemName.contains("ethfr")) {
                            let destPath = destinationURL.appendingPathComponent(item.lastPathComponent)
                            try? fileManager.copyItem(at: item, to: destPath)
                            extractedFiles.append(destPath)
                        }
                    }
                }
            }
            
            // Also check for direct bundle resources with the cert name
            if let p12URL = Bundle.main.url(forResource: certName, withExtension: "p12") {
                let destP12 = destinationURL.appendingPathComponent(p12URL.lastPathComponent)
                try? fileManager.copyItem(at: p12URL, to: destP12)
                extractedFiles.append(destP12)
            }
            
            if let provisionURL = Bundle.main.url(forResource: certName, withExtension: "mobileprovision") {
                let destProvision = destinationURL.appendingPathComponent(provisionURL.lastPathComponent)
                try? fileManager.copyItem(at: provisionURL, to: destProvision)
                extractedFiles.append(destProvision)
            }
        }
        
        // Scan destination for any extracted files
        if extractedFiles.isEmpty {
            if let destContents = try? fileManager.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil) {
                for item in destContents {
                    let ext = item.pathExtension.lowercased()
                    if ext == "p12" || ext == "mobileprovision" {
                        extractedFiles.append(item)
                    }
                }
            }
        }
        
        return extractedFiles
    }
    
    func resetVerification() {
        UserDefaults.standard.removeObject(forKey: udidStorageKey)
        isVerified = false
        enteredUDID = ""
    }
}

// MARK: - UDID Verification View
struct UDIDVerificationView: View {
    @ObservedObject var udidManager: UDIDManager
    @State private var inputUDID: String = ""
    @State private var showInfo: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Device Verification Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please enter your device UDID to verify access.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // UDID Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device UDID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("00008140-XXXXXXXXXXXX", text: $inputUDID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
                .padding(.horizontal, 32)
                
                // How to find UDID
                Button {
                    showInfo.toggle()
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("How to find your UDID?")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                if showInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To find your device UDID:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Connect your device to a Mac")
                            Text("2. Open Finder (macOS Catalina+) or iTunes")
                            Text("3. Click on your device")
                            Text("4. Click on the device info until UDID appears")
                            Text("5. Copy the UDID and paste it here")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Verify Button
                Button {
                    _ = udidManager.verifyUDID(inputUDID)
                } label: {
                    Text("Verify Device")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: inputUDID.isEmpty ? [.gray] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .disabled(inputUDID.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
    }
}

// MARK: - UDID Failure View
struct UDIDFailureView: View {
    @ObservedObject var udidManager: UDIDManager
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error Icon
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Access Denied")
                .font(.title)
                .fontWeight(.bold)
            
            Text(udidManager.failureMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Manual Close Button
            Button {
                onClose()
            } label: {
                Text("Close App")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    UDIDVerificationView(udidManager: UDIDManager.shared)
}
