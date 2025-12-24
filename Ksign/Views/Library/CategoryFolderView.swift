//
//  CategoryFolderView.swift
//  Feather
//
//  iOS-style folder view showing apps in a category
//

import SwiftUI
import NimbleViews
import CoreData

// MARK: - View
struct CategoryFolderView: View {
    @Environment(\.dismiss) private var dismiss
    
    let category: AppCategory
    
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedAppDylibsPresenting: AnyApp?
    @Binding var selectedModifyAppPresenting: AnyApp?
    
    @State private var _apps: [AppInfoPresentable] = []
    @State private var _isEditMode = false
    @State private var _selectedApps: Set<String> = []
    @State private var _showEditCategory = false
    @State private var _selectedApp: AppInfoPresentable?
    @State private var _showAppActionSheet = false
    
    var categoryColor: Color {
        Color(category.color ?? "blue")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Folder Header
                _folderHeader()
                
                // Apps Grid/List
                if _apps.isEmpty {
                    _emptyState()
                } else {
                    _appsList()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(category.name ?? "Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
                
                // Edit button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        _showEditCategory = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(.localized("Edit Folder"), systemImage: "pencil") {
                            _showEditCategory = true
                        }
                        
                        if !_apps.isEmpty {
                            Button(_isEditMode ? .localized("Done Editing") : .localized("Select Apps"), systemImage: "checkmark.circle") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    _isEditMode.toggle()
                                    if !_isEditMode {
                                        _selectedApps.removeAll()
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(.localized("Delete Folder"), systemImage: "trash", role: .destructive) {
                            Storage.shared.deleteCategory(category)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                _loadApps()
            }
            .sheet(isPresented: $_showEditCategory) {
                CategoryEditView(category: category)
            }
            .confirmationDialog(
                _selectedApp?.name ?? .localized("App"),
                isPresented: $_showAppActionSheet,
                titleVisibility: .visible
            ) {
                _appActionSheetButtons()
            }
        }
    }
}

// MARK: - View Components
extension CategoryFolderView {
    @ViewBuilder
    private func _folderHeader() -> some View {
        VStack(spacing: 16) {
            // Category Icon - tappable to edit
            Button {
                _showEditCategory = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: category.icon ?? "folder.fill")
                        .font(.system(size: 36))
                        .foregroundColor(categoryColor)
                    
                    // Edit badge
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(categoryColor)
                        .background(Circle().fill(Color(.systemGroupedBackground)).padding(-2))
                        .offset(x: 30, y: 30)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 4) {
                Text(category.name ?? "Folder")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(verbatim: "\(_apps.count) apps")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Edit mode toolbar
            if _isEditMode && !_selectedApps.isEmpty {
                _editModeToolbar()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [categoryColor.opacity(0.05), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    @ViewBuilder
    private func _editModeToolbar() -> some View {
        HStack(spacing: 20) {
            Button {
                _removeSelectedFromFolder()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "folder.badge.minus")
                        .font(.title3)
                    Text(.localized("Remove"))
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
            
            Button {
                _deleteSelectedApps()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text(.localized("Delete"))
                        .font(.caption2)
                }
                .foregroundColor(.red)
            }
            
            Button {
                withAnimation {
                    _selectedApps.removeAll()
                    _isEditMode = false
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.title3)
                    Text(.localized("Cancel"))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func _emptyState() -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "app.dashed")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(.localized("No Apps in Folder"))
                .font(.headline)
            
            Text(.localized("Add apps to this category from the library"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func _appsList() -> some View {
        List {
            ForEach(_apps, id: \.uuid) { app in
                _appRow(app)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func _appRow(_ app: AppInfoPresentable) -> some View {
        HStack(spacing: 12) {
            // Selection checkbox in edit mode
            if _isEditMode {
                Button {
                    _toggleAppSelection(app)
                } label: {
                    Image(systemName: _selectedApps.contains(app.uuid ?? "") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(_selectedApps.contains(app.uuid ?? "") ? .accentColor : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            
            // App Icon
            ZStack(alignment: .topTrailing) {
                FRAppIconView(app: app, size: 50)
                
                // Signed badge
                if app.isSigned {
                    _signedBadge()
                }
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(app.identifier ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Type badge
                HStack(spacing: 6) {
                    if app.isSigned {
                        _typeBadge(text: .localized("Signed"), color: .green, icon: "checkmark.seal.fill")
                    } else {
                        _typeBadge(text: .localized("Downloaded"), color: .blue, icon: "arrow.down.circle.fill")
                    }
                    
                    if let version = app.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if !_isEditMode {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if _isEditMode {
                _toggleAppSelection(app)
            } else {
                _selectedApp = app
                _showAppActionSheet = true
            }
        }
        .contextMenu {
            _contextMenu(for: app)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Storage.shared.deleteApp(for: app)
                _loadApps()
            } label: {
                Label(.localized("Delete"), systemImage: "trash")
            }
            
            Button {
                Storage.shared.setCategory(nil, for: app)
                _loadApps()
            } label: {
                Label(.localized("Remove"), systemImage: "folder.badge.minus")
            }
            .tint(.orange)
        }
    }
    
    @ViewBuilder
    private func _typeBadge(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
    
    @ViewBuilder
    private func _signedBadge() -> some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 16, height: 16)
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 9))
                .foregroundColor(.white)
        }
        .offset(x: 3, y: -3)
    }
    
    @ViewBuilder
    private func _appActionSheetButtons() -> some View {
        if let app = _selectedApp {
            Button(.localized("Get Info"), systemImage: "info.circle") {
                selectedInfoAppPresenting = AnyApp(base: app)
            }
            
            if app.isSigned {
                Button(.localized("Install"), systemImage: "square.and.arrow.down") {
                    selectedInstallAppPresenting = AnyApp(base: app)
                }
                
                Button(.localized("Re-sign"), systemImage: "signature") {
                    selectedSigningAppPresenting = AnyApp(base: app)
                }
                
                if let id = app.identifier {
                    Button(.localized("Open App"), systemImage: "app.badge.checkmark") {
                        UIApplication.openApp(with: id)
                    }
                }
            } else {
                Button(.localized("Sign & Install"), systemImage: "signature") {
                    selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
                }
                
                Button(.localized("Sign"), systemImage: "pencil.and.outline") {
                    selectedSigningAppPresenting = AnyApp(base: app)
                }
            }
            
            Button(.localized("Show Dylibs"), systemImage: "puzzlepiece.extension") {
                selectedAppDylibsPresenting = AnyApp(base: app)
            }
            
            Button(.localized("Modify"), systemImage: "pencil.and.outline") {
                selectedModifyAppPresenting = AnyApp(base: app)
            }
            
            Button(.localized("Share IPA"), systemImage: "square.and.arrow.up.on.square") {
                if let appDir = Storage.shared.getAppDirectory(for: app) {
                    UIActivityViewController.show(activityItems: [appDir])
                }
            }
            
            Button(.localized("Extract Source"), systemImage: "doc.zipper") {
                selectedInfoAppPresenting = AnyApp(base: app)
            }
            
            Button(.localized("Remove from Folder"), systemImage: "folder.badge.minus") {
                Storage.shared.setCategory(nil, for: app)
                _loadApps()
            }
            
            Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                Storage.shared.deleteApp(for: app)
                _loadApps()
            }
        }
    }
    
    @ViewBuilder
    private func _contextMenu(for app: AppInfoPresentable) -> some View {
        Button(.localized("Get Info"), systemImage: "info.circle") {
            selectedInfoAppPresenting = AnyApp(base: app)
        }
        
        Divider()
        
        if app.isSigned {
            Button(.localized("Install"), systemImage: "square.and.arrow.down") {
                selectedInstallAppPresenting = AnyApp(base: app)
            }
            Button(.localized("Re-sign"), systemImage: "signature") {
                selectedSigningAppPresenting = AnyApp(base: app)
            }
            if let id = app.identifier {
                Button(.localized("Open App"), systemImage: "app.badge.checkmark") {
                    UIApplication.openApp(with: id)
                }
            }
        } else {
            Button(.localized("Sign & Install"), systemImage: "signature") {
                selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
            }
            Button(.localized("Sign"), systemImage: "signature") {
                selectedSigningAppPresenting = AnyApp(base: app)
            }
        }
        
        Divider()
        
        Button(.localized("Show Dylibs"), systemImage: "puzzlepiece.extension") {
            selectedAppDylibsPresenting = AnyApp(base: app)
        }
        
        Button(.localized("Modify"), systemImage: "pencil.and.outline") {
            selectedModifyAppPresenting = AnyApp(base: app)
        }
        
        Button(.localized("Share IPA"), systemImage: "square.and.arrow.up.on.square") {
            if let appDir = Storage.shared.getAppDirectory(for: app) {
                UIActivityViewController.show(activityItems: [appDir])
            }
        }
        
        Button(.localized("Extract Source"), systemImage: "doc.zipper") {
            selectedInfoAppPresenting = AnyApp(base: app)
        }
        
        Divider()
        
        // Copy & Paste
        Button(.localized("Copy"), systemImage: "doc.on.doc") {
            if let appDir = Storage.shared.getAppDirectory(for: app) {
                UIPasteboard.general.url = appDir
            }
        }
        Button(.localized("Paste"), systemImage: "doc.on.clipboard") {
            if let url = UIPasteboard.general.url {
                // Handle paste
                print("Pasted: \(url)")
            }
        }
        
        Divider()
        
        Button(.localized("Remove from Folder"), systemImage: "folder.badge.minus") {
            Storage.shared.setCategory(nil, for: app)
            _loadApps()
        }
        
        Divider()
        
        Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
            Storage.shared.deleteApp(for: app)
            _loadApps()
        }
    }
}

// MARK: - Logic
extension CategoryFolderView {
    private func _loadApps() {
        withAnimation {
            _apps = Storage.shared.getAppsInCategory(category)
        }
    }
    
    private func _toggleAppSelection(_ app: AppInfoPresentable) {
        guard let uuid = app.uuid else { return }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if _selectedApps.contains(uuid) {
                _selectedApps.remove(uuid)
            } else {
                _selectedApps.insert(uuid)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func _removeSelectedFromFolder() {
        for uuid in _selectedApps {
            if let app = _apps.first(where: { $0.uuid == uuid }) {
                Storage.shared.setCategory(nil, for: app)
            }
        }
        _selectedApps.removeAll()
        _isEditMode = false
        _loadApps()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func _deleteSelectedApps() {
        for uuid in _selectedApps {
            if let app = _apps.first(where: { $0.uuid == uuid }) {
                Storage.shared.deleteApp(for: app)
            }
        }
        _selectedApps.removeAll()
        _isEditMode = false
        _loadApps()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}
