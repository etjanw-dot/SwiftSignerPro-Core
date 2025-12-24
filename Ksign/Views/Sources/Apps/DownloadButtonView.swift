//
//  DownloadButtonView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import CoreData

struct DownloadButtonView: View {
	let app: ASRepository.App
	let showModify: Bool
	
	@ObservedObject private var downloadManager = DownloadManager.shared
	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?
	@State private var showSigningView: Bool = false
	@State private var importedApp: Imported? = nil
	
	// Check if app exists in library (by bundle identifier)
	@FetchRequest private var importedApps: FetchedResults<Imported>
	
	init(app: ASRepository.App, showModify: Bool = false) {
		self.app = app
		self.showModify = showModify
		
		// Create fetch request to check if app with this bundle ID exists
		let request: NSFetchRequest<Imported> = Imported.fetchRequest()
		request.predicate = NSPredicate(format: "identifier == %@", app.id ?? "")
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		request.fetchLimit = 1
		_importedApps = FetchRequest(fetchRequest: request)
	}
	
	private var isInLibrary: Bool {
		!importedApps.isEmpty
	}

	var body: some View {
		HStack(spacing: 8) {
			if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				// Downloading state - circular progress
				_downloadingButton(currentDownload)
			} else if isInLibrary {
				// App is downloaded - show Sign button
				_openSignButton
				
				// Modify button (optional)
				if showModify {
					_modifyButton
				}
			} else {
				// App not downloaded - show Download button
				_downloadButton
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.easeInOut(duration: 0.3), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
		.animation(.easeInOut(duration: 0.3), value: isInLibrary)
		.fullScreenCover(isPresented: $showSigningView) {
			if let importedApp = importedApps.first {
				SigningView(app: importedApp, signAndInstall: false)
			}
		}
	}
	
	// MARK: - Download Button (when app is NOT in library)
	private var _downloadButton: some View {
		Button {
			if let url = app.currentDownloadUrl {
				_ = downloadManager.startDownload(from: url, id: app.currentUniqueId)
			}
		} label: {
			HStack(spacing: 4) {
				Image(systemName: "arrow.down.circle.fill")
					.font(.system(size: 12, weight: .bold))
				Text(.localized("Get"))
					.font(.subheadline)
					.fontWeight(.bold)
			}
			.foregroundColor(.white)
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(
				Capsule()
					.fill(Color.accentColor)
			)
		}
		.buttonStyle(.borderless)
	}
	
	// MARK: - Sign Button (when app IS in library - opens SigningView)
	private var _openSignButton: some View {
		Button {
			showSigningView = true
		} label: {
			HStack(spacing: 4) {
				Image(systemName: "signature")
					.font(.system(size: 12, weight: .bold))
				Text(.localized("Sign"))
					.font(.subheadline)
					.fontWeight(.bold)
			}
			.foregroundColor(.white)
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(
				Capsule()
					.fill(Color.orange)
			)
		}
		.buttonStyle(.borderless)
	}
	
	// MARK: - Modify Button
	private var _modifyButton: some View {
		Button {
			// TODO: Open modify options
		} label: {
			HStack(spacing: 4) {
				Image(systemName: "slider.horizontal.3")
					.font(.system(size: 12, weight: .medium))
				Text(.localized("Modify"))
					.font(.subheadline)
					.fontWeight(.medium)
			}
			.foregroundColor(.primary)
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(
				Capsule()
					.stroke(Color.gray.opacity(0.5), lineWidth: 1)
			)
		}
		.buttonStyle(.borderless)
	}
	
	// MARK: - Downloading Button
	@ViewBuilder
	private func _downloadingButton(_ currentDownload: Download) -> some View {
		HStack(spacing: 4) {
			ZStack {
				Circle()
					.stroke(Color.accentColor.opacity(0.2), lineWidth: 2.5)
					.frame(width: 28, height: 28)
				
				Circle()
					.trim(from: 0, to: downloadProgress)
					.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
					.rotationEffect(.degrees(-90))
					.frame(width: 28, height: 28)
					.animation(.smooth, value: downloadProgress)
				
				if downloadProgress >= 0.75 {
					Image(systemName: "archivebox.fill")
						.foregroundStyle(.tint)
						.font(.system(size: 10, weight: .bold))
				} else {
					Image(systemName: "square.fill")
						.foregroundStyle(.tint)
						.font(.system(size: 8))
				}
			}
			
			Text("\(Int(downloadProgress * 100))%")
				.font(.subheadline)
				.fontWeight(.bold)
				.foregroundColor(.accentColor)
				.monospacedDigit()
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 6)
		.background(
			Capsule()
				.fill(Color.accentColor.opacity(0.15))
		)
		.onTapGesture {
			if downloadProgress <= 0.75 {
				downloadManager.cancelDownload(currentDownload)
			}
		}
	}

	private func setupObserver() {
		cancellable?.cancel()
		guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress

		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)

		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
}

