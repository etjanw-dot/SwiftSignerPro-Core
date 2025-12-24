//
//  CategorySettingsView.swift
//  Feather
//
//  Settings view for managing app categories/folders
//

import SwiftUI
import NimbleViews
import CoreData

// MARK: - View
struct CategorySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: AppCategory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)],
        animation: .snappy
    ) private var categories: FetchedResults<AppCategory>
    
    @State private var _showAddCategory = false
    @State private var _editingCategory: AppCategory?
    
    var body: some View {
        Form {
            // Header
            Section {
                _headerCard()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Categories List
            Section {
                if categories.isEmpty {
                    _emptyState()
                } else {
                    ForEach(categories, id: \.uuid) { category in
                        _categoryRow(category)
                    }
                    .onDelete(perform: _deleteCategories)
                }
            } header: {
                HStack {
                    Text(.localized("Categories"))
                    Spacer()
                    Text("\(categories.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(.localized("Categories"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    _showAddCategory = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $_showAddCategory) {
            CategoryEditView(category: nil)
        }
        .sheet(item: $_editingCategory) { category in
            CategoryEditView(category: category)
        }
    }
}

// MARK: - View Components
extension CategorySettingsView {
    @ViewBuilder
    private func _headerCard() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "folder.fill.badge.gearshape")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(.localized("App Categories"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(.localized("Organize your apps into folders for easy access. Categories work for both downloaded and signed apps."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func _emptyState() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(.localized("No Categories"))
                .font(.headline)
            
            Text(.localized("Create your first category to organize apps"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                _showAddCategory = true
            } label: {
                Text(.localized("Create Category"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    @ViewBuilder
    private func _categoryRow(_ category: AppCategory) -> some View {
        Button {
            _editingCategory = category
        } label: {
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(category.color ?? "blue").opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon ?? "folder.fill")
                        .font(.title3)
                        .foregroundColor(Color(category.color ?? "blue"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Folder")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    let count = Storage.shared.getCategoryAppCount(category)
                    Text(verbatim: "\(count) apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contextMenu {
            Button(.localized("Edit"), systemImage: "pencil") {
                _editingCategory = category
            }
            
            Divider()
            
            Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                Storage.shared.deleteCategory(category)
            }
        }
    }
    
    private func _deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            Storage.shared.deleteCategory(categories[index])
        }
    }
}

// MARK: - Category Edit View
struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let category: AppCategory?
    
    @State private var _name: String = ""
    @State private var _selectedIcon: String = "folder.fill"
    @State private var _selectedColor: String = "blue"
    
    var isEditing: Bool { category != nil }
    
    var body: some View {
        NavigationView {
            Form {
                // Name Section
                Section {
                    TextField(.localized("Category Name"), text: $_name)
                } header: {
                    Text(.localized("Name"))
                }
                
                // Icon Section
                Section {
                    _iconPicker()
                } header: {
                    Text(.localized("Icon"))
                }
                
                // Color Section
                Section {
                    _colorPicker()
                } header: {
                    Text(.localized("Color"))
                }
                
                // Preview
                Section {
                    _preview()
                } header: {
                    Text(.localized("Preview"))
                }
                
                // Delete (only for editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let category = category {
                                Storage.shared.deleteCategory(category)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text(.localized("Delete Category"))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? .localized("Edit Category") : .localized("New Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Save")) {
                        _save()
                    }
                    .disabled(_name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let category = category {
                    _name = category.name ?? ""
                    _selectedIcon = category.icon ?? "folder.fill"
                    _selectedColor = category.color ?? "blue"
                }
            }
        }
    }
    
    @ViewBuilder
    private func _iconPicker() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(CategoryIcons.all, id: \.icon) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        _selectedIcon = item.icon
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(_selectedIcon == item.icon
                                  ? Color(_selectedColor).opacity(0.2)
                                  : Color(uiColor: .quaternarySystemFill))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundColor(_selectedIcon == item.icon
                                             ? Color(_selectedColor)
                                             : .secondary)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(_selectedIcon == item.icon ? Color(_selectedColor) : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func _colorPicker() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
            ForEach(Color.categoryColors, id: \.name) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        _selectedColor = item.name
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Circle()
                        .fill(item.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: _selectedColor == item.name ? 3 : 0)
                        )
                        .overlay(
                            Circle()
                                .stroke(item.color, lineWidth: _selectedColor == item.name ? 2 : 0)
                                .padding(4)
                        )
                        .scaleEffect(_selectedColor == item.name ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func _preview() -> some View {
        HStack(spacing: 14) {
            // iOS-style folder preview
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(_selectedColor).opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: _selectedIcon)
                    .font(.system(size: 28))
                    .foregroundColor(Color(_selectedColor))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(_name.isEmpty ? .localized("Category Name") : _name)
                    .font(.headline)
                    .foregroundColor(_name.isEmpty ? .secondary : .primary)
                
                Text(.localized("0 apps"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func _save() {
        let trimmedName = _name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let category = category {
            // Update existing
            Storage.shared.updateCategory(
                category,
                name: trimmedName,
                icon: _selectedIcon,
                color: _selectedColor
            )
        } else {
            // Create new
            Storage.shared.addCategory(
                name: trimmedName,
                icon: _selectedIcon,
                color: _selectedColor
            ) { _, _ in }
        }
        
        dismiss()
    }
}
