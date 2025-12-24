//
//  TweakEligibilityView.swift
//  Ksign
//
//  Regional eligibility tweaks.
//

#if os(iOS)
import SwiftUI

struct TweakEligibilityView: View {
    // EU Eligibility
    @State private var enableEUFeatures: Bool = false
    @State private var enableAltStores: Bool = false
    @State private var enableSideloading: Bool = false
    
    // Region Features
    @State private var disableShutterSound: Bool = false
    @State private var enableInternationalCallID: Bool = false
    
    // Apple Intelligence
    @State private var enableAIEligibility: Bool = false
    @State private var enableWritingTools: Bool = false
    @State private var enableImagePlayground: Bool = false
    
    var body: some View {
        List {
            // EU Section
            euSection
            
            // Region Section
            regionSection
            
            // AI Eligibility Section
            aiEligibilitySection
            
            // Info Section
            infoSection
        }
        .navigationTitle(.localized("Eligibility"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - EU Section
    
    private var euSection: some View {
        Section {
            Toggle(isOn: $enableEUFeatures) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("EU Features"))
                        .font(.body)
                    Text(.localized("Enable EU-exclusive features"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableAltStores) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Alternative App Stores"))
                        .font(.body)
                    Text(.localized("Enable third-party app store support"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableSideloading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("App Sideloading"))
                        .font(.body)
                    Text(.localized("Enable web-based app sideloading"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("European Union"), systemImage: "globe.europe.africa.fill")
        } footer: {
            Text(.localized("These features are normally restricted to EU devices under the Digital Markets Act."))
        }
    }
    
    // MARK: - Region Section
    
    private var regionSection: some View {
        Section {
            Toggle(isOn: $disableShutterSound) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Disable Shutter Sound"))
                        .font(.body)
                    Text(.localized("Remove camera shutter sound (region-locked)"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableInternationalCallID) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("International Caller ID"))
                        .font(.body)
                    Text(.localized("Enable caller ID lookup in all regions"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("Region Features"), systemImage: "globe")
        }
    }
    
    // MARK: - AI Eligibility Section
    
    private var aiEligibilitySection: some View {
        Section {
            Toggle(isOn: $enableAIEligibility) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Apple Intelligence Eligibility"))
                        .font(.body)
                    Text(.localized("Mark device as eligible for Apple Intelligence"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableWritingTools) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Writing Tools"))
                        .font(.body)
                    Text(.localized("Enable AI writing tools"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $enableImagePlayground) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Image Playground"))
                        .font(.body)
                    Text(.localized("Enable AI image generation"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(.localized("Apple Intelligence"), systemImage: "brain.head.profile")
        } footer: {
            Text(.localized("AI features require iOS 18.1+ and may not work on all device configurations."))
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("About Eligibility"))
                        .font(.subheadline.weight(.medium))
                    Text(.localized("Eligibility tweaks modify system files to enable region-locked or device-restricted features. Changes require Nugget to apply."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Legal Notice"))
                        .font(.subheadline.weight(.medium))
                    Text(.localized("Enabling region-locked features may violate local laws or Apple's terms of service."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        TweakEligibilityView()
    }
}
#endif
