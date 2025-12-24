//
//  DownloadingAppCellView.swift
//  SwiftSigner Pro
//
//  Shows an app that is currently being downloaded from the App Store
//  Displays with grayed out appearance and download progress bar
//

import SwiftUI
import NukeUI

// MARK: - Downloading App Model
struct DownloadingApp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let bundleId: String
    let iconURL: URL?
    var version: String
    var seller: String?
    var progress: Double // 0.0 to 1.0
    var status: DownloadStatus
    var bytesDownloaded: Int64
    var totalBytes: Int64
    
    // Convenience init with defaults
    init(id: UUID, name: String, bundleId: String, iconURL: URL?, status: DownloadStatus, progress: Double, version: String = "", seller: String? = nil, bytesDownloaded: Int64 = 0, totalBytes: Int64 = 0) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.iconURL = iconURL
        self.version = version
        self.seller = seller
        self.progress = progress
        self.status = status
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
    }
    
    enum DownloadStatus: Equatable {
        case waiting
        case downloading
        case extracting
        case importing
        case completed
        case failed(String)
        
        var displayText: String {
            switch self {
            case .waiting: return .localized("Waiting...")
            case .downloading: return .localized("Downloading...")
            case .extracting: return .localized("Extracting...")
            case .importing: return .localized("Importing...")
            case .completed: return .localized("Completed")
            case .failed(let error): return .localized("Failed: ") + error
            }
        }
        
        var isActive: Bool {
            switch self {
            case .waiting, .downloading, .extracting, .importing:
                return true
            default:
                return false
            }
        }
    }
    
    var progressText: String {
        if totalBytes > 0 {
            return "\(ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))"
        }
        return status.displayText
    }
}

// MARK: - Downloading Apps Manager
class DownloadingAppsManager: ObservableObject {
    static let shared = DownloadingAppsManager()
    
    @Published var downloads: [DownloadingApp] = []
    
    func addDownload(_ app: DownloadingApp) {
        DispatchQueue.main.async {
            if !self.downloads.contains(where: { $0.id == app.id }) {
                self.downloads.append(app)
            }
        }
    }
    
    func updateProgress(id: UUID, progress: Double, bytesDownloaded: Int64 = 0, totalBytes: Int64 = 0) {
        DispatchQueue.main.async {
            if let index = self.downloads.firstIndex(where: { $0.id == id }) {
                self.downloads[index].progress = progress
                self.downloads[index].bytesDownloaded = bytesDownloaded
                self.downloads[index].totalBytes = totalBytes
            }
        }
    }
    
    func updateStatus(id: UUID, status: DownloadingApp.DownloadStatus) {
        DispatchQueue.main.async {
            if let index = self.downloads.firstIndex(where: { $0.id == id }) {
                self.downloads[index].status = status
                
                // Remove completed/failed downloads after a delay
                if case .completed = status {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.removeDownload(id: id)
                    }
                }
            }
        }
    }
    
    func removeDownload(id: UUID) {
        DispatchQueue.main.async {
            self.downloads.removeAll { $0.id == id }
        }
    }
}

// MARK: - Downloading App Cell View
struct DownloadingAppCellView: View {
    let app: DownloadingApp
    
    @State private var _animationOffset: CGFloat = -200
    
    var body: some View {
        HStack(spacing: 9) {
            // App icon - grayed out
            ZStack {
                if let iconURL = app.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            _placeholderIcon
                        }
                    }
                    .frame(width: 57, height: 57)
                    .clipShape(RoundedRectangle(cornerRadius: 12.5))
                    .saturation(0.3) // Gray out
                    .opacity(0.7)
                } else {
                    _placeholderIcon
                }
                
                // Download indicator overlay
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 28, height: 28)
                    
                    if app.status.isActive {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
            }
            
            // App info
            VStack(alignment: .leading, spacing: 4) {
                // App name - grayed out
                Text(app.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Bundle ID and version
                Text("\(app.bundleId) • v\(app.version)")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 6)
                        
                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * app.progress, 0), height: 6)
                            .animation(.spring(response: 0.3), value: app.progress)
                        
                        // Animated shimmer effect for active downloads
                        if app.status.isActive && app.progress < 1.0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50, height: 6)
                                .offset(x: _animationOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: 3)
                                        .frame(width: max(geometry.size.width * app.progress, 0), height: 6)
                                )
                        }
                    }
                }
                .frame(height: 6)
                
                // Status text with importing icon
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                    
                    Text(app.progressText)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Cancel button for active downloads
            if app.status.isActive {
                Button {
                    DownloadingAppsManager.shared.removeDownload(id: app.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.85)
        .onAppear {
            // Start shimmer animation
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                _animationOffset = 300
            }
        }
    }
    
    private var _placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 12.5)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 57, height: 57)
            .overlay(
                Image(systemName: "app.dashed")
                    .font(.title2)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Preview
#Preview {
    List {
        DownloadingAppCellView(app: DownloadingApp(
            id: UUID(),
            name: "Instagram",
            bundleId: "com.burbn.instagram",
            iconURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/a9/ab/c4/a9abc4e4-5943-4927-d2e3-5e6e3c0b9e8a/Prod-0-0-1x_U007emarketing-0-7-0-85-220.png/100x100bb.jpg"),
            status: .downloading,
            progress: 0.45,
            version: "305.0",
            seller: "Instagram, Inc.",
            bytesDownloaded: 45_000_000,
            totalBytes: 100_000_000
        ))
        
        DownloadingAppCellView(app: DownloadingApp(
            id: UUID(),
            name: "Spotify",
            bundleId: "com.spotify.client",
            iconURL: nil,
            status: .waiting,
            progress: 0.0
        ))
    }
}
