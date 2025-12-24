//
//  BulkSigningView.swift
//  Ksign
//
//  Created by Nagata Asami on 11/9/25.
//

import SwiftUI
import NimbleViews
import PhotosUI

struct BulkSigningView: View {
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var certificates: FetchedResults<CertificatePair>
	
	private func _selectedCert() -> CertificatePair? {
		guard certificates.indices.contains(_temporaryCertificate) else { return nil }
		return certificates[_temporaryCertificate]
	}
	
	@StateObject private var _optionsManager = OptionsManager.shared
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _temporaryCertificate: Int
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isSigning = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	@State private var _selectedAppForIcon: AnyApp?
	@State private var _appStoreLinks: [String: String] = [:] // bundleId -> link
	
	@Environment(\.dismiss) private var dismiss
	var apps: [AppInfoPresentable]

	init(apps: [AppInfoPresentable]) {
		self.apps = apps
		let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		__temporaryCertificate = State(initialValue: storedCert)
	}

	@State private var _currentAppIndex: Int = 0
	
	var body: some View {
		NBNavigationView(.localized("Bulk Signing"), displayMode: .inline) {
			VStack(spacing: 0) {
				// App selector tabs at top
				if apps.count > 1 {
					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 12) {
							ForEach(Array(apps.enumerated()), id: \.element.uuid) { index, app in
								Button {
									withAnimation(.spring(response: 0.3)) {
										_currentAppIndex = index
									}
								} label: {
									VStack(spacing: 4) {
										FRAppIconView(app: app, size: 50)
										Text(app.name ?? "App")
											.font(.caption2)
											.lineLimit(1)
											.frame(maxWidth: 60)
									}
									.padding(.vertical, 8)
									.padding(.horizontal, 4)
									.background(
										RoundedRectangle(cornerRadius: 12)
											.fill(_currentAppIndex == index ? Color.accentColor.opacity(0.15) : Color.clear)
									)
									.overlay(
										RoundedRectangle(cornerRadius: 12)
											.stroke(_currentAppIndex == index ? Color.accentColor : Color.clear, lineWidth: 2)
									)
								}
								.buttonStyle(.plain)
							}
						}
						.padding(.horizontal)
						.padding(.vertical, 8)
					}
					.background(Color(.systemGroupedBackground))
					
					Divider()
				}
				
				// Horizontal paging for each app's settings
				TabView(selection: $_currentAppIndex) {
					ForEach(Array(apps.enumerated()), id: \.element.uuid) { index, app in
						Form {
							_cert()
							Section {
								_customizationOptions(for: app)
								_customizationProperties(for: app)
							}
						}
						.tag(index)
					}
				}
				.tabViewStyle(.page(indexDisplayMode: apps.count > 1 ? .automatic : .never))
			}
			.safeAreaInset(edge: .bottom) {
				Button {
					_start()
				} label: {
					HStack(spacing: 8) {
						Image(systemName: "signature")
							.font(.headline)
						Text(.localized("Sign All (\(apps.count))"))
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
			.toolbar {
				NBToolbarButton(role: .dismiss)
				
				ToolbarItemGroup(placement: .topBarTrailing) {
					Button {
						_temporaryOptions = OptionsManager.shared.options
						appIcon = nil
					} label: {
						Image(systemName: "arrow.counterclockwise")
							.font(.title3)
					}
				}
			}
			.sheet(isPresented: $_isAltPickerPresenting) {
				if let selected = _selectedAppForIcon {
					SigningAlternativeIconView(app: selected.base, appIcon: $appIcon, isModifing: .constant(true))
				}
			}
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
			.onChange(of: _selectedPhoto) { newValue in
				guard let newValue else { return }
				
				Task {
					if let data = try? await newValue.loadTransferable(type: Data.self),
					   let image = UIImage(data: data)?.resizeToSquare() {
						appIcon = image
					}
				}
			}
			.disabled(_isSigning)
			.animation(.smooth, value: _isSigning)
		}
	}
}

extension BulkSigningView {
	@ViewBuilder
	private func _customizationOptions(for app: AppInfoPresentable) -> some View {
			Menu {
				Button(.localized("Select Alternative Icon")) { _isAltPickerPresenting = true }
				Button(.localized("Choose from Files")) { _isFilePickerPresenting = true }
				Button(.localized("Choose from Photos")) { _isImagePickerPresenting = true }
			} label: {
				FRAppIconView(app: app, size: 55)
			}
			_infoCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name) {
				SigningPropertiesView(
					title: .localized("Name"),
					initialValue: _temporaryOptions.appName ?? (app.name ?? ""),
					bindingValue: $_temporaryOptions.appName
				)
			}
			_infoCell(.localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier) {
				SigningPropertiesView(
					title: .localized("Identifier"),
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
			
			// App Store Link Section
			_appStoreLinkEditor(for: app)
	}
	

	@ViewBuilder
	private func _cert() -> some View {
		NBSection(.localized("Signing")) {
			if let cert = _selectedCert() {
				NavigationLink {
					CertificatesView(selectedCert: $_temporaryCertificate)
				} label: {
					CertificatesCellView(
						cert: cert
					)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
			DisclosureGroup(.localized("Modify")) {
				NavigationLink(.localized("Existing Dylibs")) {
					SigningDylibView(
						app: app,
						options: $_temporaryOptions.optional()
					)
				}
				
				NavigationLink(String.localized("Frameworks & PlugIns")) {
					SigningFrameworksView(
						app: app,
						options: $_temporaryOptions.optional()
					)
				}
				#if NIGHTLY || DEBUG
				NavigationLink(String.localized("Entitlements")) {
					SigningEntitlementsView(
						bindingValue: $_temporaryOptions.appEntitlementsFile
					)
				}
				#endif
				NavigationLink(String.localized("Tweaks")) {
					SigningTweaksView(
						options: $_temporaryOptions
					)
				}
			}
			
			NavigationLink(String.localized("Properties")) {
				Form { SigningOptionsView(
					options: $_temporaryOptions,
					temporaryOptions: _optionsManager.options
				)}
			.navigationTitle(.localized("Properties"))
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
		let bundleId = app.identifier ?? ""
		let currentLink = _appStoreLinks[bundleId] ?? UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") ?? ""
		
		DisclosureGroup(.localized("App Store Link")) {
			VStack(alignment: .leading, spacing: 10) {
				HStack(spacing: 8) {
					TextField(.localized("https://apps.apple.com/app/id..."), text: Binding(
						get: { _appStoreLinks[bundleId] ?? UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") ?? "" },
						set: { _appStoreLinks[bundleId] = $0 }
					))
					.textFieldStyle(.roundedBorder)
					.autocapitalization(.none)
					.font(.system(.caption, design: .monospaced))
					
					Button {
						if let clipboardContent = UIPasteboard.general.string {
							_appStoreLinks[bundleId] = clipboardContent
						}
					} label: {
						Image(systemName: "doc.on.clipboard")
							.font(.caption)
							.foregroundColor(.accentColor)
					}
					.buttonStyle(.borderless)
				}
				
				HStack(spacing: 8) {
					Button {
						_saveAppStoreLink(for: bundleId)
					} label: {
						Text(.localized("Save"))
							.font(.caption)
							.foregroundColor(.white)
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(Color.green)
							.cornerRadius(4)
					}
					.buttonStyle(.borderless)
					
					Button {
						_lookupAppStoreLink(for: app)
					} label: {
						Text(.localized("Lookup"))
							.font(.caption)
							.foregroundColor(.white)
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(Color.blue)
							.cornerRadius(4)
					}
					.buttonStyle(.borderless)
					
					Spacer()
					
					if !currentLink.isEmpty {
						Image(systemName: "checkmark.seal.fill")
							.font(.caption)
							.foregroundColor(.green)
					}
				}
			}
		}
	}
	
	private func _saveAppStoreLink(for bundleId: String) {
		guard !bundleId.isEmpty else { return }
		
		if let link = _appStoreLinks[bundleId], !link.isEmpty {
			UserDefaults.standard.set(link, forKey: "AppStoreLink_\(bundleId)")
		} else {
			UserDefaults.standard.removeObject(forKey: "AppStoreLink_\(bundleId)")
		}
		UINotificationFeedbackGenerator().notificationOccurred(.success)
	}
	
	private func _lookupAppStoreLink(for app: AppInfoPresentable) {
		guard let bundleId = app.identifier else { return }
		
		Task {
			if let appInfo = await AppStoreClient.shared.lookupApp(bundleId: bundleId) {
				await MainActor.run {
					_appStoreLinks[bundleId] = appInfo.appStoreLink
					_saveAppStoreLink(for: bundleId)
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
		_isSigning = true
		
		// Dismiss immediately so user can see progress in Library
		dismiss()
		
		// Add all apps to SigningAppsManager
		var activityIds: [String: UUID] = [:]
		for app in apps {
			let activityId = UUID()
			activityIds[app.uuid ?? UUID().uuidString] = activityId
			SigningAppsManager.shared.addActivity(
				id: activityId,
				name: app.name ?? "Unknown",
				bundleId: app.identifier ?? "unknown",
				iconURL: app.iconURL
			)
		}
		
		// Sign each app with progress tracking
		for (index, app) in apps.enumerated() {
			let activityId = activityIds[app.uuid ?? UUID().uuidString]!
			
			// Update status to in progress
			SigningAppsManager.shared.updateStatus(id: activityId, status: .inProgress)
			SigningAppsManager.shared.updateProgress(id: activityId, progress: Double(index) / Double(apps.count))
			
			FR.signPackageFile(
				app,
				using: _temporaryOptions,
				icon: appIcon,
				certificate: _selectedCert()
			) { error in
				DispatchQueue.main.async {
					if let error {
						SigningAppsManager.shared.updateStatus(id: activityId, status: .failed(error.localizedDescription))
						// Remove failed after delay
						DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
							SigningAppsManager.shared.removeActivity(id: activityId)
						}
					} else {
						SigningAppsManager.shared.updateProgress(id: activityId, progress: 1.0)
						SigningAppsManager.shared.updateStatus(id: activityId, status: .completed)
					}
					
					// Post notification when all complete
					if index == apps.count - 1 {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
							NotificationCenter.default.post(name: NSNotification.Name("ksign.bulkSigningFinished"), object: nil)
						}
					}
				}
			}
		}

	}
}
