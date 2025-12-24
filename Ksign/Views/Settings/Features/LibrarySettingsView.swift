//
//  LibrarySettingsView.swift
//  Feather
//
//  Global library settings including auto-delete configuration
//

import SwiftUI
import NimbleViews
import CoreData

// MARK: - View
struct LibrarySettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Default expiration settings
    @AppStorage("Feather.defaultAutoDelete") private var _defaultAutoDelete: Bool = false
    @AppStorage("Feather.defaultAutoDeleteDays") private var _defaultAutoDeleteDays: Int = 7
    
    @State private var _showConfirmBulkSet = false
    @State private var _showConfirmClearAll = false
    @State private var _appsWithExpiration: Int = 0
    @State private var _totalApps: Int = 0
    
    var body: some View {
        Form {
            // Auto-Delete Overview Section
            Section {
                _overviewCard()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Default Settings Section
            Section {
                Toggle(isOn: $_defaultAutoDelete.animation(.spring())) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Auto-Delete by Default"))
                                .font(.body)
                            Text(.localized("Apply to new apps"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if _defaultAutoDelete {
                    Picker(selection: $_defaultAutoDeleteDays) {
                        Text(.localized("1 Day")).tag(1)
                        Text(.localized("3 Days")).tag(3)
                        Text(.localized("7 Days")).tag(7)
                        Text(.localized("14 Days")).tag(14)
                        Text(.localized("30 Days")).tag(30)
                    } label: {
                        Label {
                            Text(.localized("Default Duration"))
                        } icon: {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text(.localized("Default Settings"))
            } footer: {
                Text(.localized("When enabled, newly downloaded or signed apps will automatically have an expiration date set."))
            }
            
            // Bulk Actions Section
            Section {
                // Set expiration for all apps
                Button {
                    _showConfirmBulkSet = true
                } label: {
                    HStack {
                        Label {
                            Text(.localized("Set Expiration for All Apps"))
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        Text(verbatim: "\(_defaultAutoDeleteDays) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Clear all expiration dates
                Button(role: .destructive) {
                    _showConfirmClearAll = true
                } label: {
                    Label {
                        Text(.localized("Clear All Expiration Dates"))
                    } icon: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .disabled(_appsWithExpiration == 0)
            } header: {
                Text(.localized("Bulk Actions"))
            } footer: {
                Text(.localized("Apply or remove expiration dates from all apps in your library at once."))
            }
            
            // Statistics Section  
            Section {
                HStack {
                    Label {
                        Text(.localized("Total Apps"))
                    } icon: {
                        Image(systemName: "app.fill")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Text("\(_totalApps)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label {
                        Text(.localized("Apps with Expiration"))
                    } icon: {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("\(_appsWithExpiration)")
                        .foregroundColor(_appsWithExpiration > 0 ? .orange : .secondary)
                }
            } header: {
                Text(.localized("Statistics"))
            }
        }
        .navigationTitle(.localized("Library Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            _updateStats()
        }
        .alert(.localized("Set Expiration for All Apps"), isPresented: $_showConfirmBulkSet) {
            Button(.localized("Cancel"), role: .cancel) {}
            Button(.localized("Set Expiration")) {
                _setExpirationForAllApps()
            }
        } message: {
            Text(verbatim: "All apps will be set to expire in \(_defaultAutoDeleteDays) days. This action can be undone by clearing expiration dates.")
        }
        .alert(.localized("Clear All Expiration Dates"), isPresented: $_showConfirmClearAll) {
            Button(.localized("Cancel"), role: .cancel) {}
            Button(.localized("Clear All"), role: .destructive) {
                _clearAllExpirations()
            }
        } message: {
            Text(verbatim: "This will remove expiration dates from all \(_appsWithExpiration) apps. They will no longer be automatically deleted.")
        }
    }
}

// MARK: - View Components
extension LibrarySettingsView {
    @ViewBuilder
    private func _overviewCard() -> some View {
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
                    
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Auto-Delete"))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(.localized("Automatically remove apps after a set time"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick stats row
            if _appsWithExpiration > 0 {
                Divider()
                
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(_appsWithExpiration)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(.localized("Scheduled"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "app.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(_totalApps - _appsWithExpiration)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(.localized("Permanent"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func _statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Logic
extension LibrarySettingsView {
    private func _updateStats() {
        let signedRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
        let importedRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
        
        let signedCount = (try? Storage.shared.context.count(for: signedRequest)) ?? 0
        let importedCount = (try? Storage.shared.context.count(for: importedRequest)) ?? 0
        _totalApps = signedCount + importedCount
        
        // Count apps with expiration
        signedRequest.predicate = NSPredicate(format: "expirationDate != nil")
        importedRequest.predicate = NSPredicate(format: "expirationDate != nil")
        
        let signedWithExp = (try? Storage.shared.context.count(for: signedRequest)) ?? 0
        let importedWithExp = (try? Storage.shared.context.count(for: importedRequest)) ?? 0
        _appsWithExpiration = signedWithExp + importedWithExp
    }
    
    private func _setExpirationForAllApps() {
        let expirationDate = Date().addingTimeInterval(Double(_defaultAutoDeleteDays) * 86400)
        
        let signedRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
        let importedRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
        
        if let signedApps = try? Storage.shared.context.fetch(signedRequest) {
            for app in signedApps {
                app.expirationDate = expirationDate
            }
        }
        
        if let importedApps = try? Storage.shared.context.fetch(importedRequest) {
            for app in importedApps {
                app.expirationDate = expirationDate
            }
        }
        
        Storage.shared.saveContext()
        _updateStats()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func _clearAllExpirations() {
        let signedRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
        signedRequest.predicate = NSPredicate(format: "expirationDate != nil")
        
        let importedRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
        importedRequest.predicate = NSPredicate(format: "expirationDate != nil")
        
        if let signedApps = try? Storage.shared.context.fetch(signedRequest) {
            for app in signedApps {
                app.expirationDate = nil
            }
        }
        
        if let importedApps = try? Storage.shared.context.fetch(importedRequest) {
            for app in importedApps {
                app.expirationDate = nil
            }
        }
        
        Storage.shared.saveContext()
        _updateStats()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
