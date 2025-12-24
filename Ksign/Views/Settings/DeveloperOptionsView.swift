//
//  DeveloperOptionsView.swift
//  Ksign
//
//  Developer options and debug settings.
//

import SwiftUI
import NimbleViews

// MARK: - Developer Options View
struct DeveloperOptionsView: View {
    @AppStorage("Ksign.developer.debugMode") private var debugMode: Bool = false
    @AppStorage("Ksign.developer.verboseLogs") private var verboseLogs: Bool = false
    @AppStorage("Ksign.developer.showBuildInfo") private var showBuildInfo: Bool = true
    @AppStorage("Ksign.developer.skipValidation") private var skipValidation: Bool = false
    
    @State private var showClearCacheAlert = false
    @State private var showResetAllAlert = false
    
    var body: some View {
        NBList(.localized("Developer Options")) {
            // Debug Section
            NBSection(.localized("Debug")) {
                Toggle(isOn: $debugMode) {
                    Label {
                        Text(.localized("Debug Mode"))
                    } icon: {
                        Image(systemName: "ant.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Toggle(isOn: $verboseLogs) {
                    Label {
                        Text(.localized("Verbose Logging"))
                    } icon: {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Toggle(isOn: $showBuildInfo) {
                    Label {
                        Text(.localized("Show Build Info"))
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentColor)
                    }
                }
            } footer: {
                Text(.localized("Enable additional debugging features and logging."))
            }
            
            // Advanced Section
            NBSection(.localized("Advanced")) {
                Toggle(isOn: $skipValidation) {
                    Label {
                        Text(.localized("Skip Certificate Validation"))
                    } icon: {
                        Image(systemName: "shield.slash")
                            .foregroundColor(.orange)
                    }
                }
            } footer: {
                Text(.localized("Warning: These options can cause unexpected behavior. Use with caution."))
            }
            
            // Build Info Section
            if showBuildInfo {
                NBSection(.localized("Build Information")) {
                    HStack {
                        Label {
                            Text(.localized("Version"))
                        } icon: {
                            Image(systemName: "1.circle")
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                        Text(Bundle.main.version ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label {
                            Text(.localized("Build"))
                        } icon: {
                            Image(systemName: "hammer")
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                        Text(Bundle.main.buildNumber ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label {
                            Text(.localized("Bundle ID"))
                        } icon: {
                            Image(systemName: "shippingbox")
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                        Text(Bundle.main.bundleIdentifier ?? "Unknown")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // Actions Section
            NBSection(.localized("Actions")) {
                Button {
                    showClearCacheAlert = true
                } label: {
                    Label {
                        Text(.localized("Clear Cache"))
                    } icon: {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.orange)
                    }
                }
                
                Button(role: .destructive) {
                    showResetAllAlert = true
                } label: {
                    Label {
                        Text(.localized("Reset All Developer Settings"))
                    } icon: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert(.localized("Clear Cache"), isPresented: $showClearCacheAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Clear"), role: .destructive) {
                clearCache()
            }
        } message: {
            Text(.localized("This will clear temporary files and cached data."))
        }
        .alert(.localized("Reset Developer Settings"), isPresented: $showResetAllAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text(.localized("This will reset all developer options to their default values."))
        }
    }
    
    private func clearCache() {
        // Clear temp directory
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            .forEach { try? FileManager.default.removeItem(at: $0) }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func resetAllSettings() {
        debugMode = false
        verboseLogs = false
        showBuildInfo = true
        skipValidation = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

// MARK: - Preview
#Preview {
    DeveloperOptionsView()
}
