//
//  GameTweaksView.swift
//  Ksign
//
//  Game Tweaks section for downloading and importing iOS game mods.
//

import SwiftUI
import NimbleViews

// MARK: - Game Tweak Definition
struct GameTweak: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let downloadURL: String
    let fileName: String
    var isDownloading: Bool = false
    var isInstalled: Bool = false
    var progress: Double = 0
}

// MARK: - Game Tweaks Manager
class GameTweaksManager: ObservableObject {
    static let shared = GameTweaksManager()
    
    @Published var tweaks: [GameTweak] = [
        // IAP Bypass Tweaks
        GameTweak(
            name: "SatellaJailed",
            description: "In-app purchase bypass for jailed iOS devices",
            icon: "cart.fill",
            downloadURL: "https://github.com/Paisseon/SatellaJailed/raw/refs/heads/emt/SatellaJailed.dylib",
            fileName: "SatellaJailed.dylib"
        ),
        GameTweak(
            name: "iOSGods",
            description: "Popular game modding framework for iOS games",
            icon: "gamecontroller.fill",
            downloadURL: "https://drive.google.com/uc?id=1Z6O3GmOwXBk5wp_ejBaebHND8AHR3oaA",
            fileName: "iOSGods.framework"
        ),
        GameTweak(
            name: "Wolf",
            description: "Universal subscription unlock for most apps",
            icon: "dollarsign.circle.fill",
            downloadURL: "https://github.com/AhmedNaser1/Wolf/raw/main/Wolf.dylib",
            fileName: "Wolf.dylib"
        ),
        GameTweak(
            name: "RevenueCat Bypass",
            description: "Bypass RevenueCat subscription checks",
            icon: "creditcard.fill",
            downloadURL: "https://raw.githubusercontent.com/BandarHelworster/VoldemortGhost/main/RevenueKitten.dylib",
            fileName: "RevenueKitten.dylib"
        ),
        
        // Social Media Tweaks
        GameTweak(
            name: "Rocket for Instagram",
            description: "Download media, hide ads, custom features for Instagram",
            icon: "camera.fill",
            downloadURL: "https://github.com/AhmedNaser1/Rocket/raw/main/Rocket.dylib",
            fileName: "Rocket.dylib"
        ),
        GameTweak(
            name: "Watusi",
            description: "Full-featured WhatsApp enhancement tweak",
            icon: "bubble.left.and.bubble.right.fill",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/Watusi/main/Watusi.dylib",
            fileName: "Watusi.dylib"
        ),
        GameTweak(
            name: "uYou+",
            description: "Enhanced YouTube experience with download features",
            icon: "play.rectangle.fill",
            downloadURL: "https://raw.githubusercontent.com/qnblackcat/uYouPlus/main/uYou.dylib",
            fileName: "uYou.dylib"
        ),
        GameTweak(
            name: "TikTok God",
            description: "Enhanced TikTok with download and no watermark",
            icon: "music.note",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/TikTokGod/main/TikTokGod.dylib",
            fileName: "TikTokGod.dylib"
        ),
        GameTweak(
            name: "Twitter++",
            description: "Enhanced Twitter/X with extra features",
            icon: "at",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/TwitterPlusPlus/main/Twitter++.dylib",
            fileName: "Twitter++.dylib"
        ),
        GameTweak(
            name: "Spotify++",
            description: "Premium Spotify features unlocked",
            icon: "music.note.tv.fill",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/SpotifyPlusPlus/main/Spotify++.dylib",
            fileName: "Spotify++.dylib"
        ),
        
        // Jailbreak Detection Bypass
        GameTweak(
            name: "Shadow",
            description: "Jailbreak detection bypass (works jailed too)",
            icon: "eye.slash.fill",
            downloadURL: "https://github.com/jjolano/shadow/releases/download/2.0.20/shadow.dylib",
            fileName: "shadow.dylib"
        ),
        GameTweak(
            name: "FlyJB",
            description: "Advanced jailbreak detection bypass",
            icon: "lock.shield.fill",
            downloadURL: "https://github.com/AhmedNaser1/FlyJB/raw/main/FlyJB.dylib",
            fileName: "FlyJB.dylib"
        ),
        
        // Utility Tweaks
        GameTweak(
            name: "ElleKit",
            description: "Modern CydiaSubstrate replacement framework",
            icon: "hammer.fill",
            downloadURL: "https://github.com/evelyneee/ellekit/releases/download/0.4.5/ellekit.dylib",
            fileName: "ellekit.dylib"
        ),
        GameTweak(
            name: "Fishhook",
            description: "Dynamic library injection helper",
            icon: "link.circle.fill",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/Fishhook/main/fishhook.dylib",
            fileName: "fishhook.dylib"
        ),
        GameTweak(
            name: "LocalIAPStore",
            description: "Classic IAP bypass for games",
            icon: "bag.fill",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/LocalIAPStore/main/LocalIAPStore.dylib",
            fileName: "LocalIAPStore.dylib"
        ),
        
        // App-Specific Tweaks
        GameTweak(
            name: "Snapchat Phantom",
            description: "Enhanced Snapchat with saving features",
            icon: "camera.viewfinder",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/Phantom/main/Phantom.dylib",
            fileName: "Phantom.dylib"
        ),
        GameTweak(
            name: "Facebook++",
            description: "Enhanced Facebook with extra features",
            icon: "person.2.fill",
            downloadURL: "https://raw.githubusercontent.com/AhmedNaser1/FacebookPlusPlus/main/Facebook++.dylib",
            fileName: "Facebook++.dylib"
        )
    ]
    
    private let installedKey = "Ksign.gameTweaks.installed"
    
    private init() {
        loadInstalledState()
    }
    
    func loadInstalledState() {
        let installed = UserDefaults.standard.stringArray(forKey: installedKey) ?? []
        for i in tweaks.indices {
            tweaks[i].isInstalled = installed.contains(tweaks[i].fileName)
        }
    }
    
    func markAsInstalled(_ tweak: GameTweak) {
        var installed = UserDefaults.standard.stringArray(forKey: installedKey) ?? []
        if !installed.contains(tweak.fileName) {
            installed.append(tweak.fileName)
            UserDefaults.standard.set(installed, forKey: installedKey)
        }
        
        if let index = tweaks.firstIndex(where: { $0.id == tweak.id }) {
            tweaks[index].isInstalled = true
            tweaks[index].isDownloading = false
        }
    }
    
    func downloadTweak(_ tweak: GameTweak, completion: @escaping (URL?) -> Void) {
        guard let index = tweaks.firstIndex(where: { $0.id == tweak.id }) else {
            completion(nil)
            return
        }
        
        tweaks[index].isDownloading = true
        tweaks[index].progress = 0
        
        guard let url = URL(string: tweak.downloadURL) else {
            tweaks[index].isDownloading = false
            completion(nil)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let index = self.tweaks.firstIndex(where: { $0.id == tweak.id }) {
                    self.tweaks[index].isDownloading = false
                }
                
                if let error = error {
                    print("Download error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let localURL = localURL else {
                    completion(nil)
                    return
                }
                
                // Move to tweaks directory
                let tweaksDir = FileManager.default.tweaks
                try? FileManager.default.createDirectory(at: tweaksDir, withIntermediateDirectories: true)
                
                let destinationURL = tweaksDir.appendingPathComponent(tweak.fileName)
                
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    self.markAsInstalled(tweak)
                    completion(destinationURL)
                } catch {
                    print("Move error: \(error)")
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Game Tweaks View
struct GameTweaksView: View {
    @StateObject private var manager = GameTweaksManager.shared
    @State private var showDownloadAlert = false
    @State private var downloadingTweak: GameTweak?
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var searchText = ""
    
    private var filteredTweaks: [GameTweak] {
        if searchText.isEmpty {
            return manager.tweaks
        }
        return manager.tweaks.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NBNavigationView(.localized("Game Tweaks"), displayMode: .large) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card - Library style (no big circle icon)
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
                                
                                Image(systemName: "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("iOS Game Mods"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text(.localized("Download tweaks to inject into apps"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Stats Row
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(manager.tweaks.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(.localized("Available"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("\(manager.tweaks.filter { $0.isInstalled }.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(.localized("Installed"))
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
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(.localized("Search tweaks..."), text: $searchText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Tweaks Grid
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTweaks) { tweak in
                            GameTweakCard(
                                tweak: tweak,
                                onDownload: {
                                    downloadingTweak = tweak
                                    showDownloadAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // How to Use Card - Library style
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("How to use"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(.localized("Follow these steps to use tweaks"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack(spacing: 16) {
                            _stepBadge(number: 1, text: .localized("Download"))
                            _stepBadge(number: 2, text: .localized("Sign App"))
                            _stepBadge(number: 3, text: .localized("Enable"))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .alert(.localized("Download Tweak"), isPresented: $showDownloadAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Download")) {
                if let tweak = downloadingTweak {
                    manager.downloadTweak(tweak) { url in
                        if url != nil {
                            showSuccessAlert = true
                        } else {
                            showErrorAlert = true
                        }
                    }
                }
            }
        } message: {
            if let tweak = downloadingTweak {
                Text(.localized("Download \(tweak.name) to your Tweaks folder?"))
            }
        }
        .alert(.localized("Success!"), isPresented: $showSuccessAlert) {
            Button(.localized("OK")) { }
        } message: {
            Text(.localized("Tweak downloaded successfully. You can now use it when signing apps."))
        }
        .alert(.localized("Download Failed"), isPresented: $showErrorAlert) {
            Button(.localized("OK")) { }
        } message: {
            Text(.localized("Failed to download the tweak. Please check your internet connection and try again."))
        }
    }
    
    @ViewBuilder
    private func _statCard(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    @ViewBuilder
    private func _stepRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func _stepBadge(number: Int, text: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Game Tweak Cell
struct GameTweakCell: View {
    let tweak: GameTweak
    let onDownload: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(tweak.isInstalled ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: tweak.icon)
                    .font(.title3)
                    .foregroundColor(tweak.isInstalled ? .green : .blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tweak.name)
                    .fontWeight(.semibold)
                
                Text(tweak.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Button
            if tweak.isDownloading {
                ProgressView()
            } else if tweak.isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button {
                    onDownload()
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Game Tweak Card (Premium)
struct GameTweakCard: View {
    let tweak: GameTweak
    let onDownload: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon with gradient background - iOS 26 Style
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: tweak.isInstalled ? [.green.opacity(0.8), .mint] : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: tweak.isInstalled ? .green.opacity(0.3) : .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: tweak.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tweak.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(tweak.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Button
            if tweak.isDownloading {
                ProgressView()
                    .tint(.accentColor)
            } else if tweak.isInstalled {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text(.localized("Installed"))
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else {
                Button {
                    onDownload()
                } label: {
                    Text(.localized("Get"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview
#Preview {
    GameTweaksView()
}
