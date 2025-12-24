//
//  AllAppsView.swift
//  Ksign
//
//  Shows all apps from all repositories in a unified list with bulk selection

import SwiftUI
import NimbleViews
import NukeUI
import AltSourceKit
import CoreData

// Helper struct to pair app with its source
struct AppWithSource: Identifiable {
	var id: String { app.uuid.uuidString }
	let source: ASRepository
	let app: ASRepository.App
}

struct AllAppsView: View {
	@StateObject private var viewModel = SourcesViewModel.shared
	@State private var searchText: String = ""
	@State private var isSelectionMode: Bool = false
	@State private var selectedApps: Set<String> = []
	@State private var showBulkSigningSheet: Bool = false
	@State private var currentSigningIndex: Int = 0
	@State private var showSigningOptions: Bool = false
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var sources: FetchedResults<AltSource>
	
	// Get all apps from all sources with their source reference
	private var allApps: [AppWithSource] {
		var apps: [AppWithSource] = []
		for source in sources {
			if let repository = viewModel.sources[source] {
				for app in viewModel.getApps(for: source) {
					apps.append(AppWithSource(source: repository, app: app))
				}
			}
		}
		return apps
	}
	
	// Filter apps by search text
	private var filteredApps: [AppWithSource] {
		if searchText.isEmpty {
			return allApps
		}
		return allApps.filter { appWithSource in
			appWithSource.app.currentName.localizedCaseInsensitiveContains(searchText)
		}
	}
	
	// Get selected apps for signing
	private var selectedAppsForSigning: [AppWithSource] {
		filteredApps.filter { selectedApps.contains($0.id) }
	}
	
	var body: some View {
		NavigationStack {
			List {
				ForEach(filteredApps) { appWithSource in
					HStack(spacing: 12) {
						// Selection checkbox (only in selection mode)
						if isSelectionMode {
							Button {
								toggleSelection(appWithSource.id)
							} label: {
								Image(systemName: selectedApps.contains(appWithSource.id) ? "checkmark.circle.fill" : "circle")
									.font(.title2)
									.foregroundColor(selectedApps.contains(appWithSource.id) ? .blue : .secondary)
							}
							.buttonStyle(.plain)
						}
						
						// App content
						if isSelectionMode {
							_appRow(appWithSource.app)
								.contentShape(Rectangle())
								.onTapGesture {
									toggleSelection(appWithSource.id)
								}
						} else {
							NavigationLink {
								SourceAppsDetailView(source: appWithSource.source, app: appWithSource.app)
							} label: {
								_appRow(appWithSource.app)
							}
						}
					}
				}
			}
			.listStyle(.plain)
			.navigationTitle(.localized("All Apps"))
			.navigationBarTitleDisplayMode(.inline)
			.searchable(text: $searchText, prompt: .localized("Search \(allApps.count) Apps"))
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					if isSelectionMode {
						Button {
							withAnimation {
								isSelectionMode = false
								selectedApps.removeAll()
							}
						} label: {
							Text(.localized("Cancel"))
						}
					}
				}
				
				ToolbarItemGroup(placement: .topBarTrailing) {
					if isSelectionMode {
						// Select All / Deselect All
						Button {
							if selectedApps.count == filteredApps.count {
								selectedApps.removeAll()
							} else {
								selectedApps = Set(filteredApps.map { $0.id })
							}
						} label: {
							Text(selectedApps.count == filteredApps.count ? .localized("Deselect All") : .localized("Select All"))
								.font(.subheadline)
						}
					} else {
						// Edit/Select mode button
						Button {
							withAnimation {
								isSelectionMode = true
							}
						} label: {
							Image(systemName: "checkmark.circle")
								.font(.title3)
						}
					}
				}
			}
			.safeAreaInset(edge: .bottom) {
				if isSelectionMode && !selectedApps.isEmpty {
					_signingBar
				}
			}
			.overlay {
				if !viewModel.isFinished {
					// Show skeleton loading that matches the app list layout
					SkeletonListView()
				} else if allApps.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Apps"), systemImage: "app.dashed")
						} description: {
							Text(.localized("Add a repository to see apps here."))
						}
					}
				} else if filteredApps.isEmpty && !searchText.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView.search(text: searchText)
					}
				}
			}
			.sheet(isPresented: $showSigningOptions) {
				_signingOptionsSheet
			}
		}
		.task(id: Array(sources)) {
			// Force refresh to get latest data every time
			await viewModel.fetchSources(sources, refresh: true)
		}
	}
	
	// MARK: - Signing Bar
	private var _signingBar: some View {
		VStack(spacing: 0) {
			Divider()
			
			HStack(spacing: 16) {
				// Selected count
				VStack(alignment: .leading, spacing: 2) {
					Text("\(selectedApps.count) " + .localized("Selected"))
						.font(.headline)
						.fontWeight(.semibold)
					Text(.localized("Ready to sign"))
						.font(.caption)
						.foregroundColor(.secondary)
				}
				
				Spacer()
				
				// Sign button
				Button {
					showSigningOptions = true
				} label: {
					HStack(spacing: 8) {
						Image(systemName: "signature")
						Text(.localized("Sign"))
					}
					.font(.headline)
					.foregroundColor(.white)
					.padding(.horizontal, 24)
					.padding(.vertical, 12)
					.background(
						LinearGradient(
							colors: [.blue, .purple],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.cornerRadius(12)
				}
			}
			.padding(.horizontal)
			.padding(.vertical, 12)
			.background(Color(.systemBackground))
		}
	}
	
	// MARK: - Signing Options Sheet
	private var _signingOptionsSheet: some View {
		NavigationStack {
			List {
				Section {
					// Sign All Selected
					Button {
						showSigningOptions = false
						// TODO: Open bulk signing with all selected apps
						showBulkSigningSheet = true
					} label: {
						HStack(spacing: 14) {
							ZStack {
								Circle()
									.fill(Color.accentColor.opacity(0.15))
									.frame(width: 44, height: 44)
								Image(systemName: "square.stack.3d.up.fill")
									.font(.title2)
									.foregroundColor(.accentColor)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Sign All Selected"))
									.font(.headline)
									.foregroundColor(.primary)
								Text("\(selectedApps.count) " + .localized("apps will be signed"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.foregroundColor(.secondary)
						}
					}
					
					// Sign One by One
					Button {
						showSigningOptions = false
						currentSigningIndex = 0
						// Navigate to first selected app
						navigateToNextApp()
					} label: {
						HStack(spacing: 14) {
							ZStack {
								Circle()
									.fill(Color.accentColor.opacity(0.15))
									.frame(width: 44, height: 44)
								Image(systemName: "arrow.right.circle.fill")
									.font(.title2)
									.foregroundColor(.purple)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Sign One by One"))
									.font(.headline)
									.foregroundColor(.primary)
								Text(.localized("Swipe to next app after signing"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.foregroundColor(.secondary)
						}
					}
				} header: {
					Text(.localized("Signing Options"))
				} footer: {
					Text(.localized("Choose how you want to sign the selected apps"))
				}
				
				Section {
					ForEach(selectedAppsForSigning) { appWithSource in
						HStack(spacing: 12) {
							if let iconURL = appWithSource.app.iconURL {
								LazyImage(url: iconURL) { state in
									if let image = state.image {
										image.appIconStyle(size: 40)
									} else {
										_smallPlaceholderIcon
									}
								}
							} else {
								_smallPlaceholderIcon
							}
							
							Text(appWithSource.app.currentName)
								.font(.subheadline)
								.lineLimit(1)
						}
					}
				} header: {
					Text(.localized("Selected Apps"))
				}
			}
			.navigationTitle(.localized("Sign Apps"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(.localized("Cancel")) {
						showSigningOptions = false
					}
				}
			}
		}
		.presentationDetents([.medium, .large])
	}
	
	// MARK: - Helper Functions
	private func toggleSelection(_ id: String) {
		withAnimation(.spring(response: 0.3)) {
			if selectedApps.contains(id) {
				selectedApps.remove(id)
			} else {
				selectedApps.insert(id)
			}
		}
	}
	
	private func navigateToNextApp() {
		// This would navigate to the signing view for the current app
		// with swipe gestures to go to next/previous
	}
	
	// MARK: - App Row
	@ViewBuilder
	private func _appRow(_ app: ASRepository.App) -> some View {
		HStack(spacing: 14) {
			// App Icon
			if let iconURL = app.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.appIconStyle(size: 56)
					} else {
						_placeholderIcon
					}
				}
			} else {
				_placeholderIcon
			}
			
			// App Info
			VStack(alignment: .leading, spacing: 4) {
				Text(app.currentName)
					.font(.headline)
					.fontWeight(.semibold)
					.lineLimit(1)
				
				if let version = app.currentVersion {
					Text("Version: \(version)")
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				
				if let date = app.currentDate?.date {
					Text(date, style: .date)
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			
			Spacer()
		}
		.padding(.vertical, 4)
	}
	
	private var _placeholderIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(.tertiarySystemFill))
				.frame(width: 56, height: 56)
			Image(systemName: "app.fill")
				.font(.title2)
				.foregroundColor(.secondary)
		}
	}
	
	private var _smallPlaceholderIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 8)
				.fill(Color(.tertiarySystemFill))
				.frame(width: 40, height: 40)
			Image(systemName: "app.fill")
				.font(.body)
				.foregroundColor(.secondary)
		}
	}
}

#Preview {
	AllAppsView()
}
