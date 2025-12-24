//
//  SourcesView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _searchText = ""
	@State private var _isEditMode = false
	@State private var _showRepoMaker = false
	
	private var _filteredSources: [AltSource] {
		_sources.filter { _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) }
	}
	
	private var _erroredSources: [AltSource] {
		// Source has error if fetch completed but source not in viewModel's dictionary
		_filteredSources.filter { viewModel.sources[$0] == nil && !viewModel.isFinished }
	}
	
	private var _validSources: [AltSource] {
		// Source is valid if it's in the viewModel's sources dictionary
		_filteredSources.filter { viewModel.sources[$0] != nil }
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Repositories")) {
			ScrollView {
				VStack(spacing: 16) {
					// Search Bar
					HStack(spacing: 10) {
						Image(systemName: "magnifyingglass")
							.foregroundColor(.secondary)
						TextField(.localized("Search Repositories"), text: $_searchText)
							.textFieldStyle(.plain)
					}
					.padding(12)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(Color(.secondarySystemBackground))
					)
					.padding(.horizontal)
					
					// Valid Sources Section
					if !_validSources.isEmpty {
						VStack(alignment: .leading, spacing: 12) {
							ForEach(_validSources) { source in
								NavigationLink {
									SourceAppsView(object: [source], viewModel: viewModel)
								} label: {
									SourcesCellView(source: source, isEditMode: $_isEditMode)
								}
								.buttonStyle(.plain)
							}
						}
						.padding(.horizontal)
					}
					
					// Failed to Load Section
					if !_erroredSources.isEmpty {
						VStack(alignment: .leading, spacing: 8) {
							Text(.localized("Failed to Load"))
								.font(.subheadline)
								.fontWeight(.medium)
								.foregroundColor(.secondary)
								.padding(.horizontal)
							
							ForEach(_erroredSources) { source in
								NavigationLink {
									SourceAppsView(object: [source], viewModel: viewModel)
								} label: {
									SourcesCellView(source: source, isEditMode: $_isEditMode)
								}
								.buttonStyle(.plain)
							}
							.padding(.horizontal)
						}
					}
					
					// Stats Footer
					VStack(spacing: 4) {
						Text(.localized("Showing \(_filteredSources.count) Repository"))
							.font(.caption)
							.foregroundColor(.secondary)
						
						if !_erroredSources.isEmpty {
							Text(.localized("\(_erroredSources.count) Repository failed to load"))
								.font(.caption)
								.foregroundColor(.red)
						}
						
						if let lastUpdate = viewModel.lastUpdateTime {
							Text(.localized("Last updated: ") + lastUpdate)
								.font(.caption2)
								.foregroundColor(.secondary)
						}
					}
					.padding(.top, 8)
				}
				.padding(.vertical)
			}
		.overlay {
			if !viewModel.isFinished && _sources.count > 0 {
				// Show skeleton loading overlay while fetching sources
				ScrollView {
					VStack(spacing: 12) {
						ForEach(0..<min(_sources.count, 5), id: \.self) { _ in
							SkeletonSourceCardView()
						}
					}
					.padding()
				}
				.background(Color(.systemGroupedBackground))
			} else if !viewModel.isFinished {
				// Show skeleton loading when no sources exist yet
				ScrollView {
					VStack(spacing: 12) {
						ForEach(0..<3, id: \.self) { _ in
							SkeletonSourceCardView()
						}
					}
					.padding()
				}
				.background(Color(.systemGroupedBackground))
			} else if _filteredSources.isEmpty && _sources.isEmpty {
				if #available(iOS 17, *) {
					ContentUnavailableView {
						Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
					} description: {
						Text(.localized("Get started by adding your first repository."))
					} actions: {
						Button {
							_isAddingPresenting = true
						} label: {
							Text("Add Source").bg()
						}
					}
				}
			}
		}
		.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					if _isEditMode {
						Button {
							withAnimation {
								_isEditMode = false
							}
						} label: {
							Text(.localized("Done"))
								.fontWeight(.semibold)
						}
					}
				}
				
				ToolbarItemGroup(placement: .topBarTrailing) {
					// Repo Maker button with window icon
					Button {
						_showRepoMaker = true
					} label: {
						Image(systemName: "macwindow.badge.plus")
					}
					
					// Edit/Pen button
					if !_isEditMode {
						Button {
							withAnimation {
								_isEditMode = true
							}
						} label: {
							Image(systemName: "pencil")
						}
					}
					
					// Add button
					Button {
						_isAddingPresenting = true
					} label: {
						Image(systemName: "plus")
					}
				}
			}
			.sheet(isPresented: $_isAddingPresenting) {
				SourcesAddView()
					.presentationDetents([.medium])
			}
			.sheet(isPresented: $_showRepoMaker) {
				RepoMakerView()
			}
			.refreshable {
				await viewModel.fetchSources(_sources, refresh: true)
			}
		}
		.task(id: _sources.count) {
			await viewModel.fetchSources(_sources)
		}
		.onAppear {
			// Trigger initial fetch when view appears
			Task {
				await viewModel.fetchSources(_sources)
			}
		}
	}
}
