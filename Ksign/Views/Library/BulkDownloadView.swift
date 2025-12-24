//
//  BulkDownloadView.swift
//  SwiftSigner Pro
//
//  Bulk download multiple apps from repositories at once
//

import SwiftUI
import NimbleViews
import NukeUI
import AltSourceKit
import CoreData
import Combine

// Helper struct to pair app with its source repository name
struct BulkDownloadAppWithSource: Identifiable {
	var id: String { app.uuid.uuidString }
	let app: ASRepository.App
	let repoName: String
	let repoIconURL: URL?
}

struct BulkDownloadView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var viewModel = SourcesViewModel.shared
	@ObservedObject private var downloadManager = DownloadManager.shared
	
	@State private var selectedSource: AltSource?
	@State private var searchText = ""
	@State private var selectedApps: Set<String> = []
	@State private var isDownloading = false
	@State private var downloadedCount: Int = 0
	@State private var totalToDownload: Int = 0
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var sources: FetchedResults<AltSource>
	
	private var allApps: [BulkDownloadAppWithSource] {
		if let source = selectedSource,
		   let repo = viewModel.sources[source] {
			return repo.apps.map { BulkDownloadAppWithSource(app: $0, repoName: source.name ?? "Unknown", repoIconURL: source.iconURL) }
		}
		
		var apps: [BulkDownloadAppWithSource] = []
		for (source, repo) in viewModel.sources {
			for app in repo.apps {
				apps.append(BulkDownloadAppWithSource(app: app, repoName: source.name ?? "Unknown", repoIconURL: source.iconURL))
			}
		}
		return apps
	}
	
	private var filteredApps: [BulkDownloadAppWithSource] {
		if searchText.isEmpty {
			return allApps
		}
		return allApps.filter { appWithSource in
			(appWithSource.app.name ?? "").localizedCaseInsensitiveContains(searchText) ||
			(appWithSource.app.id ?? "").localizedCaseInsensitiveContains(searchText) ||
			appWithSource.repoName.localizedCaseInsensitiveContains(searchText)
		}
	}
	
	var body: some View {
		NBNavigationView(.localized("Bulk Download"), displayMode: .inline) {
			VStack(spacing: 0) {
				// Source Filter
				_sourceFilterPicker()
				
				// Apps List
				if !viewModel.isFinished {
					SkeletonBulkDownloadView()
				} else if filteredApps.isEmpty {
					_emptyState()
				} else {
					List {
						ForEach(filteredApps) { appWithSource in
							_appRow(appWithSource)
						}
					}
					.listStyle(.plain)
				}
			}
			.searchable(text: $searchText, prompt: Text(.localized("Search apps...")))
			.safeAreaInset(edge: .bottom) {
				if !selectedApps.isEmpty {
					_downloadBar()
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button(.localized("Cancel")) {
						dismiss()
					}
				}
				
				ToolbarItemGroup(placement: .navigationBarTrailing) {
					// Select All button
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
					
					// Download All button
					if !filteredApps.isEmpty {
						Button {
							selectedApps = Set(filteredApps.map { $0.id })
							_startBulkDownload()
						} label: {
							Label(.localized("Download All"), systemImage: "arrow.down.circle.fill")
						}
					}
				}
			}
		}
		.task {
			await viewModel.fetchSources(sources, refresh: true)
		}
	}
	
	// MARK: - Subviews
	
	@ViewBuilder
	private func _sourceFilterPicker() -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 8) {
				Button {
					withAnimation(.spring(response: 0.3)) {
						selectedSource = nil
					}
				} label: {
					HStack(spacing: 6) {
						Image(systemName: "globe")
							.font(.caption)
						Text(.localized("All"))
							.font(.subheadline)
							.fontWeight(.medium)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(
						Capsule()
							.fill(selectedSource == nil ? Color.accentColor : Color.secondary.opacity(0.15))
					)
					.foregroundColor(selectedSource == nil ? .white : .primary)
				}
				
				ForEach(sources, id: \.identifier) { source in
					Button {
						withAnimation(.spring(response: 0.3)) {
							selectedSource = source
						}
					} label: {
						HStack(spacing: 6) {
							if let iconURL = source.iconURL {
								LazyImage(url: iconURL) { state in
									if let image = state.image {
										image
											.resizable()
											.aspectRatio(contentMode: .fill)
									} else {
										Image(systemName: "app.dashed")
											.foregroundColor(.secondary)
									}
								}
								.frame(width: 16, height: 16)
								.clipShape(RoundedRectangle(cornerRadius: 4))
							}
							
							Text(source.name ?? .localized("Unknown"))
								.font(.subheadline)
								.fontWeight(.medium)
								.lineLimit(1)
						}
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.background(
							Capsule()
								.fill(selectedSource?.identifier == source.identifier ? Color.accentColor : Color.secondary.opacity(0.15))
						)
						.foregroundColor(selectedSource?.identifier == source.identifier ? .white : .primary)
					}
				}
			}
			.padding(.horizontal)
			.padding(.vertical, 8)
		}
		.background(Color(.systemGroupedBackground))
	}
	
	@ViewBuilder
	private func _appRow(_ appWithSource: BulkDownloadAppWithSource) -> some View {
		let app = appWithSource.app
		let isSelected = selectedApps.contains(appWithSource.id)
		
		HStack(spacing: 12) {
			// Selection checkbox
			Button {
				withAnimation(.spring(response: 0.3)) {
					if isSelected {
						selectedApps.remove(appWithSource.id)
					} else {
						selectedApps.insert(appWithSource.id)
					}
				}
			} label: {
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.font(.title2)
					.foregroundColor(isSelected ? .accentColor : .secondary)
			}
			.buttonStyle(.plain)
			
			// App Icon
			if let iconURL = app.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} else {
						RoundedRectangle(cornerRadius: 12)
							.fill(Color.secondary.opacity(0.2))
					}
				}
				.frame(width: 50, height: 50)
				.clipShape(RoundedRectangle(cornerRadius: 11))
			} else {
				RoundedRectangle(cornerRadius: 11)
					.fill(Color.secondary.opacity(0.2))
					.frame(width: 50, height: 50)
					.overlay(
						Image(systemName: "app.dashed")
							.font(.title3)
							.foregroundColor(.secondary)
					)
			}
			
			// App Info
			VStack(alignment: .leading, spacing: 2) {
				Text(app.currentName)
					.font(.headline)
					.lineLimit(1)
				
				// Repository source badge
				HStack(spacing: 4) {
					if let repoIconURL = appWithSource.repoIconURL {
						LazyImage(url: repoIconURL) { state in
							if let image = state.image {
								image
									.resizable()
									.aspectRatio(contentMode: .fill)
							} else {
								Image(systemName: "globe")
									.font(.system(size: 8))
							}
						}
						.frame(width: 12, height: 12)
						.clipShape(RoundedRectangle(cornerRadius: 3))
					} else {
						Image(systemName: "globe")
							.font(.system(size: 8))
							.foregroundColor(.secondary)
					}
					
					Text(appWithSource.repoName)
						.font(.caption2)
						.fontWeight(.medium)
						.foregroundColor(.accentColor)
						.lineLimit(1)
				}
				.padding(.horizontal, 6)
				.padding(.vertical, 2)
				.background(
					Capsule()
						.fill(Color.accentColor.opacity(0.1))
				)
				
				HStack(spacing: 4) {
					Text(app.currentVersion ?? "1.0")
						.font(.caption2)
						.foregroundColor(.secondary)
					
					if let size = app.size {
						Text("•")
							.font(.caption2)
							.foregroundColor(.secondary)
						Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
							.font(.caption2)
							.foregroundColor(.secondary)
					}
				}
			}
			
			Spacer()
		}
		.contentShape(Rectangle())
		.onTapGesture {
			withAnimation(.spring(response: 0.3)) {
				if isSelected {
					selectedApps.remove(appWithSource.id)
				} else {
					selectedApps.insert(appWithSource.id)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _downloadBar() -> some View {
		VStack(spacing: 0) {
			Divider()
			
			VStack(spacing: 10) {
				HStack(spacing: 16) {
					VStack(alignment: .leading, spacing: 2) {
						if isDownloading {
							Text(.localized("Downloading..."))
								.font(.headline)
								.fontWeight(.semibold)
							Text("\(downloadedCount)/\(totalToDownload) " + .localized("completed"))
								.font(.caption)
								.foregroundColor(.secondary)
						} else {
							Text("\(selectedApps.count) " + .localized("Selected"))
								.font(.headline)
								.fontWeight(.semibold)
							Text(.localized("Ready to download"))
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
					
					Spacer()
					
					if isDownloading {
						// Progress percentage
						Text("\(Int(Double(downloadedCount) / Double(max(totalToDownload, 1)) * 100))%")
							.font(.headline)
							.fontWeight(.bold)
							.foregroundColor(.accentColor)
					}
					
					Button {
						_startBulkDownload()
					} label: {
						HStack(spacing: 8) {
							if isDownloading {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.scaleEffect(0.8)
							} else {
								Image(systemName: "arrow.down.circle.fill")
							}
							Text(isDownloading ? .localized("Starting...") : .localized("Download"))
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
					.disabled(isDownloading)
				}
				
				// Progress bar when downloading
				if isDownloading && totalToDownload > 0 {
					GeometryReader { geometry in
						ZStack(alignment: .leading) {
							RoundedRectangle(cornerRadius: 4)
								.fill(Color(.tertiarySystemFill))
								.frame(height: 6)
							
							RoundedRectangle(cornerRadius: 4)
								.fill(
									LinearGradient(
										colors: [.blue, .purple],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.frame(width: max(geometry.size.width * (Double(downloadedCount) / Double(totalToDownload)), 0), height: 6)
								.animation(.spring(response: 0.3), value: downloadedCount)
						}
					}
					.frame(height: 6)
				}
			}
			.padding(.horizontal)
			.padding(.vertical, 12)
			.background(Color(.systemBackground))
		}
	}
	
	@ViewBuilder
	private func _emptyState() -> some View {
		VStack(spacing: 16) {
			Image(systemName: "app.badge.checkmark")
				.font(.system(size: 48))
				.foregroundColor(.secondary)
			
			Text(.localized("No Apps Available"))
				.font(.headline)
			
			Text(.localized("Add repositories in the Sources tab to see apps here."))
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	// MARK: - Actions
	
	private func _startBulkDownload() {
		isDownloading = true
		let generator = UIImpactFeedbackGenerator(style: .medium)
		generator.impactOccurred()
		
		let appsToDownload = filteredApps.filter { selectedApps.contains($0.id) }
		
		print("[BulkDownload] Starting download for \(appsToDownload.count) apps")
		
		// Use a DispatchQueue to stagger downloads slightly to avoid race conditions
		for (index, appWithSource) in appsToDownload.enumerated() {
			let app = appWithSource.app
			guard let downloadURL = app.currentDownloadUrl else { 
				print("[BulkDownload] Skipping \(app.name ?? "Unknown") - no download URL")
				continue 
			}
			
			// Generate a unique ID for each download
			let uniqueId = "BulkDownload_\(app.uuid.uuidString)_\(UUID().uuidString)"
			let downloadId = UUID()
			
			// Add to DownloadingAppsManager so it shows in Library with progress
			let downloadingApp = DownloadingApp(
				id: downloadId,
				name: app.currentName,
				bundleId: app.id ?? "unknown",
				iconURL: app.iconURL,
				status: .waiting,
				progress: 0
			)
			DownloadingAppsManager.shared.addDownload(downloadingApp)
			
			// Add a small delay between each download start to prevent conflicts
			DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
				print("[BulkDownload] Starting download \(index + 1)/\(appsToDownload.count): \(app.name ?? "Unknown") from \(appWithSource.repoName)")
				_ = self.downloadManager.startDownload(from: downloadURL, id: uniqueId)
				
				// Update status and track progress
				DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .downloading)
				
				// Monitor this download in background
				Task {
					var lastProgress: Double = 0
					while self.downloadManager.getDownload(by: uniqueId) != nil {
						if let dl = self.downloadManager.getDownload(by: uniqueId) {
							let progress = dl.overallProgress
							if abs(progress - lastProgress) > 0.01 {
								lastProgress = progress
								await MainActor.run {
									DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: progress)
									if progress >= 0.75 {
										DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .extracting)
									}
								}
							}
						}
						try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
					}
					
					// Download completed
					await MainActor.run {
						DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 1.0)
						DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .completed)
						
						// Update counter
						self.downloadedCount += 1
						
						// Remove after delay
						Task {
							try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
							await MainActor.run {
								DownloadingAppsManager.shared.removeDownload(id: downloadId)
							}
						}
					}
				}
			}
		}
		
		// Dismiss after a delay proportional to the number of apps
		let dismissDelay = 0.5 + Double(appsToDownload.count) * 0.2
		DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
			UINotificationFeedbackGenerator().notificationOccurred(.success)
			self.dismiss()
		}
	}
}
