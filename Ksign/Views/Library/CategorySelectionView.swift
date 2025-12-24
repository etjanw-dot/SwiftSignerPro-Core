//
//  CategorySelectionView.swift
//  Feather
//
//  View for selecting/assigning a category to an app
//

import SwiftUI
import NimbleViews
import CoreData

// MARK: - View
struct CategorySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let app: AppInfoPresentable
    var onSelect: ((AppCategory?) -> Void)?
    
    @FetchRequest(
        entity: AppCategory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)],
        animation: .snappy
    ) private var categories: FetchedResults<AppCategory>
    
    @State private var _selectedCategory: AppCategory?
    @State private var _showCreateCategory = false
    
    var body: some View {
        NavigationView {
            Form {
                // App Info Header
                Section {
                    _appInfoHeader()
                }
                .listRowBackground(Color.clear)
                
                // No Category Option
                Section {
                    Button {
                        _selectedCategory = nil
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "folder.badge.minus")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("No Category"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(.localized("Remove from all categories"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if _selectedCategory == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                            }
                        }
                    }
                }
                
                // Categories List
                Section {
                    if categories.isEmpty {
                        _emptyState()
                    } else {
                        ForEach(categories, id: \.uuid) { category in
                            _categoryRow(category)
                        }
                    }
                } header: {
                    HStack {
                        Text(.localized("Categories"))
                        Spacer()
                        Button {
                            _showCreateCategory = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(.localized("Select Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        _saveSelection()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                _selectedCategory = Storage.shared.getCategory(for: app)
            }
            .sheet(isPresented: $_showCreateCategory) {
                CategoryEditView(category: nil)
            }
        }
    }
}

// MARK: - View Components
extension CategorySelectionView {
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
                
                // Current category badge
                if let category = _selectedCategory {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon ?? "folder.fill")
                            .font(.caption2)
                        Text(category.name ?? "Folder")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(category.color ?? "blue"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(category.color ?? "blue").opacity(0.15))
                    )
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func _emptyState() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text(.localized("No Categories Yet"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                _showCreateCategory = true
            } label: {
                Text(.localized("Create Category"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func _categoryRow(_ category: AppCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _selectedCategory = category
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                
                if _selectedCategory?.uuid == category.uuid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
        }
    }
    
    private func _saveSelection() {
        Storage.shared.setCategory(_selectedCategory, for: app)
        onSelect?(_selectedCategory)
        dismiss()
    }
}
