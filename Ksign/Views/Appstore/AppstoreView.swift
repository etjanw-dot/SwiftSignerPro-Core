//
//  AppstoreView.swift
//  Ksign
//
//  Created by Nagata Asami on 3/8/25.
//

import SwiftUI
import CoreData
import AltSourceKit
import NimbleViews
import NukeUI

struct AppstoreView: View {
	@StateObject private var _viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _searchText = ""
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	private var _filteredSources: [AltSource] {
		_sources.filter { _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) }
	}
	
	private var _erroredSources: [AltSource] {
		// Source has error if fetch completed but source not in viewModel's dictionary
		_filteredSources.filter { _viewModel.sources[$0] == nil && !_viewModel.isFinished }
	}
	
	private var _validSources: [AltSource] {
		// Source is valid if it's in the viewModel's sources dictionary
		_filteredSources.filter { _viewModel.sources[$0] != nil }
	}
	
	private var _totalAppCount: Int {
		_sources.reduce(0) { $0 + _viewModel.getApps(for: $1).count }
	}
	
	var body: some View {
		NavigationStack {
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
					
					// All Apps Card - shows all repos content combined
					NavigationLink {
						SourceAppsView(fromAppStore: true, object: Array(_sources), viewModel: _viewModel)
					} label: {
						HStack(spacing: 14) {
							Circle()
								.stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
								.frame(width: 24, height: 24)
							
							ZStack {
								RoundedRectangle(cornerRadius: 12)
									.fill(Color(.tertiarySystemFill))
									.frame(width: 50, height: 50)
								Image(systemName: "square.grid.2x2.fill")
									.font(.title2)
									.foregroundColor(.secondary)
							}
							
							VStack(alignment: .leading, spacing: 4) {
								Text(.localized("All Apps"))
									.font(.headline)
									.fontWeight(.semibold)
									.foregroundColor(.primary)
								Text("\(_totalAppCount) " + .localized("Apps"))
									.font(.subheadline)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.foregroundColor(.secondary)
								.font(.caption)
						}
						.padding(.vertical, 8)
						.padding(.horizontal, 12)
						.background(
							RoundedRectangle(cornerRadius: 14)
								.fill(Color(.secondarySystemBackground))
						)
					}
					.buttonStyle(.plain)
					.padding(.horizontal)
					
					// Individual Repos
					if !_validSources.isEmpty {
						VStack(alignment: .leading, spacing: 12) {
							ForEach(_validSources) { source in
								NavigationLink {
									SourceAppsView(object: [source], viewModel: _viewModel)
								} label: {
									_repoCard(for: source)
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
								_errorRepoCard(for: source)
									.padding(.horizontal)
							}
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
					}
					.padding(.top, 8)
				}
				.padding(.vertical)
			}
			.navigationTitle(.localized("Repositories"))
			.navigationBarTitleDisplayMode(.large)
			.overlay {
			if !_viewModel.isFinished && _validSources.isEmpty {
				// Show skeleton loading that matches the repository cards layout
				ScrollView {
					VStack(spacing: 12) {
						ForEach(0..<3, id: \.self) { _ in
							SkeletonSourceCardView()
						}
					}
					.padding()
				}
				.background(Color(.systemGroupedBackground))
			} else if _sources.isEmpty {
				if #available(iOS 17, *) {
					ContentUnavailableView {
						Label(.localized("No Repositories"), systemImage: "folder.fill")
					} description: {
						Text(.localized("Get started by adding your first repository."))
					} actions: {
						Button {
							_isAddingPresenting = true
						} label: {
							Text(.localized("Add Repository")).bg()
						}
					}
				}
			}
		}
		.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
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
			.refreshable {
				await _viewModel.fetchSources(_sources, refresh: true)
			}
		}
		.task(id: Array(_sources)) {
			await _viewModel.fetchSources(_sources)
		}
	}
	
	// MARK: - Repo Card
	@ViewBuilder
	private func _repoCard(for source: AltSource) -> some View {
		let appCount = _viewModel.getApps(for: source).count
		
		HStack(spacing: 14) {
			Circle()
				.stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
				.frame(width: 24, height: 24)
			
			// Repo Icon
			if let iconURL = source.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.appIconStyle(size: 50)
					} else {
						_placeholderIcon
					}
				}
			} else {
				_placeholderIcon
			}
			
			VStack(alignment: .leading, spacing: 4) {
				Text(source.name ?? .localized("Unknown"))
					.font(.headline)
					.fontWeight(.semibold)
					.foregroundColor(.primary)
				
				Text("\(appCount) " + .localized("Apps"))
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Image(systemName: "chevron.right")
				.foregroundColor(.secondary)
				.font(.caption)
		}
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(Color(.secondarySystemBackground))
		)
	}
	
	// MARK: - Error Repo Card
	@ViewBuilder
	private func _errorRepoCard(for source: AltSource) -> some View {
		HStack(spacing: 14) {
			Circle()
				.stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
				.frame(width: 24, height: 24)
			
			ZStack {
				RoundedRectangle(cornerRadius: 12)
					.fill(Color.red.opacity(0.15))
					.frame(width: 50, height: 50)
				Image(systemName: "exclamationmark.triangle.fill")
					.font(.title2)
					.foregroundColor(.red)
			}
			
			VStack(alignment: .leading, spacing: 4) {
				Text(source.name ?? source.sourceURL?.host ?? .localized("Unknown"))
					.font(.headline)
					.fontWeight(.semibold)
					.foregroundColor(.red)
				
				Text(.localized("Failed to load repository"))
					.font(.subheadline)
					.foregroundColor(.red.opacity(0.8))
			}
			
			Spacer()
		}
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(Color.red.opacity(0.08))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 14)
				.stroke(Color.red.opacity(0.3), lineWidth: 1)
		)
		.swipeActions {
			Button(role: .destructive) {
				Storage.shared.deleteSource(for: source)
			} label: {
				Label(.localized("Delete"), systemImage: "trash")
			}
		}
		.contextMenu {
			Button(role: .destructive) {
				Storage.shared.deleteSource(for: source)
			} label: {
				Label(.localized("Delete"), systemImage: "trash")
			}
		}
	}
	
	private var _placeholderIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(.tertiarySystemFill))
				.frame(width: 50, height: 50)
			Image(systemName: "questionmark.app.fill")
				.font(.title2)
				.foregroundColor(.secondary)
		}
	}
}
