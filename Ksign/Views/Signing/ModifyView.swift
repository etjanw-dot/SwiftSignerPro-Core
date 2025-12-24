//
//  ModifyView.swift
//  SwiftSigner Pro
//
//  Modify IPA properties without signing - change name, icon, bundle ID, version, and inject tweaks
//

import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct ModifyView: View {
	@Environment(\.dismiss) var dismiss
	@Namespace var _namespace

	@StateObject private var _optionsManager = OptionsManager.shared
	
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isLogsPresenting = false
	@State private var _isModifying = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	
	// Animation states
	@State private var _iconPulse = false
	@State private var _buttonScale: CGFloat = 1.0
	@State private var _progressRotation: Double = 0
	
	// App Store Link
	@State private var _appStoreLink: String = ""
	
	var app: AppInfoPresentable
	
	init(app: AppInfoPresentable) {
		self.app = app
	}
		
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Modify") + " " + (app.name ?? .localized("Unknown")), displayMode: .inline) {
			Form {
				_customizationOptions(for: app)
				_modifySettings()
				_customizationProperties(for: app)
			}
			.disabled(_isModifying)
			.safeAreaInset(edge: .bottom) {
				if _isModifying {
					Button() {
						_isLogsPresenting = true
					} label: {
						HStack(spacing: 8) {
							// Spinning gear icon
							Image(systemName: "gear")
								.font(.headline)
								.rotationEffect(.degrees(_progressRotation))
							Text(.localized("Modifying..."))
								.font(.headline)
						}
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(
							ZStack {
								// Animated gradient background
								LinearGradient(
									colors: [.gray.opacity(0.8), .secondary.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
								
								// Pulsing overlay
								RoundedRectangle(cornerRadius: 14)
									.fill(Color.white.opacity(_iconPulse ? 0.1 : 0.0))
							}
						)
						.cornerRadius(14)
						.shadow(color: .gray.opacity(_iconPulse ? 0.6 : 0.3), radius: _iconPulse ? 12 : 6, y: 2)
						.scaleEffect(_iconPulse ? 1.02 : 1.0)
						.padding(.horizontal)
						.padding(.bottom, 8)
					}
					.compatMatchedTransitionSource(id: "showLogs", ns: _namespace)
					.onAppear {
						// Start continuous animations
						withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
							_iconPulse = true
						}
						withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
							_progressRotation = 360
						}
					}
					.onDisappear {
						_iconPulse = false
						_progressRotation = 0
					}
				} else {
					Button() {
						// Tap animation
						withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
							_buttonScale = 0.95
						}
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
								_buttonScale = 1.0
							}
							_startModify()
						}
					} label: {
						HStack(spacing: 8) {
							Image(systemName: "pencil.and.outline")
								.font(.headline)
							Text(.localized("Apply Modifications"))
								.font(.headline)
						}
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(
							LinearGradient(
								colors: [.orange, .red],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(14)
						.shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
						.scaleEffect(_buttonScale)
						.padding(.horizontal)
						.padding(.bottom, 8)
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .dismiss)
				
				NBToolbarButton(
					.localized("Reset"),
					style: .text,
					placement: .topBarTrailing
				) {
					_temporaryOptions = OptionsManager.shared.options
					appIcon = nil
				}
			}
			.sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
			.sheet(isPresented: $_isFilePickerPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.image],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
					}
				)
			}
			.photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
			.fullScreenCover(isPresented: $_isLogsPresenting ) {
				LogsView(manager: LogsManager.shared)
					.compatNavigationTransition(id: "showLogs", ns: _namespace)
			}
			.onChange(of: _selectedPhoto) { newValue in
				guard let newValue else { return }
				
				Task {
					if let data = try? await newValue.loadTransferable(type: Data.self),
					   let image = UIImage(data: data)?.resizeToSquare() {
						appIcon = image
					}
				}
			}
			.animation(.smooth, value: _isModifying)
		}
		.onAppear {
			// Set onlyModify to true since we're only modifying
			_temporaryOptions.onlyModify = true
			
			if
				let currentBundleId = app.identifier,
				let newBundleId = _temporaryOptions.identifiers[currentBundleId]
			{
				_temporaryOptions.appIdentifier = newBundleId
			}
			
			if
				let currentName = app.name,
				let newName = _temporaryOptions.displayNames[currentName]
			{
				_temporaryOptions.appName = newName
			}
			
			// Load existing App Store link
			if let bundleId = app.identifier,
			   let savedLink = UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") {
				_appStoreLink = savedLink
			}
		}
    }
}

// MARK: - Extension: View
extension ModifyView {
	@ViewBuilder
	private func _customizationOptions(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("App Icon")) {
			Menu {
				Button(.localized("Select Alternative Icon")) { _isAltPickerPresenting = true }
				Button(.localized("Choose from Files")) { _isFilePickerPresenting = true }
				Button(.localized("Choose from Photos")) { _isImagePickerPresenting = true }
			} label: {
				VStack(spacing: 12) {
				// Centered icon - no border for clean look
				ZStack {
					// App icon
					if let icon = appIcon {
						Image(uiImage: icon)
							.appIconStyle(size: 80)
					} else {
						FRAppIconView(app: app, size: 80)
					}
				}
					
					// Tap to change text
					HStack(spacing: 4) {
						Text(.localized("Tap to change"))
							.font(.caption)
							.foregroundColor(.secondary)
						Image(systemName: "chevron.down")
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 8)
			}
		}
		
		NBSection(.localized("Basic Info")) {
			_infoCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name) {
				SigningPropertiesView(
					title: .localized("Name"),
					initialValue: _temporaryOptions.appName ?? (app.name ?? ""),
					bindingValue: $_temporaryOptions.appName
				)
			}
			_infoCell(.localized("Bundle ID"), desc: _temporaryOptions.appIdentifier ?? app.identifier) {
				SigningPropertiesView(
					title: .localized("Bundle Identifier"),
					initialValue: _temporaryOptions.appIdentifier ?? (app.identifier ?? ""),
					bindingValue: $_temporaryOptions.appIdentifier
				)
			}
			_infoCell(.localized("Version"), desc: _temporaryOptions.appVersion ?? app.version) {
				SigningPropertiesView(
					title: .localized("Version"),
					initialValue: _temporaryOptions.appVersion ?? (app.version ?? ""),
					bindingValue: $_temporaryOptions.appVersion
				)
			}
		}
		
		NBSection(.localized("App Properties")) {
			// Display only - not editable but useful info
			LabeledContent(.localized("Size")) {
				if let size = app.size {
					Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
				} else {
					Text(.localized("Unknown"))
				}
			}
			
			LabeledContent(.localized("Type")) {
				Text(app.type?.rawValue.capitalized ?? .localized("Unknown"))
			}
			
			LabeledContent(.localized("Min iOS")) {
				Text(_temporaryOptions.minimumAppRequirement)
					.foregroundColor(.secondary)
			}
			
			LabeledContent(.localized("Appearance")) {
				Text(_temporaryOptions.appAppearance)
					.foregroundColor(.secondary)
			}
		}
		
		// App Store Link Section
		NBSection(.localized("App Store Link")) {
			_appStoreLinkEditor(for: app)
		}
	}
	
	@ViewBuilder
	private func _modifySettings() -> some View {
		NBSection(.localized("Modification")) {
			// Info banner
			HStack(spacing: 12) {
				Image(systemName: "info.circle.fill")
					.font(.title2)
					.foregroundColor(.orange)
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("Modify Only Mode"))
						.fontWeight(.semibold)
					Text(.localized("Changes will be applied without code signing. The app will keep its original signature."))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.padding(.vertical, 4)
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Advanced")) {
			NavigationLink {
				SigningDylibView(
					app: app,
					options: $_temporaryOptions.optional()
				)
			} label: {
				Label {
					Text(.localized("Edit URL Schemes"))
				} icon: {
					Image(systemName: "link")
						.foregroundColor(.orange)
				}
			}
			
			NavigationLink {
				SigningFrameworksView(
					app: app,
					options: $_temporaryOptions.optional()
				)
			} label: {
				Label {
					Text(.localized("Frameworks & Plugins"))
				} icon: {
					Image(systemName: "puzzlepiece.extension")
						.foregroundColor(.orange)
				}
			}
			
			NavigationLink {
				Text("Orientations View") // Placeholder
			} label: {
				Label {
					Text(.localized("Supported Orientations"))
				} icon: {
					Image(systemName: "rotate.right")
						.foregroundColor(.orange)
				}
			}
		}
		
		// Tweaks & Mods Section
		NBSection(.localized("Tweaks & Mods")) {
			// Import local tweaks
			NavigationLink {
				SigningTweaksView(
					options: $_temporaryOptions
				)
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 2) {
						Text(.localized("Import Tweaks"))
							.fontWeight(.medium)
						Text(.localized("Import local .dylib or .deb files"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				} icon: {
					Image(systemName: "plus.circle.fill")
						.foregroundColor(.orange)
				}
			}
			
			// Download pre-made tweaks
			NavigationLink {
				GameTweaksView()
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 2) {
						Text(.localized("Download Tweaks"))
							.fontWeight(.medium)
						Text(.localized("15+ IAP bypass, social media mods, & more"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				} icon: {
					Image(systemName: "arrow.down.circle.fill")
						.foregroundColor(.purple)
				}
			}
		}
		
		// All Properties
		NBSection(.localized("All Properties")) {
			NavigationLink {
				Form { SigningOptionsView(
					options: $_temporaryOptions,
					temporaryOptions: _optionsManager.options
				)}
				.navigationTitle(.localized("All Properties"))
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 2) {
						Text(.localized("All Modification Options"))
							.fontWeight(.medium)
						Text(.localized("Orientation, Network, Security, Background & more"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				} icon: {
					Image(systemName: "slider.horizontal.3")
						.foregroundColor(.orange)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _infoCell<V: View>(_ title: String, desc: String?, @ViewBuilder destination: () -> V) -> some View {
		NavigationLink {
			destination()
		} label: {
			LabeledContent(title) {
				Text(desc ?? .localized("Unknown"))
			}
		}
	}
	
	@ViewBuilder
	private func _appStoreLinkEditor(for app: AppInfoPresentable) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			// Info text
			HStack(spacing: 8) {
				Image(systemName: "apple.logo")
					.font(.title3)
					.foregroundColor(.primary)
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("App Store Link"))
						.font(.subheadline)
						.fontWeight(.medium)
					Text(.localized("Used for downloading older versions"))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			
			// Link input field
			HStack(spacing: 8) {
				TextField(.localized("https://apps.apple.com/app/id..."), text: $_appStoreLink)
					.textFieldStyle(.roundedBorder)
					.autocapitalization(.none)
					.disableAutocorrection(true)
					.font(.system(.body, design: .monospaced))
				
				// Paste button
				Button {
					if let clipboardContent = UIPasteboard.general.string {
						_appStoreLink = clipboardContent
					}
				} label: {
					Image(systemName: "doc.on.clipboard")
						.font(.body)
						.foregroundColor(.accentColor)
				}
				.buttonStyle(.borderless)
			}
			
			// Action buttons
			HStack(spacing: 12) {
				// Save button
				Button {
					_saveAppStoreLink()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "checkmark.circle.fill")
							.font(.caption)
						Text(.localized("Save Link"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(
						LinearGradient(
							colors: [.green, .green.opacity(0.8)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.cornerRadius(8)
				}
				.buttonStyle(.borderless)
				.disabled(_appStoreLink.isEmpty)
				
				// Auto-lookup button
				Button {
					_lookupAppStoreLink()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "magnifyingglass")
							.font(.caption)
						Text(.localized("Auto Lookup"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(
						LinearGradient(
							colors: [.blue, .purple],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.cornerRadius(8)
				}
				.buttonStyle(.borderless)
				
				Spacer()
				
				// Clear button
				if !_appStoreLink.isEmpty {
					Button {
						_appStoreLink = ""
						_saveAppStoreLink()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.body)
							.foregroundColor(.secondary)
					}
					.buttonStyle(.borderless)
				}
			}
			
			// Status indicator
			if !_appStoreLink.isEmpty {
				HStack(spacing: 6) {
					Image(systemName: "checkmark.seal.fill")
						.font(.caption)
						.foregroundColor(.green)
					Text(.localized("Link saved - Downgrade will use this link"))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
		}
		.padding(.vertical, 4)
	}
	
	private func _saveAppStoreLink() {
		guard let bundleId = app.identifier else { return }
		
		if _appStoreLink.isEmpty {
			UserDefaults.standard.removeObject(forKey: "AppStoreLink_\(bundleId)")
		} else {
			UserDefaults.standard.set(_appStoreLink, forKey: "AppStoreLink_\(bundleId)")
		}
		
		UINotificationFeedbackGenerator().notificationOccurred(.success)
	}
	
	private func _lookupAppStoreLink() {
		guard let bundleId = app.identifier else { return }
		
		Task {
			if let appInfo = await AppStoreClient.shared.lookupApp(bundleId: bundleId) {
				await MainActor.run {
					_appStoreLink = appInfo.appStoreLink
					_saveAppStoreLink()
				}
			} else {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: .localized("Not Found"),
						message: .localized("This app could not be found in the App Store.")
					)
				}
			}
		}
	}
}

// MARK: - Extension: Action
extension ModifyView {
	private func _startModify() {
		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
		_isLogsPresenting = _optionsManager.options.signingLogs
		_isModifying = true
		
		// Force onlyModify to true
		_temporaryOptions.onlyModify = true
		
		// Add to ModifyingAppsManager so it shows in Library
		let activityId = UUID()
		ModifyingAppsManager.shared.addActivity(
			id: activityId,
			name: app.name ?? "Unknown",
			bundleId: app.identifier ?? "unknown",
			iconURL: app.iconURL
		)
		ModifyingAppsManager.shared.updateStatus(id: activityId, status: .inProgress)
		
		// Close view so user can see progress in Library
		dismiss()
		
#if DEBUG
		LogsManager.shared.startCapture()
#endif
		FR.signPackageFile(
			app,
			using: _temporaryOptions,
			icon: appIcon,
			certificate: nil // No certificate needed for modify-only
		) { error in
			DispatchQueue.main.async {
				if let error = error {
					ModifyingAppsManager.shared.updateStatus(id: activityId, status: .failed(error.localizedDescription))
					// Remove failed after delay
					DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
						ModifyingAppsManager.shared.removeActivity(id: activityId)
					}
				} else {
					// Success
					ModifyingAppsManager.shared.updateProgress(id: activityId, progress: 1.0)
					ModifyingAppsManager.shared.updateStatus(id: activityId, status: .completed)
					UINotificationFeedbackGenerator().notificationOccurred(.success)
				}
			}
		}
	}
}
