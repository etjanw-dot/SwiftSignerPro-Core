//
//  TweaksView.swift
//  Ksign
//
//  Main Tweaks tab with categories for various device tweaks and customizations.
//

#if os(iOS)
import SwiftUI
import NimbleViews

// MARK: - Tweak Category
enum TweakCategory: String, CaseIterable, Identifiable {
    case wallpaper = "Wallpaper"
    case gestalt = "Mobile Gestalt"
    case statusBar = "Status Bar"
    case springboard = "SpringBoard"
    case featureFlags = "Feature Flags"
    case eligibility = "Eligibility"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .wallpaper: return .localized("Wallpaper")
        case .gestalt: return .localized("Mobile Gestalt")
        case .statusBar: return .localized("Status Bar")
        case .springboard: return .localized("SpringBoard")
        case .featureFlags: return .localized("Feature Flags")
        case .eligibility: return .localized("Eligibility")
        }
    }
    
    var icon: String {
        switch self {
        case .wallpaper: return "photo.artframe"
        case .gestalt: return "cpu"
        case .statusBar: return "rectangle.topthird.inset.filled"
        case .springboard: return "apps.iphone"
        case .featureFlags: return "flag.fill"
        case .eligibility: return "checkmark.seal.fill"
        }
    }
    
    var description: String {
        switch self {
        case .wallpaper: return .localized("Custom wallpapers via Nugget")
        case .gestalt: return .localized("Device features & Dynamic Island")
        case .statusBar: return .localized("Customize status bar elements")
        case .springboard: return .localized("SpringBoard UI tweaks")
        case .featureFlags: return .localized("iOS feature flags")
        case .eligibility: return .localized("Regional feature eligibility")
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .wallpaper: return [.orange, .pink]
        case .gestalt: return [.blue, .purple]
        case .statusBar: return [.green, .mint]
        case .springboard: return [.cyan, .blue]
        case .featureFlags: return [.red, .orange]
        case .eligibility: return [.purple, .pink]
        }
    }
    
    var minVersion: Double {
        switch self {
        case .featureFlags: return 18.0
        default: return 15.0
        }
    }
}

// MARK: - Tweaks View
struct TweaksView: View {
    @State private var selectedCategory: TweakCategory?
    @State private var showingApplyAlert = false
    @State private var showingRespringConfirm = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let systemVersion = Double(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0
    
    var body: some View {
        NBNavigationView(.localized("Tweaks")) {
            List {
                // Header Section
                headerSection
                
                // Quick Actions Section
                actionsSection
                
                // Categories Section
                categoriesSection
                
                // Info Section
                infoSection
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingRespringConfirm = true
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .confirmationDialog(.localized("Respring Device"), isPresented: $showingRespringConfirm, titleVisibility: .visible) {
                Button(.localized("Respring Now"), role: .destructive) {
                    performRespring()
                }
                Button(.localized("Cancel"), role: .cancel) { }
            } message: {
                Text(.localized("This will restart SpringBoard. Any unsaved work may be lost."))
            }
            .alert(alertTitle, isPresented: $showingApplyAlert) {
                Button(.localized("OK"), role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("Device Tweaks"))
                            .font(.headline)
                        Text(.localized("Customize your iOS device"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(.localized("Select a category below to access different tweaks. Some features require specific iOS versions or Nugget connection."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        Section {
            ForEach(TweakCategory.allCases) { category in
                if systemVersion >= category.minVersion {
                    NavigationLink {
                        destinationView(for: category)
                    } label: {
                        categoryRow(for: category)
                    }
                }
            }
        } header: {
            Label(.localized("Categories"), systemImage: "square.grid.2x2.fill")
        }
    }
    
    private func categoryRow(for category: TweakCategory) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: category.gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: category.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func destinationView(for category: TweakCategory) -> some View {
        switch category {
        case .wallpaper:
            TweakWallpaperView()
        case .gestalt:
            TweakGestaltView()
        case .statusBar:
            TweakStatusBarView()
        case .springboard:
            TweakSpringBoardView()
        case .featureFlags:
            TweakFeatureFlagsView()
        case .eligibility:
            TweakEligibilityView()
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("About Tweaks"))
                            .font(.subheadline.weight(.medium))
                        Text(.localized("These tweaks use various iOS exploits to modify system files. Some may require a reboot or respiring to take effect."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("Caution"))
                            .font(.subheadline.weight(.medium))
                        Text(.localized("Some tweaks may be risky. Always create a backup before applying major changes."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label(.localized("Information"), systemImage: "lightbulb.fill")
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            // Respring Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingRespringConfirm = true
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.2), .red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Respring"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(.localized("Restart SpringBoard to apply changes"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Userspace Reboot Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                performUserspaceReboot()
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.2), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "power.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Userspace Reboot"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(.localized("Soft reboot without losing jailbreak"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label(.localized("Quick Actions"), systemImage: "bolt.fill")
        } footer: {
            Text(.localized("Use these actions after configuring your tweaks."))
        }
    }
    
    // MARK: - Functions
    
    private func performRespring() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Method 1: Kill SpringBoard via Darwin notification
        let notifyName = "com.apple.SpringBoard.relaunch" as CFString
        var notifyToken: Int32 = 0
        notify_register_check(notifyName as String, &notifyToken)
        notify_post(notifyName as String)
        
        // Method 2: Alternative using posix_spawn to kill backboardd
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fallback: Try to terminate via exit
            guard let workspace = objc_getClass("LSApplicationWorkspace") as? NSObject else { return }
            let ws = workspace.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject
            ws?.perform(Selector(("openApplicationWithBundleID:")), with: "com.apple.springboard")
        }
    }
    
    private func performUserspaceReboot() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Attempt userspace reboot
        let result = reboot3(0x400) // RB2_USERREBOOT
        if result != 0 {
            alertTitle = .localized("Reboot Failed")
            alertMessage = .localized("Could not perform userspace reboot. This may require additional privileges.")
            showingApplyAlert = true
        }
    }
}

// Helper function declarations
@_silgen_name("notify_register_check")
func notify_register_check(_ name: String, _ out_token: UnsafeMutablePointer<Int32>) -> UInt32

@_silgen_name("notify_post")
func notify_post(_ name: String) -> UInt32

@_silgen_name("reboot3")
func reboot3(_ flags: Int32) -> Int32

// MARK: - Preview
#Preview {
    TweaksView()
}
#endif
