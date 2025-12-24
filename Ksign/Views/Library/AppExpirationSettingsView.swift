//
//  AppExpirationSettingsView.swift
//  Feather
//
//  Settings view for configuring app expiration dates
//

import SwiftUI
import NimbleViews

// MARK: - View
struct AppExpirationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let app: AppInfoPresentable
    
    @State private var _hasExpiration: Bool = false
    @State private var _expirationDate: Date = Date().addingTimeInterval(604800) // Default 7 days from now
    @State private var _showConfirmation = false
    
    private let _presetOptions: [(String, TimeInterval)] = [
        ("1 Day", 86400),
        ("3 Days", 259200),
        ("7 Days", 604800),
        ("14 Days", 1209600),
        ("30 Days", 2592000),
        ("Custom", 0)
    ]
    
    @State private var _selectedPreset: Int = 2 // Default to 7 days
    
    var body: some View {
        NavigationView {
            Form {
                // App Info Header
                Section {
                    _appInfoHeader()
                }
                .listRowBackground(Color.clear)
                
                // Expiration Toggle
                Section {
                    Toggle(isOn: $_hasExpiration.animation(.spring())) {
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
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Auto-Delete"))
                                    .font(.body)
                                Text(.localized("Remove app on expiration date"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } footer: {
                    Text(.localized("When enabled, this app will be automatically removed from your library after the specified date."))
                }
                
                // Date Selection
                if _hasExpiration {
                    Section {
                        // Quick Presets
                        _presetsGrid()
                    } header: {
                        Text(.localized("Expiration Date"))
                    }
                    
                    // Custom Date Picker
                    if _selectedPreset == 5 { // Custom option
                        Section {
                            DatePicker(
                                .localized("Delete After"),
                                selection: $_expirationDate,
                                in: Date()...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .tint(.red)
                        }
                    }
                    
                    // Preview Section
                    Section {
                        _expirationPreview()
                    } header: {
                        Text(.localized("Preview"))
                    }
                }
            }
            .navigationTitle(.localized("Expiration Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Save")) {
                        _saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                _loadCurrentSettings()
            }
            .alert(.localized("Confirm Auto-Delete"), isPresented: $_showConfirmation) {
                Button(.localized("Cancel"), role: .cancel) {}
                Button(.localized("Enable"), role: .destructive) {
                    _confirmSave()
                }
            } message: {
                Text(.localized("This app will be automatically deleted on \(_expirationDate.formatted(date: .long, time: .omitted)). Are you sure?"))
            }
        }
    }
}

// MARK: - View Components
extension AppExpirationSettingsView {
    @ViewBuilder
    private func _appInfoHeader() -> some View {
        HStack(spacing: 14) {
            FRAppIconView(app: app, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? .localized("Unknown"))
                    .font(.headline)
                Text(app.identifier ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show current status badge
                if app.isSigned {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text(.localized("Signed"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption2)
                        Text(.localized("Downloaded"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func _presetsGrid() -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            ForEach(Array(_presetOptions.enumerated()), id: \.offset) { index, preset in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        _selectedPreset = index
                        if index != 5 { // Not custom
                            _expirationDate = Date().addingTimeInterval(preset.1)
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(preset.0)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(_selectedPreset == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(_selectedPreset == index
                                      ? LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                      : LinearGradient(
                                        colors: [Color(uiColor: .quaternarySystemFill), Color(uiColor: .quaternarySystemFill)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                )
                                .shadow(color: _selectedPreset == index ? .purple.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(_selectedPreset == index ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func _expirationPreview() -> some View {
        HStack(spacing: 14) {
            // Trash icon with animation - iOS 26 Style
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(.localized("Will be deleted on:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(_expirationDate.formatted(date: .long, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Days remaining
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: _expirationDate).day ?? 0
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    if daysRemaining == 0 {
                        Text(.localized("Today"))
                            .font(.caption)
                    } else if daysRemaining == 1 {
                        Text(.localized("In 1 day"))
                            .font(.caption)
                    } else {
                        Text(verbatim: "In \(daysRemaining) days")
                            .font(.caption)
                    }
                }
                .foregroundColor(daysRemaining <= 3 ? .red : .orange)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Logic
extension AppExpirationSettingsView {
    private func _loadCurrentSettings() {
        if let info = Storage.shared.getExpirationInfo(for: app) {
            _hasExpiration = true
            _expirationDate = info.expirationDate
            _selectedPreset = 5 // Custom since it's already set
        } else {
            _hasExpiration = false
        }
    }
    
    private func _saveSettings() {
        if _hasExpiration {
            _showConfirmation = true
        } else {
            // Clear expiration
            Storage.shared.setExpirationDate(nil, for: app)
            dismiss()
        }
    }
    
    private func _confirmSave() {
        Storage.shared.setExpirationDate(_expirationDate, for: app)
        dismiss()
    }
}
