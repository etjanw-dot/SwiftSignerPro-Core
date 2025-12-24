//
//  BulkCertificateImportView.swift
//  Ksign
//
//  Bulk certificate import with "Add Another" functionality
//

import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import Zip

// MARK: - Certificate Entry
struct CertificateEntry: Identifiable {
    let id: UUID
    var p12URL: URL?
    var provisionURL: URL?
    var password: String
    var nickname: String
    var p12Data: Data?
    var provisionData: Data?
    var isFromZip: Bool
    var expirationDate: Date?
    var isExpired: Bool
    
    init(id: UUID = UUID(), p12URL: URL? = nil, provisionURL: URL? = nil, password: String = "", nickname: String = "", p12Data: Data? = nil, provisionData: Data? = nil, isFromZip: Bool = false, expirationDate: Date? = nil, isExpired: Bool = false) {
        self.id = id
        self.p12URL = p12URL
        self.provisionURL = provisionURL
        self.password = password
        self.nickname = nickname
        self.p12Data = p12Data
        self.provisionData = provisionData
        self.isFromZip = isFromZip
        self.expirationDate = expirationDate
        self.isExpired = isExpired
    }
    
    var isComplete: Bool {
        return (p12URL != nil || p12Data != nil) && (provisionURL != nil || provisionData != nil)
    }
}

// MARK: - View
struct BulkCertificateImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var certificates: [CertificateEntry] = [CertificateEntry()]
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var currentImportingIndex: Int = 0
    @State private var showFilePicker = false
    @State private var activePickerType: PickerType = .p12
    @State private var activePickerIndex: Int = 0
    @State private var importResults: [ImportResult] = []
    @State private var showResultsSheet = false
    
    enum PickerType {
        case p12
        case provision
        case zip
    }
    
    struct ImportResult: Identifiable {
        let id = UUID()
        let nickname: String
        let success: Bool
        let message: String
    }
    
    var completeCertificates: [CertificateEntry] {
        certificates.filter { $0.isComplete }
    }
    
    var body: some View {
        NBNavigationView(.localized("Bulk Import"), displayMode: .inline) {
            Form {
                // Header
                Section {
                    _headerView()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Certificate Entries
                ForEach(Array(certificates.enumerated()), id: \.element.id) { index, cert in
                    _certificateSection(index: index, cert: cert)
                }
                
                // Add Another Button
                Section {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            certificates.append(CertificateEntry())
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Add Another Certificate"))
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                                Text(.localized("No limit on number of certificates"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Quick Import Section
                NBSection(.localized("Quick Import")) {
                    Button {
                        activePickerType = .zip
                        activePickerIndex = certificates.count - 1
                        showFilePicker = true
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
                                Text(.localized("Import from ZIP"))
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Text(.localized("Extract multiple certificates from ZIP file"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Import Progress
                if isImporting {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: importProgress)
                                .tint(.accentColor)
                            
                            Text(.localized("Importing certificate \(currentImportingIndex + 1) of \(completeCertificates.count)..."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        _importAllCertificates()
                    } label: {
                        if isImporting {
                            ProgressView()
                        } else {
                            Text(.localized("Import All"))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(completeCertificates.isEmpty || isImporting)
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
            _filePicker()
        }
        .sheet(isPresented: $showResultsSheet) {
            _resultsSheet()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func _headerView() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Small icon with gradient - Library style
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "signature")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Bulk Certificate Import"))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(.localized("Import multiple certificates at once"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Stats row
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(certificates.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(.localized("Total"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(completeCertificates.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(.localized("Ready"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func _statBadge(value: String, label: String, color: Color = .primary, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(highlight ? color : .primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(highlight ? 0.15 : 0.08))
        )
    }
    
    @ViewBuilder
    private func _certificateSection(index: Int, cert: CertificateEntry) -> some View {
        Section {
            // P12 Import
            Button {
                activePickerType = .p12
                activePickerIndex = index
                showFilePicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("P12 Certificate"))
                            .foregroundColor(.primary)
                        if let p12URL = cert.p12URL {
                            Text(p12URL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if cert.p12Data != nil {
                            Text(.localized("Loaded from ZIP"))
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(.localized("Tap to select"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if cert.p12URL != nil || cert.p12Data != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Provision Import
            Button {
                activePickerType = .provision
                activePickerIndex = index
                showFilePicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "doc.badge.gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Provisioning Profile"))
                            .foregroundColor(.primary)
                        if let provisionURL = cert.provisionURL {
                            Text(provisionURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if cert.provisionData != nil {
                            Text(.localized("Loaded from ZIP"))
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(.localized("Tap to select"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if cert.provisionURL != nil || cert.provisionData != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Expiration info
            if let expDate = cert.expirationDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(cert.isExpired ? .red : .green)
                    
                    Text(cert.isExpired ? .localized("Expired") : .localized("Expires"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(expDate, style: .date)
                        .font(.caption)
                        .foregroundColor(cert.isExpired ? .red : .primary)
                }
            }
            
            // Password
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                SecureField(.localized("Password"), text: Binding(
                    get: { certificates[index].password },
                    set: { certificates[index].password = $0 }
                ))
            }
            
            // Nickname
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "tag.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                TextField(.localized("Nickname (Optional)"), text: Binding(
                    get: { certificates[index].nickname },
                    set: { certificates[index].nickname = $0 }
                ))
            }
        } header: {
            HStack {
                Text(.localized("Certificate \(index + 1)"))
                
                Spacer()
                
                if certificates.count > 1 {
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.3)) {
                            let indexToRemove: Int = index
                            certificates.remove(at: indexToRemove)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                }
            }
        } footer: {
            if cert.isComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(.localized("Ready to import"))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    @ViewBuilder
    private func _filePicker() -> some View {
        let contentTypes: [UTType] = {
            switch activePickerType {
            case .p12:
                return [UTType(filenameExtension: "p12")!, UTType.pkcs12]
            case .provision:
                return [UTType(filenameExtension: "mobileprovision")!]
            case .zip:
                return [UTType.zip, UTType.archive]
            }
        }()
        
        FileImporterRepresentableView(
            allowedContentTypes: contentTypes,
            onDocumentsPicked: { urls in
                guard let url = urls.first else { return }
                _handleFilePicked(url)
            }
        )
    }
    
    @ViewBuilder
    private func _resultsSheet() -> some View {
        NBNavigationView(.localized("Import Results"), displayMode: .inline) {
            List {
                ForEach(importResults) { result in
                    HStack(spacing: 12) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.nickname.isEmpty ? .localized("Certificate") : result.nickname)
                                .fontWeight(.medium)
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Done")) {
                        showResultsSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func _handleFilePicked(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        switch activePickerType {
        case .p12:
            certificates[activePickerIndex].p12URL = url
            certificates[activePickerIndex].p12Data = nil
            certificates[activePickerIndex].isFromZip = false
            
        case .provision:
            certificates[activePickerIndex].provisionURL = url
            certificates[activePickerIndex].provisionData = nil
            certificates[activePickerIndex].isFromZip = false
            _extractExpirationDate(from: url, at: activePickerIndex)
            
        case .zip:
            _extractCertificatesFromZip(url)
        }
    }
    
    private func _extractExpirationDate(from url: URL, at index: Int) {
        guard let data = try? Data(contentsOf: url) else { return }
        
        // Simple plist parsing for expiration date
        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let expDate = plist["ExpirationDate"] as? Date {
            certificates[index].expirationDate = expDate
            certificates[index].isExpired = expDate < Date()
        }
    }
    
    private func _extractCertificatesFromZip(_ zipURL: URL) {
        Task {
            do {
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                try Zip.unzipFile(zipURL, destination: tempDir, overwrite: true, password: nil)
                
                let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                
                var p12Files: [URL] = []
                var provisionFiles: [URL] = []
                
                func scanDirectory(_ dir: URL) throws {
                    let items = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                    for item in items {
                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                            try scanDirectory(item)
                        } else {
                            let ext = item.pathExtension.lowercased()
                            if ext == "p12" {
                                p12Files.append(item)
                            } else if ext == "mobileprovision" {
                                provisionFiles.append(item)
                            }
                        }
                    }
                }
                
                try scanDirectory(tempDir)
                
                await MainActor.run {
                    // Match p12 files with provision files
                    let pairCount = min(p12Files.count, provisionFiles.count)
                    
                    for i in 0..<pairCount {
                        let p12Data = try? Data(contentsOf: p12Files[i])
                        let provisionData = try? Data(contentsOf: provisionFiles[i])
                        
                        var entry = CertificateEntry()
                        entry.p12Data = p12Data
                        entry.provisionData = provisionData
                        entry.isFromZip = true
                        entry.nickname = p12Files[i].deletingPathExtension().lastPathComponent
                        
                        // Try to extract expiration date
                        if let provData = provisionData,
                           let plist = try? PropertyListSerialization.propertyList(from: provData, format: nil) as? [String: Any],
                           let expDate = plist["ExpirationDate"] as? Date {
                            entry.expirationDate = expDate
                            entry.isExpired = expDate < Date()
                        }
                        
                        if certificates.count == 1 && !certificates[0].isComplete {
                            certificates[0] = entry
                        } else {
                            certificates.append(entry)
                        }
                    }
                    
                    // Handle unpaired files
                    for i in pairCount..<p12Files.count {
                        var entry = CertificateEntry()
                        entry.p12Data = try? Data(contentsOf: p12Files[i])
                        entry.isFromZip = true
                        entry.nickname = p12Files[i].deletingPathExtension().lastPathComponent
                        certificates.append(entry)
                    }
                    
                    for i in pairCount..<provisionFiles.count {
                        var entry = CertificateEntry()
                        entry.provisionData = try? Data(contentsOf: provisionFiles[i])
                        entry.isFromZip = true
                        entry.nickname = provisionFiles[i].deletingPathExtension().lastPathComponent
                        certificates.append(entry)
                    }
                    
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                
                // Cleanup
                try? FileManager.default.removeItem(at: tempDir)
                
            } catch {
                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Extraction Failed"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func _importAllCertificates() {
        let certsToImport = completeCertificates
        guard !certsToImport.isEmpty else { return }
        
        isImporting = true
        importProgress = 0
        importResults = []
        
        Task {
            for (index, cert) in certsToImport.enumerated() {
                await MainActor.run {
                    currentImportingIndex = index
                    importProgress = Double(index) / Double(certsToImport.count)
                }
                
                let result = await _importCertificate(cert)
                
                await MainActor.run {
                    importResults.append(result)
                }
                
                // Small delay between imports
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            await MainActor.run {
                importProgress = 1.0
                isImporting = false
                showResultsSheet = true
            }
        }
    }
    
    private func _importCertificate(_ cert: CertificateEntry) async -> ImportResult {
        do {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer {
                try? FileManager.default.removeItem(at: tempDir)
            }
            
            let tempP12URL: URL
            let tempProvisionURL: URL
            
            // Handle P12 data/URL
            if let data = cert.p12Data {
                tempP12URL = tempDir.appendingPathComponent("cert.p12")
                try data.write(to: tempP12URL)
            } else if let url = cert.p12URL {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                tempP12URL = tempDir.appendingPathComponent(url.lastPathComponent)
                try data.write(to: tempP12URL)
            } else {
                return ImportResult(nickname: cert.nickname, success: false, message: .localized("Missing P12 file"))
            }
            
            // Handle Provision data/URL
            if let data = cert.provisionData {
                tempProvisionURL = tempDir.appendingPathComponent("cert.mobileprovision")
                try data.write(to: tempProvisionURL)
            } else if let url = cert.provisionURL {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                tempProvisionURL = tempDir.appendingPathComponent(url.lastPathComponent)
                try data.write(to: tempProvisionURL)
            } else {
                return ImportResult(nickname: cert.nickname, success: false, message: .localized("Missing provisioning profile"))
            }
            
            // Validate password
            let passwordValid = FR.checkPasswordForCertificate(for: tempP12URL, with: cert.password, using: tempProvisionURL)
            if !passwordValid && !cert.password.isEmpty {
                return ImportResult(nickname: cert.nickname, success: false, message: .localized("Invalid password"))
            }
            
            // Save the certificate using FR helper
            return await withCheckedContinuation { continuation in
                FR.handleCertificateFiles(
                    p12URL: tempP12URL,
                    provisionURL: tempProvisionURL,
                    p12Password: cert.password,
                    certificateName: cert.nickname
                ) { error in
                    if let error = error {
                        continuation.resume(returning: ImportResult(nickname: cert.nickname, success: false, message: error.localizedDescription))
                    } else {
                        continuation.resume(returning: ImportResult(nickname: cert.nickname, success: true, message: .localized("Imported successfully")))
                    }
                }
            }
            
        } catch {
            return ImportResult(nickname: cert.nickname, success: false, message: error.localizedDescription)
        }
    }
}
