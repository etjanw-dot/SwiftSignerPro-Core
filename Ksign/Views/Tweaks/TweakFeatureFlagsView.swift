//
//  TweakFeatureFlagsView.swift
//  Ksign
//
//  iOS Feature Flags tweaks (iOS 18.0+).
//

#if os(iOS)
import SwiftUI

struct TweakFeatureFlagsView: View {
    // AI Features
    @State private var enableAppleIntelligence: Bool = false
    @State private var enableSiriAI: Bool = false
    
    // UI Features
    @State private var enableNewPhotosUI: Bool = false
    @State private var enableNewSettingsUI: Bool = false
    
    // System Features
    @State private var enableRCS: Bool = false
    @State private var enableSatellite: Bool = false
    @State private var enableCarKey: Bool = false
    
    // Developer Features
    @State private var enableInternalUI: Bool = false
    @State private var enableDebugSettings: Bool = false
    
    private let minVersion: Double = 18.0
    private let systemVersion = Double(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0
    
    var body: some View {
        List {
            if systemVersion >= minVersion {
                // AI Features Section
                aiSection
                
                // UI Features Section
                uiSection
                
                // System Features Section
                systemSection
                
                // Developer Section
                developerSection
                
                // Info Section
                infoSection
            } else {
                notSupportedSection
            }
        }
        .navigationTitle(.localized("Feature Flags"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - AI Section
    
    private var aiSection: some View {
        Section {
            Toggle(isOn: $enableAppleIntelligence) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Apple Intelligence"))
                        .font(.body)
                    Text(.localized("Enable Apple Intelligence on unsupported devices"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableSiriAI) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Siri AI Features"))
                        .font(.body)
                    Text(.localized("Enable advanced Siri AI capabilities"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("AI Features"), systemImage: "brain.head.profile")
        }
    }
    
    // MARK: - UI Section
    
    private var uiSection: some View {
        Section {
            Toggle(isOn: $enableNewPhotosUI) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("New Photos UI"))
                        .font(.body)
                    Text(.localized("Enable the redesigned Photos app interface"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableNewSettingsUI) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("New Settings UI"))
                        .font(.body)
                    Text(.localized("Enable experimental Settings redesign"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("UI Features"), systemImage: "paintbrush.fill")
        }
    }
    
    // MARK: - System Section
    
    private var systemSection: some View {
        Section {
            Toggle(isOn: $enableRCS) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("RCS Messaging"))
                        .font(.body)
                    Text(.localized("Enable RCS messaging support"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableSatellite) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Satellite Features"))
                        .font(.body)
                    Text(.localized("Enable satellite connectivity features"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableCarKey) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Car Key"))
                        .font(.body)
                    Text(.localized("Enable Car Key in Wallet"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("System Features"), systemImage: "gearshape.fill")
        }
    }
    
    // MARK: - Developer Section
    
    private var developerSection: some View {
        Section {
            Toggle(isOn: $enableInternalUI) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Internal UI Elements"))
                        .font(.body)
                    Text(.localized("Show internal Apple UI elements"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableDebugSettings) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Debug Settings"))
                        .font(.body)
                    Text(.localized("Enable debug settings menus"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("Developer"), systemImage: "hammer.fill")
        } footer: {
            Text(.localized("These options are intended for advanced users."))
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Experimental"))
                        .font(.subheadline.weight(.medium))
                    Text(.localized("Feature flags control experimental iOS features. Some may not work on all devices or iOS versions."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Not Supported Section
    
    private var notSupportedSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                Text(.localized("iOS 18.0+ Required"))
                    .font(.headline)
                
                Text(.localized("Feature Flags are only available on iOS 18.0 and later."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}

#Preview {
    NavigationStack {
        TweakFeatureFlagsView()
    }
}
#endif
