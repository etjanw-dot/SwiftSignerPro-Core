//
//  TabHapticSettingsView.swift
//  Ksign
//
//  Tab order, visibility, and haptic feedback settings.
//

import SwiftUI
import NimbleViews

// MARK: - Haptic Intensity
enum HapticIntensity: String, CaseIterable, Codable {
    case off = "Off"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case highest = "Highest"
    
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .off: return nil
        case .low: return .light
        case .medium: return .medium
        case .high: return .heavy
        case .highest: return .rigid
        }
    }
    
    var color: Color {
        switch self {
        case .off: return .secondary
        case .low: return .blue
        case .medium: return .blue
        case .high: return .orange
        case .highest: return .red
        }
    }
    
    var intensityIndicator: String {
        switch self {
        case .off: return ""
        case .low: return "▂ ‥ ‥"
        case .medium: return "▂ ▄ ‥"
        case .high: return "▂ ▄ ▆"
        case .highest: return "▂ ▄ ▆ ▇"
        }
    }
}

// MARK: - Tab Visibility Config
struct TabVisibilityConfig: Codable {
    var repos: Bool = true
    var apps: Bool = true
    var home: Bool = true
    var library: Bool = true
    var tweaks: Bool = true // Default tab, always shown
    var settings: Bool = true // Always required
    var certificates: Bool = false // Optional, off by default
    var files: Bool = false // Optional, off by default
    var ai: Bool = false // Optional, off by default
    
    func isEnabled(_ tab: TabEnum) -> Bool {
        switch tab {
        case .repos: return repos
        case .apps: return apps
        case .home: return home
        case .library: return library
        case .tweaks: return true // Always enabled
        case .settings: return true // Always enabled
        case .certificates: return certificates
        case .files: return files
        case .ai: return ai
        }
    }
}

// MARK: - Tab Settings Manager
class TabSettingsManager: ObservableObject {
    static let shared = TabSettingsManager()
    
    @Published var defaultTab: TabEnum = .home
    @Published var tabVisibility: TabVisibilityConfig = TabVisibilityConfig()
    @Published var tabOrder: [TabEnum] = TabEnum.defaultTabs
    @Published var hapticIntensity: HapticIntensity = .medium
    
    private let defaultTabKey = "Ksign.tabs.defaultTab"
    private let visibilityKey = "Ksign.tabs.visibility"
    private let orderKey = "Ksign.tabs.order"
    private let hapticKey = "Ksign.haptic.intensity"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Load / Save
    
    func loadSettings() {
        // Load default tab
        if let savedDefault = UserDefaults.standard.string(forKey: defaultTabKey),
           let tab = TabEnum(rawValue: savedDefault) {
            defaultTab = tab
        }
        
        // Load visibility
        if let data = UserDefaults.standard.data(forKey: visibilityKey),
           let visibility = try? JSONDecoder().decode(TabVisibilityConfig.self, from: data) {
            tabVisibility = visibility
        }
        
        // Load order
        if let savedOrder = UserDefaults.standard.stringArray(forKey: orderKey) {
            tabOrder = savedOrder.compactMap { TabEnum(rawValue: $0) }
            // Ensure all default tabs are present
            for tab in TabEnum.defaultTabs {
                if !tabOrder.contains(tab) {
                    tabOrder.append(tab)
                }
            }
        }
        
        // Load haptic intensity
        if let savedHaptic = UserDefaults.standard.string(forKey: hapticKey),
           let intensity = HapticIntensity(rawValue: savedHaptic) {
            hapticIntensity = intensity
        }
    }
    
    func saveSettings() {
        // Save default tab
        UserDefaults.standard.set(defaultTab.rawValue, forKey: defaultTabKey)
        
        // Save visibility
        if let data = try? JSONEncoder().encode(tabVisibility) {
            UserDefaults.standard.set(data, forKey: visibilityKey)
        }
        
        // Save order
        UserDefaults.standard.set(tabOrder.map { $0.rawValue }, forKey: orderKey)
        
        // Save haptic intensity
        UserDefaults.standard.set(hapticIntensity.rawValue, forKey: hapticKey)
    }
    
    // MARK: - Tab Management
    
    func toggleTab(_ tab: TabEnum) {
        guard tab != .settings && tab != .tweaks else { return } // Settings and Tweaks are always enabled
        
        switch tab {
        case .repos:
            tabVisibility.repos.toggle()
        case .apps:
            tabVisibility.apps.toggle()
        case .home:
            tabVisibility.home.toggle()
        case .library:
            tabVisibility.library.toggle()
        case .certificates:
            tabVisibility.certificates.toggle()
        case .files:
            tabVisibility.files.toggle()
        case .ai:
            tabVisibility.ai.toggle()
        case .tweaks, .settings:
            break // Always enabled
        }
        
        saveSettings()
    }
    
    func moveTab(from source: IndexSet, to destination: Int) {
        tabOrder.move(fromOffsets: source, toOffset: destination)
        saveSettings()
    }
    
    func resetToDefault() {
        defaultTab = .home
        tabVisibility = TabVisibilityConfig()
        tabOrder = TabEnum.defaultTabs
        hapticIntensity = .medium
        saveSettings()
    }
    
    // MARK: - Haptic Feedback
    
    func triggerHaptic() {
        guard let style = hapticIntensity.feedbackStyle else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func setHapticIntensity(_ intensity: HapticIntensity) {
        hapticIntensity = intensity
        saveSettings()
        triggerHaptic()
    }
    
    // MARK: - Helpers
    
    var enabledTabs: [TabEnum] {
        // Get base tabs that are enabled
        var enabled = tabOrder.filter { tabVisibility.isEnabled($0) }
        
        // Add customizable tabs at the end if they're enabled but not in order
        for tab in TabEnum.customizableTabs {
            if tabVisibility.isEnabled(tab) && !enabled.contains(tab) {
                enabled.append(tab)
            }
        }
        
        return enabled
    }
}

// MARK: - Tab & Haptic Settings View
struct TabHapticSettingsView: View {
    @StateObject private var manager = TabSettingsManager.shared
    @State private var showResetAlert = false
    
    var body: some View {
        NBList(.localized("Tab & Haptic Settings")) {
            // Default Tab Section
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.accentColor)
                        Text(.localized("Default Tab"))
                            .fontWeight(.medium)
                    }
                    Text(.localized("Choose which tab opens when the app launches"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Picker(.localized("Default Tab"), selection: $manager.defaultTab) {
                    ForEach(manager.enabledTabs, id: \.self) { tab in
                        HStack {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .tag(tab)
                    }
                }
                .onChange(of: manager.defaultTab) { _ in
                    manager.saveSettings()
                }
                
                Button {
                    manager.triggerHaptic()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.accentColor)
                        Text(.localized("Switch to Default Tab Now"))
                            .foregroundColor(.accentColor)
                    }
                }
            } header: {
                Text(.localized("Default Tab"))
            }
            
            // Tab Order & Visibility Section
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text(.localized("Reorder Tabs"))
                            .fontWeight(.medium)
                    }
                    Text(.localized("Drag to reorder tabs or toggle visibility"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(manager.tabOrder, id: \.self) { tab in
                    HStack {
                        Image(systemName: tab.icon)
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        Text(tab.title)
                        
                        Spacer()
                        
                        if tab == .settings {
                            Text(.localized("Required"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        } else {
                            Button {
                                manager.toggleTab(tab)
                                manager.triggerHaptic()
                            } label: {
                                Image(systemName: manager.tabVisibility.isEnabled(tab) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(manager.tabVisibility.isEnabled(tab) ? .green : .secondary)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: manager.moveTab)
            } header: {
                Text(.localized("Tab Order & Visibility"))
            }
            
            // Optional Tabs Section
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                        Text(.localized("Extra Tabs"))
                            .fontWeight(.medium)
                    }
                    Text(.localized("Enable additional tabs that are hidden by default"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Files Tab Toggle
                HStack {
                    Image(systemName: TabEnum.files.icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TabEnum.files.title)
                        Text(.localized("Browse and manage files"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { manager.tabVisibility.files },
                        set: { _ in
                            manager.toggleTab(.files)
                            manager.triggerHaptic()
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 4)
                
                // Certificates Tab Toggle
                HStack {
                    Image(systemName: TabEnum.certificates.icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TabEnum.certificates.title)
                        Text(.localized("Manage signing certificates"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { manager.tabVisibility.certificates },
                        set: { _ in
                            manager.toggleTab(.certificates)
                            manager.triggerHaptic()
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 4)
                
                // AI Tab Toggle
                HStack {
                    Image(systemName: TabEnum.ai.icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TabEnum.ai.title)
                        Text(.localized("AI Chat and Speech tools"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { manager.tabVisibility.ai },
                        set: { _ in
                            manager.toggleTab(.ai)
                            manager.triggerHaptic()
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 4)
            } header: {
                Text(.localized("Optional Tabs"))
            } footer: {
                Text(.localized("These tabs are hidden by default. Enable them to add extra functionality to your tab bar."))
            }
            
            // Haptic Feedback Section
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(.orange)
                        Text(.localized("Haptic Feedback"))
                            .fontWeight(.medium)
                    }
                    Text(.localized("Control the intensity of haptic feedback when switching tabs"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                    Button {
                        manager.setHapticIntensity(intensity)
                    } label: {
                        HStack {
                            Image(systemName: manager.hapticIntensity == intensity ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(manager.hapticIntensity == intensity ? .blue : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(intensity.rawValue)
                                    .foregroundColor(.primary)
                                
                                if !intensity.intensityIndicator.isEmpty {
                                    Text(intensity.intensityIndicator)
                                        .font(.caption)
                                        .foregroundColor(intensity.color)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(.localized("Feedback Settings"))
            }
            
            // Reset Section
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundColor(.red)
                        Text(.localized("Reset to Default"))
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text(.localized("Reset"))
            } footer: {
                Text(.localized("This will restore the original tab order, enable all tabs, set App Store as default, and reset haptic feedback to medium."))
            }
        }
        .environment(\.editMode, .constant(.active))
        .alert(.localized("Reset to Default"), isPresented: $showResetAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                manager.resetToDefault()
            }
        } message: {
            Text(.localized("This will reset all tab settings to their default values."))
        }
    }
}

// MARK: - Preview
#Preview {
    TabHapticSettingsView()
}
