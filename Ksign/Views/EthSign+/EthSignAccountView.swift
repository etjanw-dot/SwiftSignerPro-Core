//
//  EthSignAccountView.swift
//  Ksign
//
//  SwiftSigner Pro Account Management View
//

import SwiftUI

struct EthSignAccountView: View {
    @ObservedObject private var authService = EthSignAuthService.shared
    @ObservedObject private var syncService = EthSignCloudSyncService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSignOutConfirm = false
    @State private var showDeleteDataConfirm = false
    @State private var showConfigSheet = false
    
    var body: some View {
        Form {
            if authService.isAuthenticated {
                _accountSection()
                _syncSection()
                _actionsSection()
            } else {
                _signInPromptSection()
            }
            
            _configurationSection()
        }
        .navigationTitle("SwiftSigner Pro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out? Your local data will remain on this device.")
        }
        .alert("Delete Cloud Data", isPresented: $showDeleteDataConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await syncService.deleteAllSyncedData()
                }
            }
        } message: {
            Text("This will delete all your synced data from the cloud. Your local data will not be affected.")
        }
        .sheet(isPresented: $showConfigSheet) {
            NavigationView {
                _SupabaseConfigView(isPresented: $showConfigSheet)
            }
        }
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func _accountSection() -> some View {
        Section {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(authService.currentUser?.displayName?.prefix(1).uppercased() ?? authService.currentUser?.email.prefix(1).uppercased() ?? "?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.currentUser?.displayName ?? "SwiftSigner Pro User")
                        .font(.headline)
                    
                    Text(authService.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if authService.currentUser?.isPremium == true {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Premium")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Sync Section
    @ViewBuilder
    private func _syncSection() -> some View {
        Section {
            Toggle(isOn: Binding(
                get: { syncService.isSyncEnabled },
                set: { syncService.enableSync($0) }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cloud Sync")
                            .font(.subheadline)
                        Text("Sync certificates and repos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if syncService.isSyncEnabled {
                Button {
                    Task {
                        await syncService.performFullSync()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Now")
                            if let lastSync = syncService.lastSyncDate {
                                Text("Last synced: \(_formatDate(lastSync))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if syncService.syncStatus == .syncing {
                            ProgressView()
                        } else if syncService.syncStatus == .success {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if syncService.syncStatus == .error {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .disabled(syncService.syncStatus == .syncing)
                
                if let error = syncService.syncError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Cloud Sync")
        } footer: {
            Text("Sync your certificates, repositories, and app library across all your devices.")
        }
    }
    
    // MARK: - Actions Section
    @ViewBuilder
    private func _actionsSection() -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteDataConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Cloud Data")
                }
            }
            
            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
            }
        }
    }
    
    // MARK: - Sign In Prompt Section
    @ViewBuilder
    private func _signInPromptSection() -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Sign In to SwiftSigner Pro")
                    .font(.headline)
                
                Text("Create an account to sync your certificates and repositories across all your devices.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                NavigationLink {
                    LoginView()
                } label: {
                    Text("Sign In or Create Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Configuration Section
    @ViewBuilder
    private func _configurationSection() -> some View {
        Section {
            Button {
                showConfigSheet = true
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                    Text("Supabase Configuration")
                        .foregroundColor(.primary)
                    Spacer()
                    if authService.isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Text("Not Configured")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        } footer: {
            Text("Configure your Supabase project credentials to enable cloud sync.")
        }
    }
    
    // MARK: - Helpers
    private func _formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        EthSignAccountView()
    }
}
