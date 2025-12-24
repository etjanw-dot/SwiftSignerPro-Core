//
//  TweakSpringBoardView.swift
//  Ksign
//
//  SpringBoard UI customization tweaks.
//

#if os(iOS)
import SwiftUI

struct TweakSpringBoardView: View {
    // Lock Screen
    @State private var hideLockScreenCC: Bool = false
    @State private var hideLockScreenFlashlight: Bool = false
    @State private var hideLockScreenCamera: Bool = false
    @State private var disableLockAfterRespring: Bool = false
    
    // Home Screen
    @State private var hideHomeBar: Bool = false
    @State private var hideFolderBackground: Bool = false
    @State private var hideDockBackground: Bool = false
    @State private var disablePageDots: Bool = false
    
    // App Library
    @State private var hideAppLibrary: Bool = false
    @State private var hideRecentApps: Bool = false
    @State private var hideSuggestions: Bool = false
    
    // Notifications
    @State private var hideNotificationBadges: Bool = false
    @State private var silentScreenshots: Bool = false
    
    // Other
    @State private var disableLockScreenWallpaperBlur: Bool = false
    @State private var hideSpotlight: Bool = false
    
    var body: some View {
        List {
            // Lock Screen Section
            lockScreenSection
            
            // Home Screen Section
            homeScreenSection
            
            // App Library Section
            appLibrarySection
            
            // Notifications Section
            notificationsSection
            
            // Other Section
            otherSection
            
            // Info Section
            infoSection
        }
        .navigationTitle(.localized("SpringBoard"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Lock Screen Section
    
    private var lockScreenSection: some View {
        Section {
            Toggle(.localized("Hide Control Center Access"), isOn: $hideLockScreenCC)
            Toggle(.localized("Hide Flashlight Button"), isOn: $hideLockScreenFlashlight)
            Toggle(.localized("Hide Camera Button"), isOn: $hideLockScreenCamera)
            Toggle(.localized("Disable Lock After Respring"), isOn: $disableLockAfterRespring)
        } header: {
            Label(.localized("Lock Screen"), systemImage: "lock.fill")
        }
    }
    
    // MARK: - Home Screen Section
    
    private var homeScreenSection: some View {
        Section {
            Toggle(.localized("Hide Home Bar"), isOn: $hideHomeBar)
            Toggle(.localized("Hide Folder Background"), isOn: $hideFolderBackground)
            Toggle(.localized("Hide Dock Background"), isOn: $hideDockBackground)
            Toggle(.localized("Disable Page Dots"), isOn: $disablePageDots)
        } header: {
            Label(.localized("Home Screen"), systemImage: "apps.iphone")
        }
    }
    
    // MARK: - App Library Section
    
    private var appLibrarySection: some View {
        Section {
            Toggle(.localized("Hide App Library"), isOn: $hideAppLibrary)
            Toggle(.localized("Hide Recent Apps"), isOn: $hideRecentApps)
            Toggle(.localized("Hide Suggestions"), isOn: $hideSuggestions)
        } header: {
            Label(.localized("App Library"), systemImage: "square.grid.3x3.fill")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Toggle(.localized("Hide Notification Badges"), isOn: $hideNotificationBadges)
            Toggle(.localized("Silent Screenshots"), isOn: $silentScreenshots)
        } header: {
            Label(.localized("Notifications"), systemImage: "bell.fill")
        }
    }
    
    // MARK: - Other Section
    
    private var otherSection: some View {
        Section {
            Toggle(.localized("Disable Lock Screen Blur"), isOn: $disableLockScreenWallpaperBlur)
            Toggle(.localized("Hide Spotlight"), isOn: $hideSpotlight)
        } header: {
            Label(.localized("Other"), systemImage: "ellipsis.circle.fill")
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
                    Text(.localized("SpringBoard tweaks require Nugget to apply. A respring may be required after applying changes."))
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
        TweakSpringBoardView()
    }
}
#endif
