//
//  DownloadQueueView.swift
//  SwiftSigner Pro
//
//  Shows all active downloads, queued items, and their progress
//

import SwiftUI
import NimbleViews

struct DownloadQueueView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var downloadManager = DownloadManager.shared
	@ObservedObject private var viewModel = SourcesViewModel.shared
	
	var body: some View {
		NBNavigationView(.localized("Download Queue"), displayMode: .inline) {
			List {
				// Active Downloads Section
				if !downloadManager.downloads.isEmpty {
					Section {
						ForEach(downloadManager.downloads, id: \.id) { download in
							_downloadRow(download)
						}
					} header: {
						HStack {
							Image(systemName: "arrow.down.circle.fill")
								.foregroundColor(.blue)
							Text(.localized("Active Downloads"))
						}
					} footer: {
						Text(.localized("\(downloadManager.downloads.count) download(s) in progress"))
					}
				}
				
				// Repos Loading Status Section
				Section {
					HStack(spacing: 12) {
						ZStack {
							RoundedRectangle(cornerRadius: 8)
								.fill(viewModel.isFinished ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
								.frame(width: 32, height: 32)
							if viewModel.isFinished {
								Image(systemName: "checkmark.circle.fill")
									.foregroundColor(.green)
							} else {
								ProgressView()
									.scaleEffect(0.8)
							}
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Repository Data"))
								.fontWeight(.medium)
							Text(viewModel.isFinished ? .localized("Loaded") : .localized("Loading..."))
								.font(.caption)
								.foregroundColor(.secondary)
						}
						
						Spacer()
						
						if viewModel.isFinished {
							Text(.localized("\(viewModel.sources.count) repos"))
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
					
					// Show each repo status
					ForEach(Array(viewModel.sources.keys), id: \.identifier) { source in
						HStack(spacing: 10) {
							Image(systemName: "square.stack.3d.up.fill")
								.font(.caption)
								.foregroundColor(.purple)
							
							VStack(alignment: .leading, spacing: 2) {
								Text(source.name ?? "Unknown Repo")
									.font(.subheadline)
								if let repo = viewModel.sources[source] {
									Text(.localized("\(repo.apps.count) apps"))
										.font(.caption)
										.foregroundColor(.secondary)
								}
							}
							
							Spacer()
							
							Image(systemName: "checkmark.circle.fill")
								.font(.caption)
								.foregroundColor(.green)
						}
					}
				} header: {
					HStack {
						Image(systemName: "square.stack.3d.up.fill")
							.foregroundColor(.purple)
						Text(.localized("Repositories"))
					}
				}
				
				// App Tabs Status
				Section {
					_statusRow(
						icon: "house.fill",
						color: .green,
						title: .localized("Home"),
						status: .localized("Ready"),
						isLoading: false
					)
					
					_statusRow(
						icon: "square.stack.3d.down.right.fill",
						color: .blue,
						title: .localized("Library"),
						status: .localized("Ready"),
						isLoading: false
					)
					
					_statusRow(
						icon: "arrow.down.app.fill",
						color: .orange,
						title: .localized("Sources"),
						status: viewModel.isFinished ? .localized("Ready") : .localized("Loading..."),
						isLoading: !viewModel.isFinished
					)
					
					_statusRow(
						icon: "gearshape.fill",
						color: .gray,
						title: .localized("Settings"),
						status: .localized("Ready"),
						isLoading: false
					)
				} header: {
					HStack {
						Image(systemName: "square.grid.2x2.fill")
							.foregroundColor(.accentColor)
						Text(.localized("App Tabs"))
					}
				}
				
				// Empty State
				if downloadManager.downloads.isEmpty {
					Section {
						VStack(spacing: 12) {
							Image(systemName: "tray.fill")
								.font(.system(size: 40))
								.foregroundColor(.secondary)
							Text(.localized("No Active Downloads"))
								.font(.headline)
							Text(.localized("Downloads will appear here when you start downloading apps"))
								.font(.caption)
								.foregroundColor(.secondary)
								.multilineTextAlignment(.center)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 24)
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .dismiss)
				
				if !downloadManager.downloads.isEmpty {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							_cancelAll()
						} label: {
							Text(.localized("Cancel All"))
								.foregroundColor(.red)
						}
					}
				}
			}
		}
	}
	
	// MARK: - Download Row
	@ViewBuilder
	private func _downloadRow(_ download: Download) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				// Icon
				ZStack {
					RoundedRectangle(cornerRadius: 8)
						.fill(Color.blue.opacity(0.15))
						.frame(width: 36, height: 36)
					Image(systemName: "arrow.down.circle.fill")
						.foregroundColor(.blue)
				}
				
				VStack(alignment: .leading, spacing: 2) {
					Text(download.fileName)
						.font(.subheadline)
						.fontWeight(.medium)
						.lineLimit(1)
					
					// Progress text
					if download.totalBytes > 0 {
						Text("\(ByteCountFormatter.string(fromByteCount: download.bytesDownloaded, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: download.totalBytes, countStyle: .file))")
							.font(.caption)
							.foregroundColor(.secondary)
					} else {
						Text(.localized("Starting..."))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}
				
				Spacer()
				
				// Cancel button
				Button {
					downloadManager.cancelDownload(download)
				} label: {
					Image(systemName: "xmark.circle.fill")
						.font(.title3)
						.foregroundColor(.secondary)
				}
				.buttonStyle(.plain)
			}
			
			// Progress bar
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
						.frame(width: max(geometry.size.width * download.overallProgress, 0), height: 6)
						.animation(.spring(response: 0.3), value: download.overallProgress)
				}
			}
			.frame(height: 6)
		}
		.padding(.vertical, 4)
	}
	
	// MARK: - Status Row
	@ViewBuilder
	private func _statusRow(icon: String, color: Color, title: String, status: String, isLoading: Bool) -> some View {
		HStack(spacing: 12) {
			ZStack {
				RoundedRectangle(cornerRadius: 8)
					.fill(color.opacity(0.15))
					.frame(width: 32, height: 32)
				Image(systemName: icon)
					.font(.system(size: 14))
					.foregroundColor(color)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.subheadline)
					.fontWeight(.medium)
				Text(status)
					.font(.caption)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			if isLoading {
				ProgressView()
					.scaleEffect(0.7)
			} else {
				Image(systemName: "checkmark.circle.fill")
					.font(.caption)
					.foregroundColor(.green)
			}
		}
	}
	
	// MARK: - Actions
	private func _cancelAll() {
		for download in downloadManager.downloads {
			downloadManager.cancelDownload(download)
		}
	}
}

#Preview {
	DownloadQueueView()
}
