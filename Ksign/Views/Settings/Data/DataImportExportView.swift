//
//  DataImportExportView.swift
//  Ksign
//
//  Import and export all SwiftSigner Pro app data
//

import SwiftUI
import NimbleViews
import CoreData
import UniformTypeIdentifiers

// MARK: - Data Import/Export View
struct DataImportExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportURL: URL?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var selectedDataTypes: Set<DataType> = Set(DataType.allCases)
    
    // Fetch data for counts
    @FetchRequest(entity: CertificatePair.entity(), sortDescriptors: [])
    private var certificates: FetchedResults<CertificatePair>
    
    @FetchRequest(entity: AltSource.entity(), sortDescriptors: [])
    private var sources: FetchedResults<AltSource>
    
    @FetchRequest(entity: Imported.entity(), sortDescriptors: [])
    private var importedApps: FetchedResults<Imported>
    
    @FetchRequest(entity: Signed.entity(), sortDescriptors: [])
    private var signedApps: FetchedResults<Signed>
    
    var body: some View {
        Form {
            // Header Section
            Section {
                _headerCard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Data Overview
            Section {
                _dataRow(icon: "signature", iconColor: .orange, title: .localized("Certificates"), count: certificates.count)
                _dataRow(icon: "globe", iconColor: .blue, title: .localized("Sources"), count: sources.count)
                _dataRow(icon: "arrow.down.circle", iconColor: .green, title: .localized("Downloaded Apps"), count: importedApps.count)
                _dataRow(icon: "checkmark.seal", iconColor: .purple, title: .localized("Signed Apps"), count: signedApps.count)
            } header: {
                Text(.localized("Current Data"))
            }
            
            // Select Data Types
            Section {
                ForEach(DataType.allCases, id: \.self) { type in
                    Toggle(isOn: Binding(
                        get: { selectedDataTypes.contains(type) },
                        set: { isSelected in
                            if isSelected {
                                selectedDataTypes.insert(type)
                            } else {
                                selectedDataTypes.remove(type)
                            }
                        }
                    )) {
                        Label {
                            Text(type.displayName)
                        } icon: {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                        }
                    }
                }
            } header: {
                Text(.localized("Select Data to Export/Import"))
            } footer: {
                Text(.localized("Choose which data types to include in the export or import."))
            }
            
            // Export Section
            Section {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Export Data"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(.localized("Save all selected data as a backup file"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isProcessing {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isProcessing || selectedDataTypes.isEmpty)
            } header: {
                Text(.localized("Export"))
            } footer: {
                Text(.localized("Creates an .ethsign file containing your selected data."))
            }
            
            // Import Section
            Section {
                Button {
                    showImportPicker = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Import Data"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(.localized("Restore data from a backup file"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isProcessing {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isProcessing)
            } header: {
                Text(.localized("Import"))
            } footer: {
                Text(.localized("Import data from an .ethsign or .json backup file."))
            }
            
            // Quick Actions
            Section {
                Button {
                    exportToClipboard()
                } label: {
                    Label {
                        Text(.localized("Copy Data to Clipboard"))
                    } icon: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.orange)
                    }
                }
                .disabled(isProcessing || selectedDataTypes.isEmpty)
                
                Button {
                    importFromClipboard()
                } label: {
                    Label {
                        Text(.localized("Import from Clipboard"))
                    } icon: {
                        Image(systemName: "clipboard")
                            .foregroundColor(.green)
                    }
                }
                .disabled(isProcessing)
            } header: {
                Text(.localized("Quick Actions"))
            }
        }
        .navigationTitle(.localized("Import & Export"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker(contentTypes: [.json, .data, UTType(filenameExtension: "ethsign") ?? .data]) { url in
                importData(from: url)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button(.localized("OK")) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header Card
    private var _headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "externaldrive.fill.badge.icloud")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text(.localized("SwiftSigner Pro Data"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(.localized("Import & Export"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Data Row
    private func _dataRow(icon: String, iconColor: Color, title: String, count: Int) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Export Functions
    private func exportData() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let exportData = try createExportData()
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
                
                // Save to temp file
                let fileName = "SwiftSignerPro_Backup_\(formattedDate()).ethsign"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try jsonData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    isProcessing = false
                    exportURL = tempURL
                    showExportSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Export Failed")
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func exportToClipboard() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let exportData = try createExportData()
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    UIPasteboard.general.string = jsonString
                    isProcessing = false
                    alertTitle = .localized("Copied!")
                    alertMessage = .localized("Data has been copied to clipboard.")
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Export Failed")
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func createExportData() throws -> [String: Any] {
        var exportDict: [String: Any] = [
            "version": "1.0",
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.version ?? "1.0",
            "deviceName": UIDevice.current.name
        ]
        
        // Export Sources
        if selectedDataTypes.contains(.sources) {
            var sourcesArray: [[String: Any]] = []
            for source in sources {
                var sourceDict: [String: Any] = [:]
                if let name = source.name { sourceDict["name"] = name }
                if let url = source.sourceURL?.absoluteString { sourceDict["url"] = url }
                sourceDict["identifier"] = source.identifier
                sourcesArray.append(sourceDict)
            }
            exportDict["sources"] = sourcesArray
        }
        
        // Export Certificates (metadata only, not private keys for security)
        if selectedDataTypes.contains(.certificates) {
            var certsArray: [[String: Any]] = []
            for cert in certificates {
                var certDict: [String: Any] = [:]
                if let nickname = cert.nickname { certDict["nickname"] = nickname }
                if let expiration = cert.expiration { certDict["expiration"] = ISO8601DateFormatter().string(from: expiration) }
                if let p12Data = cert.p12Data { certDict["p12Data"] = p12Data.base64EncodedString() }
                if let provisionData = cert.provisionData { certDict["provisionData"] = provisionData.base64EncodedString() }
                if let password = cert.password { certDict["password"] = password }
                certsArray.append(certDict)
            }
            exportDict["certificates"] = certsArray
        }
        
        // Export Settings
        if selectedDataTypes.contains(.settings) {
            var settingsDict: [String: Any] = [:]
            settingsDict["userInterfaceStyle"] = UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")
            settingsDict["accentColor"] = UserDefaults.standard.integer(forKey: "Feather.accentColor")
            settingsDict["selectedCert"] = UserDefaults.standard.integer(forKey: "feather.selectedCert")
            settingsDict["showFilesTab"] = UserDefaults.standard.bool(forKey: "SwiftSignerPro.showFilesTab")
            settingsDict["showCertificatesTab"] = UserDefaults.standard.bool(forKey: "SwiftSignerPro.showCertificatesTab")
            exportDict["settings"] = settingsDict
        }
        
        // Export App Metadata (not the actual IPA files)
        if selectedDataTypes.contains(.apps) {
            var importedArray: [[String: Any]] = []
            for app in importedApps {
                var appDict: [String: Any] = [:]
                if let name = app.name { appDict["name"] = name }
                if let identifier = app.identifier { appDict["identifier"] = identifier }
                if let version = app.version { appDict["version"] = version }
                importedArray.append(appDict)
            }
            exportDict["importedApps"] = importedArray
            
            var signedArray: [[String: Any]] = []
            for app in signedApps {
                var appDict: [String: Any] = [:]
                if let name = app.name { appDict["name"] = name }
                if let identifier = app.identifier { appDict["identifier"] = identifier }
                if let version = app.version { appDict["version"] = version }
                signedArray.append(appDict)
            }
            exportDict["signedApps"] = signedArray
        }
        
        return exportDict
    }
    
    // MARK: - Import Functions
    private func importData(from url: URL) {
        isProcessing = true
        
        guard url.startAccessingSecurityScopedResource() else {
            isProcessing = false
            alertTitle = .localized("Import Failed")
            alertMessage = .localized("Could not access the file.")
            showAlert = true
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                try processImportData(data)
                
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Import Complete!")
                    alertMessage = .localized("Your data has been successfully imported.")
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Import Failed")
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func importFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string,
              let data = clipboardString.data(using: .utf8) else {
            alertTitle = .localized("Import Failed")
            alertMessage = .localized("No valid data found in clipboard.")
            showAlert = true
            return
        }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try processImportData(data)
                
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Import Complete!")
                    alertMessage = .localized("Your data has been successfully imported from clipboard.")
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    alertTitle = .localized("Import Failed")
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func processImportData(_ data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SwiftSignerPro", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        DispatchQueue.main.sync {
            // Import Sources
            if selectedDataTypes.contains(.sources),
               let sourcesArray = json["sources"] as? [[String: Any]] {
                for sourceDict in sourcesArray {
                    guard let urlString = sourceDict["url"] as? String,
                          let url = URL(string: urlString) else { continue }
                    
                    // Check if source already exists
                    let existingSource = sources.filter { $0.sourceURL?.absoluteString == urlString }.first
                    if existingSource == nil {
                        let newSource = AltSource(context: viewContext)
                        newSource.sourceURL = url
                        newSource.name = sourceDict["name"] as? String
                        newSource.identifier = sourceDict["identifier"] as? String ?? UUID().uuidString
                        newSource.date = Date()
                    }
                }
            }
            
            // Import Certificates
            if selectedDataTypes.contains(.certificates),
               let certsArray = json["certificates"] as? [[String: Any]] {
                for certDict in certsArray {
                    guard let p12Base64 = certDict["p12Data"] as? String,
                          let p12Data = Data(base64Encoded: p12Base64) else { continue }
                    
                    // Check if cert already exists
                    let existingCert = certificates.first { $0.nickname == certDict["nickname"] as? String }
                    if existingCert == nil {
                        let newCert = CertificatePair(context: viewContext)
                        newCert.nickname = certDict["nickname"] as? String
                        newCert.p12Data = p12Data
                        newCert.password = certDict["password"] as? String
                        newCert.uuid = UUID().uuidString
                        newCert.ppQCheck = false
                        
                        if let provisionBase64 = certDict["provisionData"] as? String,
                           let provisionData = Data(base64Encoded: provisionBase64) {
                            newCert.provisionData = provisionData
                        }
                        
                        if let expirationString = certDict["expiration"] as? String,
                           let expirationDate = ISO8601DateFormatter().date(from: expirationString) {
                            newCert.expiration = expirationDate
                        } else {
                            // Default expiration date (1 year from now)
                            newCert.expiration = Date().addingTimeInterval(365 * 24 * 60 * 60)
                        }
                        
                        newCert.date = Date()
                    }
                }
            }
            
            // Import Settings
            if selectedDataTypes.contains(.settings),
               let settingsDict = json["settings"] as? [String: Any] {
                if let userInterfaceStyle = settingsDict["userInterfaceStyle"] as? Int {
                    UserDefaults.standard.set(userInterfaceStyle, forKey: "Feather.userInterfaceStyle")
                }
                if let accentColor = settingsDict["accentColor"] as? Int {
                    UserDefaults.standard.set(accentColor, forKey: "Feather.accentColor")
                }
                if let showFilesTab = settingsDict["showFilesTab"] as? Bool {
                    UserDefaults.standard.set(showFilesTab, forKey: "SwiftSignerPro.showFilesTab")
                }
                if let showCertificatesTab = settingsDict["showCertificatesTab"] as? Bool {
                    UserDefaults.standard.set(showCertificatesTab, forKey: "SwiftSignerPro.showCertificatesTab")
                }
            }
            
            // Save context
            try? viewContext.save()
        }
    }
    
    // MARK: - Helpers
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Data Types Enum
enum DataType: String, CaseIterable {
    case sources = "sources"
    case certificates = "certificates"
    case settings = "settings"
    case apps = "apps"
    
    var displayName: String {
        switch self {
        case .sources: return String.localized("Sources & Repositories")
        case .certificates: return String.localized("Certificates")
        case .settings: return String.localized("App Settings")
        case .apps: return String.localized("App Metadata")
        }
    }
    
    var icon: String {
        switch self {
        case .sources: return "globe"
        case .certificates: return "signature"
        case .settings: return "gear"
        case .apps: return "app.badge"
        }
    }
    
    var color: Color {
        switch self {
        case .sources: return .blue
        case .certificates: return .orange
        case .settings: return .gray
        case .apps: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        DataImportExportView()
    }
}
