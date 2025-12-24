//
//  LibraryAppIconView.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
	@AppStorage("Feather.libraryCellAppearance") private var _libraryCellAppearance: Int = 0

	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	// App expiration info for auto-delete badge
	var expirationInfo: AppExpirationInfo? {
		Storage.shared.getExpirationInfo(for: app)
	}
	
	// Category info for folder badge
	var categoryInfo: AppCategory? {
		Storage.shared.getCategory(for: app)
	}
	
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppDylibsPresenting: AnyApp?
	@Binding var selectedModifyAppPresenting: AnyApp?
	@Binding var isEditMode: Bool
	@Binding var selectedApps: Set<String>
	@State private var _showActionSheet = false
	@State private var _showExpirationSettings = false
	@State private var _showCategorySelection = false
	@State private var _showDowngradeSheet = false
	@State private var _appStoreInfo: AppStoreSearchResult?
	@State private var _availableVersions: [AppStoreVersionInfo] = []
	@State private var _isLoadingVersions = false
	
	// Get App Store link for this app if it was imported from App Store
	var appStoreLink: String? {
		if let bundleId = app.identifier {
			return UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)")
		}
		return nil
	}
	
	private var _isSelected: Bool {
		selectedApps.contains(app.uuid ?? "")
	}
	
	// MARK: Body
	var body: some View {
		HStack(spacing: 9) {
			if isEditMode {
				Button {
					_toggleSelection()
				} label: {
					Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
						.foregroundColor(_isSelected ? .accentColor : .secondary)
						.font(.title2)
				}
				.buttonStyle(.borderless)
			}
			
			// App icon with badges overlay
			ZStack(alignment: .topTrailing) {
				FRAppIconView(app: app, size: 57)
				
				VStack(spacing: 2) {
					// Expiration badge (trash icon)
					if let expInfo = expirationInfo, expInfo.shouldShowBadge {
						_expirationBadge(info: expInfo)
					}
				}
				
				// Category badge (folder icon) - bottom left
				if let category = categoryInfo {
					_categoryBadge(category: category)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
				}
			}
			
			NBTitleWithSubtitleView(
				title: app.name ?? .localized("Unknown"),
				subtitle: _desc,
				linelimit: 0
			)
			
			Spacer()
			
			if !isEditMode {
				if app.isSigned, let certInfo = certInfo {
					// Days remaining badge
					HStack(spacing: 4) {
						Image(systemName: "checkmark.seal.fill")
							.font(.system(size: 11))
	                    Text(certInfo.formatted)
							.font(.system(size: 12))
							.fontWeight(.semibold)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(certInfo.color)
					.clipShape(Capsule())
					
					// Install button for signed apps
					Button {
						selectedInstallAppPresenting = AnyApp(base: app)
					} label: {
						Text(.localized("Install"))
							.font(.system(size: 13, weight: .semibold))
							.foregroundColor(.white)
							.padding(.horizontal, 14)
							.padding(.vertical, 6)
							.background(
								LinearGradient(
									colors: [.blue, .purple],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.clipShape(Capsule())
					}
					.buttonStyle(.borderless)
				}
				
				Image(systemName: "chevron.right")
					.foregroundColor(.secondary)
					.font(.footnote)
			}
		}
		.scaleEffect(_isSelected ? 0.98 : 1.0)
		.contentShape(Rectangle())
		.onTapGesture {
			if isEditMode {
				_toggleSelection()
			} else {
				_showActionSheet = true
			}
		}
		.confirmationDialog(
			app.name ?? .localized("Unknown"),
			isPresented: $_showActionSheet,
			titleVisibility: .visible
		) {
			if !isEditMode {
				_actionSheetButtons(for: app)
			}
		}
		.swipeActions {
			if !isEditMode {
				_actions(for: app)
			}
		}
		.contextMenu {
			if !isEditMode {
				_contextActions(for: app)
				Divider()
				_contextActionsExtra(for: app)
				Divider()
				_categoryContextAction(for: app)
				_expirationContextAction(for: app)
				_downgradeContextAction(for: app)
				Divider()
				_copyPasteSection(for: app)
				Divider()
				_actions(for: app)
			}
		}
		.sheet(isPresented: $_showExpirationSettings) {
			AppExpirationSettingsView(app: app)
		}
		.sheet(isPresented: $_showCategorySelection) {
			CategorySelectionView(app: app)
		}
		.sheet(isPresented: $_showDowngradeSheet) {
			if let appInfo = _appStoreInfo {
				AppVersionPickerView(
					app: appInfo,
					versions: _availableVersions,
					isLoading: _isLoadingVersions,
					onSelect: { versionId in
						_startDowngrade(versionId: versionId)
					}
				)
			}
		}
	}
	
	private var _desc: String {
		if
			let version = app.version,
			let id = app.identifier
		{
			return "\(version) • \(id)"
		} else {
			return .localized("Unknown")
		}
	}
	
	private func _toggleSelection() {
		guard let uuid = app.uuid else { return }
		
		let impactFeedback = UIImpactFeedbackGenerator(style: .light)
		impactFeedback.impactOccurred()
		
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
			if _isSelected {
				selectedApps.remove(uuid)
			} else {
				selectedApps.insert(uuid)
			}
		}
	}
}

// MARK: - Extension: View
extension LibraryCellView {
	@ViewBuilder
	private func _actions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteApp(for: app)
		}
	}
	
	@ViewBuilder
	private func _copyPasteSection(for app: AppInfoPresentable) -> some View {
		Button(.localized("Copy"), systemImage: "doc.on.doc") {
			if let appDir = Storage.shared.getAppDirectory(for: app) {
				UIPasteboard.general.url = appDir
			}
		}
		Button(.localized("Paste"), systemImage: "doc.on.clipboard") {
			if let url = UIPasteboard.general.url {
				// Handle paste - could be used for icon or other files
				print("Pasted: \(url)")
			}
		}
	}
	
	@ViewBuilder
	private func _contextActions(for app: AppInfoPresentable) -> some View {
		// App Information Section
		Section {
			if let name = app.name {
				Label {
					Text(name)
						.font(.headline)
				} icon: {
					Image(systemName: "app.fill")
				}
			}
			
			if let version = app.version {
				Label {
					Text("v\(version)")
				} icon: {
					Image(systemName: "number")
				}
			}
			
			if let identifier = app.identifier {
				Button {
					UIPasteboard.general.string = identifier
				} label: {
					Label {
						Text(identifier)
							.font(.caption)
					} icon: {
						Image(systemName: "doc.on.doc")
					}
				}
			}
			
			if app.isSigned {
				Label {
					Text(.localized("Signed"))
						.foregroundColor(.green)
				} icon: {
					Image(systemName: "checkmark.seal.fill")
						.foregroundColor(.green)
				}
			} else {
				Label {
					Text(.localized("Unsigned"))
						.foregroundColor(.orange)
				} icon: {
					Image(systemName: "xmark.seal")
						.foregroundColor(.orange)
				}
			}
		}
		
		Button(.localized("Get Info"), systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	@ViewBuilder
	private func _expirationContextAction(for app: AppInfoPresentable) -> some View {
		Button {
			_showExpirationSettings = true
		} label: {
			if let expInfo = expirationInfo {
				Label {
				VStack(alignment: .leading) {
					Text(.localized("Auto-Delete Settings"))
					Text(verbatim: "Deletes in \(expInfo.formatted)")
						.font(.caption)
						.foregroundColor(expInfo.color)
				}
				} icon: {
					Image(systemName: "trash.circle.fill")
						.foregroundColor(.orange)
				}
			} else {
				Label(.localized("Auto-Delete Settings"), systemImage: "trash.circle")
			}
		}
	}
	
	@ViewBuilder
	private func _expirationBadge(info: AppExpirationInfo) -> some View {
		ZStack {
			Circle()
				.fill(
					LinearGradient(
						colors: [info.color.opacity(0.95), info.color.opacity(0.75)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 20, height: 20)
				.shadow(color: info.color.opacity(0.3), radius: 2, x: 0, y: 1)
			
			Image(systemName: "trash.fill")
				.font(.system(size: 10, weight: .bold))
				.foregroundColor(.white)
		}
		.offset(x: 4, y: -4)
	}
	
	@ViewBuilder
	private func _categoryBadge(category: AppCategory) -> some View {
		let categoryColor = Color(category.color ?? "blue")
		ZStack {
			RoundedRectangle(cornerRadius: 4)
				.fill(
					LinearGradient(
						colors: [categoryColor.opacity(0.95), categoryColor.opacity(0.75)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 18, height: 18)
				.shadow(color: categoryColor.opacity(0.3), radius: 2, x: 0, y: 1)
			
			Image(systemName: category.icon ?? "folder.fill")
				.font(.system(size: 9, weight: .bold))
				.foregroundColor(.white)
		}
		.offset(x: -4, y: 4)
	}
	
	@ViewBuilder
	private func _categoryContextAction(for app: AppInfoPresentable) -> some View {
		Button {
			_showCategorySelection = true
		} label: {
			if let category = categoryInfo {
				Label {
					VStack(alignment: .leading) {
						Text(.localized("Change Category"))
						Text(category.name ?? "Folder")
							.font(.caption)
							.foregroundColor(Color(category.color ?? "blue"))
					}
				} icon: {
					Image(systemName: category.icon ?? "folder.fill")
						.foregroundColor(Color(category.color ?? "blue"))
				}
			} else {
				Label(.localized("Add to Category"), systemImage: "folder.badge.plus")
			}
		}
	}
	
	@ViewBuilder
	private func _contextActionsExtra(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			if let id = app.identifier {
				Button(.localized("Open"), systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Re-sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Modify"), systemImage: "pencil.and.outline") {
				selectedModifyAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
			Button(.localized("Share IPA"), systemImage: "square.and.arrow.up.on.square") {
				if let appDir = Storage.shared.getAppDirectory(for: app) {
					UIActivityViewController.show(activityItems: [appDir])
				}
			}
		} else {
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Modify"), systemImage: "pencil.and.outline") {
				selectedModifyAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Share IPA"), systemImage: "square.and.arrow.up.on.square") {
				if let appDir = Storage.shared.getAppDirectory(for: app) {
					UIActivityViewController.show(activityItems: [appDir])
				}
			}
		}
		
		// Extract Source option
		Button(.localized("Extract Source"), systemImage: "doc.zipper") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	@ViewBuilder
	private func _actionSheetButtons(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			
			if let id = app.identifier {
				Button(.localized("Open"), systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			
			Button(.localized("Re-sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
		} else {
			Button(.localized("Sign & Install"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
			}
			
			Button(.localized("Sign"), systemImage: "pencil.and.outline") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
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
		
		Button(.localized("Get Info"), systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
		
		Button(.localized("Extract Source"), systemImage: "doc.zipper") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
		
		Button(categoryInfo != nil ? .localized("Change Category") : .localized("Add to Category"), systemImage: categoryInfo != nil ? "folder.badge.gearshape" : "folder.badge.plus") {
			_showCategorySelection = true
		}
		
		Button(.localized("Auto-Delete Settings"), systemImage: "trash.circle") {
			_showExpirationSettings = true
		}
		
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteApp(for: app)
		}
	}
	
	@ViewBuilder
	private func _buttonActions(for app: AppInfoPresentable) -> some View {
		Group {
			if app.isSigned {
				Button {
					selectedInstallAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Install"),
						showOverlay: _libraryCellAppearance == 0,
						expiration: certInfo
					)
				}
			} else {
				Button {
					selectedSigningAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Sign"),
						showOverlay: true,
						expiration: nil
					)
				}
			}
		}
		.buttonStyle(.borderless)
	}
	
	// MARK: - Downgrade Actions
	
	@ViewBuilder
	private func _downgradeContextAction(for app: AppInfoPresentable) -> some View {
		let storeClient = AppStoreClient.shared
		
		// Only show if app has an App Store link or bundle ID
		if appStoreLink != nil || app.identifier != nil {
			if storeClient.isAuthenticated {
				// User is logged in - show downgrade option
				Button {
					_loadDowngradeVersions()
				} label: {
					Label {
						VStack(alignment: .leading) {
							Text(.localized("Downgrade"))
							if appStoreLink != nil {
								Text(.localized("Download older version"))
									.font(.caption)
									.foregroundColor(.secondary)
							} else {
								Text(.localized("Link to App Store first"))
									.font(.caption)
									.foregroundColor(.orange)
							}
						}
					} icon: {
						Image(systemName: "clock.arrow.circlepath")
							.foregroundColor(.orange)
					}
				}
			} else {
				// User not logged in - show login required
				Button {
					UIAlertController.showAlertWithOk(
						title: .localized("Apple ID Required"),
						message: .localized("Please sign in with your Apple ID in Settings to download older versions from the App Store.")
					)
				} label: {
					Label {
						VStack(alignment: .leading) {
							Text(.localized("Downgrade"))
							Text(.localized("Sign in with Apple ID first"))
								.font(.caption)
								.foregroundColor(.orange)
						}
					} icon: {
						Image(systemName: "clock.arrow.circlepath")
							.foregroundColor(.gray)
					}
				}
			}
		}
	}
	
	private func _loadDowngradeVersions() {
		guard let bundleId = app.identifier else { return }
		
		_isLoadingVersions = true
		_showDowngradeSheet = true
		
		Task {
			let storeClient = AppStoreClient.shared
			var appId: String? = nil
			
			// First check if we have a saved App Store link with app ID
			if let savedLink = appStoreLink, let extractedId = savedLink.extractedAppId {
				appId = extractedId
				
				// Lookup app info using the extracted ID
				if let appInfo = await storeClient.lookupApp(appId: extractedId) {
					await MainActor.run {
						_appStoreInfo = appInfo
					}
				}
			}
			
			// If no saved link, lookup by bundle ID
			if appId == nil {
				if let appInfo = await storeClient.lookupApp(bundleId: bundleId) {
					await MainActor.run {
						_appStoreInfo = appInfo
						appId = String(appInfo.trackId)
						
						// Store the App Store link for future use
						UserDefaults.standard.set(appInfo.appStoreLink, forKey: "AppStoreLink_\(bundleId)")
					}
				}
			}
			
			// Get available versions if we have an app ID
			if let appId = appId ?? (_appStoreInfo.map { String($0.trackId) }) {
				let versions = await storeClient.getVersionList(appId: appId)
				
				await MainActor.run {
					_availableVersions = versions
					_isLoadingVersions = false
				}
			} else {
				await MainActor.run {
					_isLoadingVersions = false
					_showDowngradeSheet = false
					
					// Show error
					UIAlertController.showAlertWithOk(
						title: .localized("App Not Found"),
						message: .localized("This app could not be found in the App Store. Try adding an App Store link in the Modify view.")
					)
				}
			}
		}
	}
	
	private func _startDowngrade(versionId: String) {
		guard let appInfo = _appStoreInfo else { return }
		
		// Show warning about data reset
		let alert = UIAlertController(
			title: .localized("Data Reset Warning"),
			message: .localized("Downloading a different version will reset all app data. This action cannot be undone. Are you sure you want to continue?"),
			preferredStyle: .alert
		)
		
		alert.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
		alert.addAction(UIAlertAction(title: .localized("Continue"), style: .destructive) { _ in
			Task {
				let storeClient = AppStoreClient.shared
				if let ipaURL = await storeClient.downloadIPA(appId: String(appInfo.trackId), versionId: versionId) {
					let downloadManager = DownloadManager.shared
					let id = "Downgrade_\(UUID().uuidString)"
					let dl = downloadManager.startArchive(from: ipaURL, id: id)
					
					downloadManager.handlePachageFile(url: ipaURL, dl: dl) { error in
						DispatchQueue.main.async {
							if error == nil {
								UINotificationFeedbackGenerator().notificationOccurred(.success)
							}
						}
					}
				}
			}
		})
		
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let rootVC = windowScene.windows.first?.rootViewController {
			rootVC.present(alert, animated: true)
		}
	}
}
