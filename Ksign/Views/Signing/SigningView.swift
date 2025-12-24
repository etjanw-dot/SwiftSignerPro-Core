//
//  SigningView.swift
//  Feather
//
//  Created by samara on 14.04.2025.
//

import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
	@Environment(\.dismiss) var dismiss
	@Namespace var _namespace

	@StateObject private var _optionsManager = OptionsManager.shared
	
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _temporaryCertificate: Int
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isLogsPresenting = false
	@State private var _isSigning = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	@State private var _appStoreLink: String = ""
	
	var signAndInstall: Bool = false
	
	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var certificates: FetchedResults<CertificatePair>
	
	private func _selectedCert() -> CertificatePair? {
		guard certificates.indices.contains(_temporaryCertificate) else { return nil }
		return certificates[_temporaryCertificate]
	}
	
	private func _getCertAppID() -> String? {
		guard
			let cert = _selectedCert(),
			let decoded = Storage.shared.getProvisionFileDecoded(for: cert),
			let entitlements = decoded.Entitlements,
			let appID = entitlements["application-identifier"]?.value as? String
		else {
			return nil
		}
		return appID.split(separator: ".").dropFirst().joined(separator: ".")
	}
	
	var app: AppInfoPresentable
	
	init(app: AppInfoPresentable, signAndInstall: Bool = false) {
		self.app = app
		self.signAndInstall = signAndInstall
		let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		__temporaryCertificate = State(initialValue: storedCert)
	}
		
	// MARK: Body
    var body: some View {
		NBNavigationView(app.name ?? .localized("Unknown"), displayMode: .inline) {
			Form {
				_customizationOptions(for: app)
				_cert()
				_customizationProperties(for: app)
			}
			.disabled(_isSigning)
			.safeAreaInset(edge: .bottom) {
				if _isSigning {
					Button() {
						_isLogsPresenting = true
					} label: {
						HStack(spacing: 8) {
							ProgressView()
								.progressViewStyle(CircularProgressViewStyle(tint: .white))
							Text(.localized("Signing..."))
								.font(.headline)
						}
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(
							LinearGradient(
								colors: [.gray, .secondary],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(14)
						.padding(.horizontal)
						.padding(.bottom, 8)
					}
					.compatMatchedTransitionSource(id: "showLogs", ns: _namespace)
				} else {
					Button() {
						_start()
					} label: {
						HStack(spacing: 8) {
							Image(systemName: "signature")
								.font(.headline)
							Text(.localized("Start Signing"))
								.font(.headline)
						}
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(
							LinearGradient(
								colors: [.blue, .purple],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(14)
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
			.animation(.smooth, value: _isSigning)
		}
		.onAppear {
			// ppq protection
			if
				_optionsManager.options.ppqProtection,
				let identifier = app.identifier,
				let cert = _selectedCert(),
				cert.ppQCheck
			{
				_temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
			}
			
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
			
			// Load App Store link
			if let bundleId = app.identifier,
			   let savedLink = UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") {
				_appStoreLink = savedLink
			}
		}
    }
}

// MARK: - Extension: View
extension SigningView {
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
					certAppId: _getCertAppID(),
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
	private func _cert() -> some View {
		NBSection(.localized("Certificate")) {
			if let cert = _selectedCert() {
				NavigationLink {
					CertificatesView(selectedCert: $_temporaryCertificate)
				} label: {
					CertificatesCellView(
						cert: cert
					)
				}
			} else {
				NavigationLink {
					CertificatesView(selectedCert: $_temporaryCertificate)
				} label: {
					Label {
						Text(.localized("Select Certificate"))
					} icon: {
						Image(systemName: "signature")
							.foregroundColor(.accentColor)
					}
				}
			}
		}
		
		NBSection(.localized("Signing")) {
			// Link to full Signing Settings
			NavigationLink {
				SigningSettingsView()
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 2) {
						Text(.localized("Signing Settings"))
							.fontWeight(.medium)
						Text(.localized("Installation Method, Button Type, Cert Export"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				} icon: {
					Image(systemName: "gearshape.fill")
						.foregroundColor(.accentColor)
				}
			}
			
			// Signing Method (quick access)
			Picker(selection: $_temporaryOptions.signingMethod) {
				ForEach(Options.signingMethodValues, id: \.self) { method in
					Text(method).tag(method)
				}
			} label: {
				Label {
					Text(.localized("Method"))
				} icon: {
					Image(systemName: "gearshape.2.fill")
						.foregroundColor(.accentColor)
				}
			}
			
			// PPQ Protection Toggle
			Toggle(isOn: $_temporaryOptions.ppqProtection) {
				Label {
					Text(.localized("PPQ Protection"))
				} icon: {
					Image(systemName: "shield.fill")
						.foregroundColor(.accentColor)
				}
			}
			
			// Adhoc Signing Toggle
			Toggle(isOn: $_temporaryOptions.doAdhocSigning) {
				Label {
					Text(.localized("Ad Hoc Signing"))
				} icon: {
					Image(systemName: "signature")
						.foregroundColor(.accentColor)
				}
			}
			
			// Only Modify Toggle
			Toggle(isOn: $_temporaryOptions.onlyModify) {
				Label {
					Text(.localized("Only Modify (No Sign)"))
				} icon: {
					Image(systemName: "pencil.slash")
						.foregroundColor(.accentColor)
				}
			}
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
						.foregroundColor(.accentColor)
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
						.foregroundColor(.accentColor)
				}
			}
			
			NavigationLink {
				Text("Orientations View") // Placeholder
			} label: {
				Label {
					Text(.localized("Supported Orientations"))
				} icon: {
					Image(systemName: "rotate.right")
						.foregroundColor(.accentColor)
				}
			}
			
			Toggle(isOn: $_temporaryOptions.onlyModify) {
				Label {
					Text(.localized("Use Developer Certificate"))
				} icon: {
					Image(systemName: "hammer")
						.foregroundColor(.accentColor)
				}
			}
			
			#if NIGHTLY || DEBUG
			NavigationLink {
				SigningEntitlementsView(
					bindingValue: $_temporaryOptions.appEntitlementsFile
				)
			} label: {
				Label {
					Text(.localized("Entitlements"))
				} icon: {
					Image(systemName: "key")
						.foregroundColor(.accentColor)
				}
			}
			#endif
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
						.foregroundColor(.accentColor)
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
		
		// All Signing Properties
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
						Text(.localized("All Signing Options"))
							.fontWeight(.medium)
						Text(.localized("Orientation, Network, Security, Background & more"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				} icon: {
					Image(systemName: "slider.horizontal.3")
						.foregroundColor(.accentColor)
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
	
	// MARK: - App Store Link Editor
	
	@ViewBuilder
	private func _appStoreLinkEditor(for app: AppInfoPresentable) -> some View {
		VStack(alignment: .leading, spacing: 12) {
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
			
			HStack(spacing: 8) {
				TextField(.localized("https://apps.apple.com/app/id..."), text: $_appStoreLink)
					.textFieldStyle(.roundedBorder)
					.autocapitalization(.none)
					.disableAutocorrection(true)
					.font(.system(.caption, design: .monospaced))
				
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
			
			HStack(spacing: 12) {
				Button {
					_saveAppStoreLink()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "checkmark.circle.fill")
							.font(.caption)
						Text(.localized("Save"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(Color.green)
					.cornerRadius(6)
				}
				.buttonStyle(.borderless)
				
				Button {
					_lookupAppStoreLink()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "magnifyingglass")
							.font(.caption)
						Text(.localized("Lookup"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(
						LinearGradient(
							colors: [.blue, .purple],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.cornerRadius(6)
				}
				.buttonStyle(.borderless)
				
				Spacer()
			}
			
			if !_appStoreLink.isEmpty {
				HStack(spacing: 4) {
					Image(systemName: "checkmark.seal.fill")
						.font(.caption2)
						.foregroundColor(.green)
					Text(.localized("Link saved"))
						.font(.caption2)
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

// MARK: - Extension: View (import)
extension SigningView {
	private func _start() {
		guard _selectedCert() != nil || _temporaryOptions.doAdhocSigning || _temporaryOptions.onlyModify else {
			UIAlertController.showAlertWithOk(
				title: .localized("No Certificate"),
				message: .localized("Please go to settings and import a valid certificate"),
				isCancel: true
			)
			return
		}

		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
		_isLogsPresenting = _optionsManager.options.signingLogs
		_isSigning = true
		
		// Add to SigningAppsManager so it shows in Library
		let activityId = UUID()
		SigningAppsManager.shared.addActivity(
			id: activityId,
			name: app.name ?? "Unknown",
			bundleId: app.identifier ?? "unknown",
			iconURL: app.iconURL
		)
		SigningAppsManager.shared.updateStatus(id: activityId, status: .inProgress)
		
		// Close view so user can see progress in Library
		dismiss()
		
#if DEBUG
		LogsManager.shared.startCapture()
#endif
		FR.signPackageFile(
			app,
			using: _temporaryOptions,
			icon: appIcon,
			certificate: _selectedCert()
		) { error in
			DispatchQueue.main.async {
				if let error = error {
					SigningAppsManager.shared.updateStatus(id: activityId, status: .failed(error.localizedDescription))
					// Remove failed after delay
					DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
						SigningAppsManager.shared.removeActivity(id: activityId)
					}
				} else {
					// Success
					SigningAppsManager.shared.updateProgress(id: activityId, progress: 1.0)
					SigningAppsManager.shared.updateStatus(id: activityId, status: .completed)
					
					// Remove app after signed option thing
					if _temporaryOptions.removeApp && !app.isSigned {
						Storage.shared.deleteApp(for: app)
					}
                
					if signAndInstall {
                    	DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        	NotificationCenter.default.post(
                            	name: NSNotification.Name("feather.installApp"),
                            	object: nil
                        	)
                    	}
                	}
				}
			}
		}
	}
}
