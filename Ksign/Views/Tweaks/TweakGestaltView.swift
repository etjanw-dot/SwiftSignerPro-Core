//
//  TweakGestaltView.swift
//  Ksign
//
//  Mobile Gestalt tweaks - Dynamic Island, device features, and gestures.
//

#if os(iOS)
import SwiftUI

// MARK: - Gestalt Tweak Model
struct GestaltTweak: Identifiable {
    var id = UUID()
    var label: String
    var description: String
    var keys: [String]
    var values: [Any]
    var isEnabled: Bool = false
    var minVersion: Double = 15.0
    var isRisky: Bool = false
}

// MARK: - Device SubType
struct DeviceSubType: Identifiable {
    var id = UUID()
    var key: Int
    var title: String
    var minVersion: Double = 16.0
}

struct TweakGestaltView: View {
    @State private var currentSubType: Int = -1
    @State private var currentSubTypeDisplay: String = "Default"
    @State private var showSubTypePicker = false
    
    @State private var deviceModelName: String = ""
    @State private var deviceModelEnabled: Bool = false
    
    @State private var showApplyAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let systemVersion = Double(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0
    
    // Device subtypes for Dynamic Island
    private let deviceSubTypes: [DeviceSubType] = [
        .init(key: -1, title: "Default"),
        .init(key: 2436, title: "iPhone X Gestures"),
        .init(key: 2556, title: "iPhone 14 Pro Dynamic Island"),
        .init(key: 2796, title: "iPhone 14 Pro Max Dynamic Island"),
        .init(key: 2976, title: "iPhone 15 Pro Max Dynamic Island", minVersion: 17.0),
        .init(key: 2622, title: "iPhone 16 Pro Dynamic Island", minVersion: 18.0),
        .init(key: 2868, title: "iPhone 16 Pro Max Dynamic Island", minVersion: 18.0)
    ]
    
    // Basic tweaks
    @State private var tweaks: [GestaltTweak] = [
        GestaltTweak(
            label: "Boot Chime",
            description: "Enable the Mac-style boot chime",
            keys: ["QHxt+hGLaBPbQJbXiUJX3w"],
            values: [1]
        ),
        GestaltTweak(
            label: "Charge Limit",
            description: "Enable 80% charge limit option",
            keys: ["37NVydb//GP/GrhuTN+exg"],
            values: [1]
        ),
        GestaltTweak(
            label: "Collision SOS",
            description: "Enable crash detection feature",
            keys: ["HCzWusHQwZDea6nNhaKndw"],
            values: [1]
        ),
        GestaltTweak(
            label: "Tap to Wake",
            description: "Enable tap to wake on iPhone SE",
            keys: ["yZf3GTRMGTuwSV/lD7Cagw"],
            values: [1]
        ),
        GestaltTweak(
            label: "Camera Button Settings",
            description: "Enable iPhone 16 Camera Button",
            keys: ["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"],
            values: [1, 1],
            minVersion: 18.0
        ),
        GestaltTweak(
            label: "Disable Wallpaper Parallax",
            description: "Remove parallax effect on wallpapers",
            keys: ["UIParallaxCapability"],
            values: [0]
        ),
        GestaltTweak(
            label: "Stage Manager",
            description: "Enable Stage Manager (risky on phones)",
            keys: ["qeaj75wk3HF4DwQ8qbIi7g"],
            values: [1],
            isRisky: true
        ),
        GestaltTweak(
            label: "iPad Multitasking",
            description: "Enable Medusa multitasking (risky)",
            keys: ["mG0AnH/Vy1veoqoLRAIgTA", "UCG5MkVahJxG1YULbbd5Bg", "ZYqko/XM5zD3XBfN5RmaXA", "nVh/gwNpy7Jv1NOk00CMrw", "uKc7FPnEO++lVhHWHFlGbQ"],
            values: [1, 1, 1, 1, 1],
            isRisky: true
        ),
        GestaltTweak(
            label: "Apple Pencil Support",
            description: "Enable Apple Pencil on unsupported devices",
            keys: ["yhHcB0iH0d1XzPO/CFd3ow"],
            values: [1]
        ),
        GestaltTweak(
            label: "Action Button",
            description: "Enable Action Button settings",
            keys: ["cT44WE1EohiwRzhsZ8xEsw"],
            values: [1]
        ),
        GestaltTweak(
            label: "Internal Storage",
            description: "Toggle internal storage (risky on iPads)",
            keys: ["LBJfwOEzExRxzlAnSuI7eg"],
            values: [1],
            isRisky: true
        ),
        GestaltTweak(
            label: "Apple Internal Install",
            description: "Enable Metal HUD in any app",
            keys: ["EqrsVvjcYDdxHBiQmGhAWw"],
            values: [1]
        ),
        GestaltTweak(
            label: "Always On Display",
            description: "Enable AOD on supported devices",
            keys: ["2OOJf1VhaM7NxfRok3HbWQ", "j8/Omm6s1lsmTDFsXjsBfA"],
            values: [1, 1],
            minVersion: 18.0
        )
    ]
    
    var body: some View {
        List {
            // Dynamic Island Section
            dynamicIslandSection
            
            // Device Model Section
            deviceModelSection
            
            // Feature Tweaks
            featureTweaksSection
            
            // Risky Tweaks
            riskyTweaksSection
            
            // Info Section
            infoSection
        }
        .navigationTitle(.localized("Mobile Gestalt"))
        .navigationBarTitleDisplayMode(.large)
        .alert(alertTitle, isPresented: $showApplyAlert) {
            Button(.localized("OK"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(.localized("Select Device Type"), isPresented: $showSubTypePicker, titleVisibility: .visible) {
            ForEach(deviceSubTypes.filter { systemVersion >= $0.minVersion }) { subType in
                Button(subType.title) {
                    currentSubType = subType.key
                    currentSubTypeDisplay = subType.title
                    saveGestaltTweak(key: "ArtworkDeviceSubType", value: subType.key)
                }
            }
            Button(.localized("Cancel"), role: .cancel) { }
        }
    }
    
    // MARK: - Dynamic Island Section
    
    private var dynamicIslandSection: some View {
        Section {
            Button {
                showSubTypePicker = true
            } label: {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Gestures / Dynamic Island"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(currentSubTypeDisplay)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Label(.localized("Device Type"), systemImage: "apps.iphone")
        } footer: {
            Text(.localized("Change device type to enable Dynamic Island or iPhone X gestures."))
        }
    }
    
    // MARK: - Device Model Section
    
    private var deviceModelSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(.localized("Custom Device Model Name"), isOn: $deviceModelEnabled)
                    .onChange(of: deviceModelEnabled) { newValue in
                        if newValue && !deviceModelName.isEmpty {
                            saveGestaltTweak(key: "ArtworkDeviceProductDescription", value: deviceModelName)
                        } else {
                            removeGestaltTweak(key: "ArtworkDeviceProductDescription")
                        }
                    }
                
                if deviceModelEnabled {
                    TextField(.localized("Device Model Name"), text: $deviceModelName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: deviceModelName) { newValue in
                            if deviceModelEnabled && !newValue.isEmpty {
                                saveGestaltTweak(key: "ArtworkDeviceProductDescription", value: newValue)
                            }
                        }
                }
            }
        } header: {
            Label(.localized("Device Model"), systemImage: "textformat")
        }
    }
    
    // MARK: - Feature Tweaks Section
    
    private var featureTweaksSection: some View {
        Section {
            ForEach($tweaks.filter { !$0.isRisky.wrappedValue && systemVersion >= $0.minVersion.wrappedValue }) { $tweak in
                Toggle(isOn: $tweak.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized(tweak.label))
                            .font(.body)
                        Text(.localized(tweak.description))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: tweak.isEnabled) { newValue in
                    if newValue {
                        for (index, key) in tweak.keys.enumerated() {
                            saveGestaltTweak(key: key, value: tweak.values[index])
                        }
                    } else {
                        for key in tweak.keys {
                            removeGestaltTweak(key: key)
                        }
                    }
                }
            }
        } header: {
            Label(.localized("Features"), systemImage: "star.fill")
        }
    }
    
    // MARK: - Risky Tweaks Section
    
    private var riskyTweaksSection: some View {
        Section {
            ForEach($tweaks.filter { $0.isRisky.wrappedValue && systemVersion >= $0.minVersion.wrappedValue }) { $tweak in
                Toggle(isOn: $tweak.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(.localized(tweak.label))
                                .font(.body)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        Text(.localized(tweak.description))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: tweak.isEnabled) { newValue in
                    if newValue {
                        for (index, key) in tweak.keys.enumerated() {
                            saveGestaltTweak(key: key, value: tweak.values[index])
                        }
                    } else {
                        for key in tweak.keys {
                            removeGestaltTweak(key: key)
                        }
                    }
                }
            }
        } header: {
            Label(.localized("Advanced (Risky)"), systemImage: "exclamationmark.triangle.fill")
        } footer: {
            Text(.localized("These tweaks may cause issues on some devices. Use with caution."))
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Requires Nugget"))
                        .font(.subheadline.weight(.medium))
                    Text(.localized("These tweaks require Nugget Mobile or Nugget Desktop to apply. Toggle the options you want, then use Nugget to apply changes."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveGestaltTweak(key: String, value: Any) {
        // Save to UserDefaults for now - will be picked up by Nugget
        var savedTweaks = UserDefaults.standard.dictionary(forKey: "Ksign.gestalt.tweaks") ?? [:]
        savedTweaks[key] = value
        UserDefaults.standard.set(savedTweaks, forKey: "Ksign.gestalt.tweaks")
    }
    
    private func removeGestaltTweak(key: String) {
        var savedTweaks = UserDefaults.standard.dictionary(forKey: "Ksign.gestalt.tweaks") ?? [:]
        savedTweaks.removeValue(forKey: key)
        UserDefaults.standard.set(savedTweaks, forKey: "Ksign.gestalt.tweaks")
    }
}

#Preview {
    NavigationStack {
        TweakGestaltView()
    }
}
#endif
