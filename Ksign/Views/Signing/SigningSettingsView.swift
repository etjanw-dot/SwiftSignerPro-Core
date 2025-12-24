//
//  SigningSettingsView.swift
//  Ksign
//
//  Signing Settings with Installation Method, Button Type, Certificate Type, and Export options.
//

import SwiftUI
import NimbleViews

// MARK: - Installation Method
enum InstallationMethod: String, CaseIterable {
    case local = "Local"
    case remote = "Remote"
    case direct = "Direct"
    case itunes = "iTunes"
    
    var icon: String {
        switch self {
        case .local: return "house.fill"
        case .remote: return "cloud.fill"
        case .direct: return "arrow.down.circle.fill"
        case .itunes: return "music.note"
        }
    }
    
    var description: String {
        switch self {
        case .local: return "Fully local signing and install using localhost web server. iOS 17.7, AD Blockers, Anti-Revoke DNS, etc may cause issues."
        case .remote: return "Sign and install using remote server. Requires network connection."
        case .direct: return "Direct installation to device without web server."
        case .itunes: return "Export IPA for iTunes/Finder installation."
        }
    }
}

// MARK: - Install Button Type
enum InstallButtonType: String, CaseIterable {
    case swipe = "Swipe"
    case button = "Button"
    case auto = "Auto"
    
    var icon: String {
        switch self {
        case .swipe: return "hand.draw.fill"
        case .button: return "button.horizontal.fill"
        case .auto: return "arrow.triangle.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .swipe: return "Slide to install - requires swiping gesture to trigger installation"
        case .button: return "Tap to install - simple button press to start installation"
        case .auto: return "Auto install - automatically installs after signing completes"
        }
    }
}

// MARK: - Certificate Type
enum CertificateType: String, CaseIterable {
    case distribution = "Distribution"
    case development = "Development"
    case enterprise = "Enterprise"
    case adhoc = "Ad Hoc"
    
    var icon: String {
        switch self {
        case .distribution: return "shippingbox.fill"
        case .development: return "hammer.fill"
        case .enterprise: return "building.2.fill"
        case .adhoc: return "signature"
        }
    }
    
    var description: String {
        switch self {
        case .distribution: return "Distribution certificates support notifications and general app distribution"
        case .development: return "Development certificates for testing and debugging"
        case .enterprise: return "Enterprise certificates for internal company distribution"
        case .adhoc: return "Ad Hoc certificates for limited device distribution"
        }
    }
}

// MARK: - Signing Settings Manager
class SigningSettingsManager: ObservableObject {
    static let shared = SigningSettingsManager()
    
    @Published var installationMethod: InstallationMethod {
        didSet { save() }
    }
    @Published var installButtonType: InstallButtonType {
        didSet { save() }
    }
    @Published var certificateType: CertificateType {
        didSet { save() }
    }
    
    private let methodKey = "Ksign.signing.installationMethod"
    private let buttonTypeKey = "Ksign.signing.installButtonType"
    private let certTypeKey = "Ksign.signing.certificateType"
    
    private init() {
        let methodRaw = UserDefaults.standard.string(forKey: methodKey) ?? InstallationMethod.local.rawValue
        let buttonRaw = UserDefaults.standard.string(forKey: buttonTypeKey) ?? InstallButtonType.swipe.rawValue
        let certRaw = UserDefaults.standard.string(forKey: certTypeKey) ?? CertificateType.distribution.rawValue
        
        self.installationMethod = InstallationMethod(rawValue: methodRaw) ?? .local
        self.installButtonType = InstallButtonType(rawValue: buttonRaw) ?? .swipe
        self.certificateType = CertificateType(rawValue: certRaw) ?? .distribution
    }
    
    private func save() {
        UserDefaults.standard.set(installationMethod.rawValue, forKey: methodKey)
        UserDefaults.standard.set(installButtonType.rawValue, forKey: buttonTypeKey)
        UserDefaults.standard.set(certificateType.rawValue, forKey: certTypeKey)
    }
}

// MARK: - Signing Settings View
struct SigningSettingsView: View {
    @StateObject private var manager = SigningSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // For certificate export
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedCertForExport: CertificatePair?
    @State private var showExportSheet = false
    @State private var showExportActionSheet = false
    @State private var exportURL: URL?
    @State private var showCopiedAlert = false
    
    var body: some View {
        NBList(.localized("Signing")) {
            // Installation Method
            NBSection(.localized("Installation Method")) {
                Picker(selection: $manager.installationMethod) {
                    ForEach(InstallationMethod.allCases, id: \.self) { method in
                        Label(method.rawValue, systemImage: method.icon)
                            .tag(method)
                    }
                } label: {
                    Label {
                        Text(manager.installationMethod.rawValue)
                    } icon: {
                        Image(systemName: manager.installationMethod.icon)
                            .foregroundColor(.accentColor)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text(manager.installationMethod.description)
            }
            
            // Install Button Type
            NBSection(.localized("Install Button Type")) {
                Picker(selection: $manager.installButtonType) {
                    ForEach(InstallButtonType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                } label: {
                    Label {
                        Text(manager.installButtonType.rawValue)
                    } icon: {
                        Image(systemName: manager.installButtonType.icon)
                            .foregroundColor(.accentColor)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text(manager.installButtonType.description)
            }
            
            // Certificate Type
            NBSection(.localized("Certificate Type")) {
                Picker(selection: $manager.certificateType) {
                    ForEach(CertificateType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                } label: {
                    Label {
                        Text(manager.certificateType.rawValue)
                    } icon: {
                        Image(systemName: manager.certificateType.icon)
                            .foregroundColor(.accentColor)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text(manager.certificateType.description)
            }
            
            // Certificate Export
            NBSection(.localized("Certificate")) {
                // Show available certificates as list
                if certificates.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(.localized("No certificates imported"))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(certificates) { cert in
                        Button {
                            selectedCertForExport = cert
                        } label: {
                            HStack {
                                Image(systemName: selectedCertForExport?.uuid == cert.uuid ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedCertForExport?.uuid == cert.uuid ? .blue : .secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cert.nickname ?? "Unknown")
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    
                                    if let expiry = cert.expiration {
                                        Text(.localized("Expires: \(expiry.formatted(date: .abbreviated, time: .omitted))"))
                                            .font(.caption)
                                            .foregroundColor(expiry < Date() ? .red : .secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Export Options
            if selectedCertForExport != nil {
                NBSection(.localized("Export Options")) {
                    // Export as Package (ZIP)
                    Button {
                        showExportActionSheet = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Export Certificate"))
                                    .fontWeight(.medium)
                                Text(.localized("Choose package or individual files"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // Copy Password
                    Button {
                        copyPassword()
                    } label: {
                        Label {
                            Text(.localized("Copy password"))
                        } icon: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.accentColor)
                        }
                    }
                } footer: {
                    if let cert = selectedCertForExport {
                        let certName = cert.nickname ?? "Unknown"
                        Text(.localized("Selected: \(certName)"))
                    }
                }
            }
        }
        .confirmationDialog(.localized("Export Certificate"), isPresented: $showExportActionSheet) {
            Button(.localized("Export as Package (ZIP)")) {
                exportAsPackage()
            }
            Button(.localized("Export p12 only")) {
                exportP12()
            }
            Button(.localized("Export Provision only")) {
                exportProvision()
            }
            Button(.localized("Cancel"), role: .cancel) { }
        } message: {
            Text(.localized("Choose how to export the certificate files"))
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert(.localized("Copied!"), isPresented: $showCopiedAlert) {
            Button(.localized("OK")) { }
        } message: {
            Text(.localized("Password copied to clipboard."))
        }
        .onAppear {
            // Select first certificate by default if none selected
            if selectedCertForExport == nil && !certificates.isEmpty {
                selectedCertForExport = certificates.first
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func exportAsPackage() {
        guard let cert = selectedCertForExport else { return }
        
        let certName = cert.nickname ?? "certificate"
        let packageDir = FileManager.default.temporaryDirectory.appendingPathComponent(certName)
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(certName).zip")
        
        do {
            // Clean up old files
            try? FileManager.default.removeItem(at: packageDir)
            try? FileManager.default.removeItem(at: zipURL)
            
            // Create directory
            try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
            
            // Copy p12 file
            if let p12URL = Storage.shared.getFile(.certificate, from: cert) {
                try FileManager.default.copyItem(at: p12URL, to: packageDir.appendingPathComponent("\(certName).p12"))
            }
            
            // Copy provision file
            if let provisionURL = Storage.shared.getFile(.provision, from: cert) {
                try FileManager.default.copyItem(at: provisionURL, to: packageDir.appendingPathComponent("\(certName).mobileprovision"))
            }
            
            // Write password to text file
            if let password = cert.password {
                try password.write(to: packageDir.appendingPathComponent("password.txt"), atomically: true, encoding: .utf8)
            }
            
            // Create ZIP using FileManager coordination
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: packageDir, options: .forUploading, error: &error) { zipTempURL in
                try? FileManager.default.copyItem(at: zipTempURL, to: zipURL)
            }
            
            if error == nil && FileManager.default.fileExists(atPath: zipURL.path) {
                exportURL = zipURL
                showExportSheet = true
            } else {
                // Fallback - just export directory
                exportURL = packageDir
                showExportSheet = true
            }
            
        } catch {
            print("Failed to create package: \(error)")
        }
    }
    
    private func exportP12() {
        guard let cert = selectedCertForExport,
              let p12URL = Storage.shared.getFile(.certificate, from: cert) else { return }
        
        exportURL = p12URL
        showExportSheet = true
    }
    
    private func exportProvision() {
        guard let cert = selectedCertForExport,
              let provisionURL = Storage.shared.getFile(.provision, from: cert) else { return }
        
        exportURL = provisionURL
        showExportSheet = true
    }
    
    private func copyPassword() {
        guard let cert = selectedCertForExport,
              let password = cert.password else { return }
        
        UIPasteboard.general.string = password
        showCopiedAlert = true
    }
}

// MARK: - Preview
#Preview {
    SigningSettingsView()
}

