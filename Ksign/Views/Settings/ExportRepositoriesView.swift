//
//  ExportRepositoriesView.swift
//  Ksign
//
//  Export repositories in various formats (KravaSign, HSign, Plain URLs).
//

import SwiftUI
import CoreData
import NimbleViews
import CoreImage.CIFilterBuiltins

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case kravaSign = "KravaSign"
    case hSign = "HSign"
    case plainURLs = "Plain URLs"
    
    var description: String {
        switch self {
        case .kravaSign: return "Coming soon..."
        case .hSign: return "HSign compatible format"
        case .plainURLs: return "Simple list of URLs"
        }
    }
}

// MARK: - Export Repositories View
struct ExportRepositoriesView: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>
    
    @State private var selectedFormat: ExportFormat = .hSign
    @State private var selectedSources: Set<String> = []
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var qrCodeImage: UIImage?
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Format Picker
                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedFormat == .kravaSign {
                    Text(.localized("Coming soon..."))
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                List {
                    // Selection Header
                    Section {
                        HStack {
                            Text(.localized("Repositories (\(selectedSources.count)/\(sources.count) selected)"))
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(selectedSources.count == sources.count ? .localized("Deselect All") : .localized("Select All")) {
                                if selectedSources.count == sources.count {
                                    selectedSources.removeAll()
                                } else {
                                    selectedSources = Set(sources.compactMap { $0.sourceURL?.absoluteString })
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    // Repository List
                    Section {
                        ForEach(sources) { source in
                            Button {
                                toggleSelection(source)
                            } label: {
                                HStack {
                                    Image(systemName: isSelected(source) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected(source) ? .blue : .secondary)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.sourceURL?.absoluteString ?? "Unknown")
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Export Buttons
                    Section {
                        Button {
                            exportRepositories()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text(.localized("Export Selected Repositories"))
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(selectedSources.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(selectedSources.isEmpty)
                        .buttonStyle(.plain)
                        
                        Button {
                            copyToClipboard()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                Text(.localized("Copy to Clipboard"))
                                Spacer()
                            }
                            .foregroundColor(.primary)
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .disabled(selectedSources.isEmpty)
                        .buttonStyle(.plain)
                    }
                    
                    // QR Code Section
                    if !selectedSources.isEmpty {
                        Section {
                            VStack {
                                Text(.localized("QR Code"))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if let qrImage = generateQRCode() {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle(.localized("Export Repositories"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Share")) {
                        exportRepositories()
                    }
                    .disabled(selectedSources.isEmpty)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(.localized("Copied!"), isPresented: $showCopiedAlert) {
                Button(.localized("OK")) { }
            } message: {
                Text(.localized("Repository URLs copied to clipboard."))
            }
            .onAppear {
                // Select all by default
                selectedSources = Set(sources.compactMap { $0.sourceURL?.absoluteString })
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isSelected(_ source: AltSource) -> Bool {
        guard let url = source.sourceURL?.absoluteString else { return false }
        return selectedSources.contains(url)
    }
    
    private func toggleSelection(_ source: AltSource) {
        guard let url = source.sourceURL?.absoluteString else { return }
        
        if selectedSources.contains(url) {
            selectedSources.remove(url)
        } else {
            selectedSources.insert(url)
        }
    }
    
    private func getExportContent() -> String {
        let urls = Array(selectedSources)
        
        switch selectedFormat {
        case .kravaSign:
            // KravaSign format (JSON structure)
            let json: [String: Any] = [
                "name": "Exported Repositories",
                "repos": urls
            ]
            if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return urls.joined(separator: "\n")
            
        case .hSign:
            // HSign format (JSON array)
            let json: [[String: String]] = urls.map { ["url": $0] }
            if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return urls.joined(separator: "\n")
            
        case .plainURLs:
            return urls.joined(separator: "\n")
        }
    }
    
    private func exportRepositories() {
        let content = getExportContent()
        
        let fileExtension: String
        switch selectedFormat {
        case .kravaSign: fileExtension = "kravasign"
        case .hSign: fileExtension = "hsign"
        case .plainURLs: fileExtension = "txt"
        }
        
        let fileName = "repositories.\(fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showShareSheet = true
        } catch {
            print("Failed to export: \(error)")
        }
    }
    
    private func copyToClipboard() {
        let content = getExportContent()
        UIPasteboard.general.string = content
        showCopiedAlert = true
    }
    
    private func generateQRCode() -> UIImage? {
        let urls = Array(selectedSources)
        guard !urls.isEmpty else { return nil }
        
        let content = urls.joined(separator: "\n")
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = 200 / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview
#Preview {
    ExportRepositoriesView()
}
