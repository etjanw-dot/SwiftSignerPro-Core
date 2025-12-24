//
//  BulkModifyView.swift
//  SwiftSigner Pro
//
//  Bulk modify multiple apps at once - change icons, names, inject tweaks without signing
//

import SwiftUI
import NimbleViews
import PhotosUI

struct BulkModifyView: View {
	@StateObject private var _optionsManager = OptionsManager.shared
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isModifying = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	@State private var _selectedAppForIcon: AnyApp?
	@State private var _appStoreLinks: [String: String] = [:] // bundleId -> link
	@Namespace private var _namespace
	
	@Environment(\.dismiss) private var dismiss
	var apps: [AppInfoPresentable]

	init(apps: [AppInfoPresentable]) {
		self.apps = apps
	}

	@State private var _currentAppIndex: Int = 0
	
	var body: some View {
		NBNavigationView(.localized("Bulk Modify"), displayMode: .inline) {
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
											.fill(_currentAppIndex == index ? Color.orange.opacity(0.15) : Color.clear)
									)
									.overlay(
										RoundedRectangle(cornerRadius: 12)
											.stroke(_currentAppIndex == index ? Color.orange : Color.clear, lineWidth: 2)
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
							_modifyInfo()
							_customizationOptions(for: app)
							_customizationProperties(for: app)
						}
						.tag(index)
					}
				}
				.tabViewStyle(.page(indexDisplayMode: apps.count > 1 ? .automatic : .never))
			}
			.safeAreaInset(edge: .bottom) {
				VStack(spacing: 8) {
					// Modify All button
					Button {
						_startModifyAll()
					} label: {
						HStack(spacing: 8) {
							Image(systemName: "pencil.and.outline")
								.font(.headline)
							Text(.localized("Modify All (\(apps.count))"))
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
						.padding(.horizontal)
					}
				}
				.padding(.bottom, 8)
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
			.disabled(_isModifying)
			.animation(.smooth, value: _isModifying)
		}
		.onAppear {
			_temporaryOptions.onlyModify = true
		}
	}
}

extension BulkModifyView {
	@ViewBuilder
	private func _modifyInfo() -> some View {
		NBSection(.localized("Modification")) {
			HStack(spacing: 12) {
				Image(systemName: "info.circle.fill")
					.font(.title2)
					.foregroundColor(.orange)
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("Bulk Modify Mode"))
						.fontWeight(.semibold)
					Text(.localized("Changes will be applied to all \(apps.count) apps without signing."))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.padding(.vertical, 4)
		}
	}
	
	@ViewBuilder
	private func _customizationOptions(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("App Icon")) {
			Menu {
				Button(.localized("Select Alternative Icon")) { 
					_selectedAppForIcon = AnyApp(base: app)
					_isAltPickerPresenting = true 
				}
				Button(.localized("Choose from Files")) { _isFilePickerPresenting = true }
				Button(.localized("Choose from Photos")) { _isImagePickerPresenting = true }
			} label: {
				VStack(spacing: 12) {
					ZStack {
						if let icon = appIcon {
							Image(uiImage: icon)
								.appIconStyle(size: 80)
						} else {
							FRAppIconView(app: app, size: 80)
						}
					}
					
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
		
		// App Store Link Section
		NBSection(.localized("App Store Link")) {
			_appStoreLinkEditor(for: app)
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Tweaks & Mods")) {
			NavigationLink {
				SigningTweaksView(options: $_temporaryOptions)
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

	private func _startModifyAll() {
		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
		_isModifying = true
		
		_temporaryOptions.onlyModify = true
		
		// Dismiss immediately so user can see progress in Library
		dismiss()
		
		// Add all apps to ModifyingAppsManager
		var activityIds: [String: UUID] = [:]
		for app in apps {
			let activityId = UUID()
			activityIds[app.uuid ?? UUID().uuidString] = activityId
			ModifyingAppsManager.shared.addActivity(
				id: activityId,
				name: app.name ?? "Unknown",
				bundleId: app.identifier ?? "unknown",
				iconURL: app.iconURL
			)
		}
		
		var completedCount = 0
		let totalCount = apps.count
		
		// Modify each app with progress tracking
		for (index, app) in apps.enumerated() {
			let activityId = activityIds[app.uuid ?? UUID().uuidString]!
			
			// Update status to in progress
			ModifyingAppsManager.shared.updateStatus(id: activityId, status: .inProgress)
			ModifyingAppsManager.shared.updateProgress(id: activityId, progress: Double(index) / Double(totalCount))
			
			FR.signPackageFile(
				app,
				using: _temporaryOptions,
				icon: appIcon,
				certificate: nil
			) { error in
				completedCount += 1
				
				DispatchQueue.main.async {
					if let error = error {
						ModifyingAppsManager.shared.updateStatus(id: activityId, status: .failed(error.localizedDescription))
						// Remove failed after delay
						DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
							ModifyingAppsManager.shared.removeActivity(id: activityId)
						}
					} else {
						ModifyingAppsManager.shared.updateProgress(id: activityId, progress: 1.0)
						ModifyingAppsManager.shared.updateStatus(id: activityId, status: .completed)
					}
					
					if completedCount == totalCount {
						UINotificationFeedbackGenerator().notificationOccurred(.success)
						NotificationCenter.default.post(name: NSNotification.Name("ksign.bulkModifyFinished"), object: nil)
					}
				}
			}
		}
	}
	
	// MARK: - App Store Link Editor
	
	@ViewBuilder
	private func _appStoreLinkEditor(for app: AppInfoPresentable) -> some View {
		let bundleId = app.identifier ?? ""
		let currentLink = _appStoreLinks[bundleId] ?? UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") ?? ""
		
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
				TextField(.localized("https://apps.apple.com/app/id..."), text: Binding(
					get: { _appStoreLinks[bundleId] ?? UserDefaults.standard.string(forKey: "AppStoreLink_\(bundleId)") ?? "" },
					set: { _appStoreLinks[bundleId] = $0 }
				))
				.textFieldStyle(.roundedBorder)
				.autocapitalization(.none)
				.disableAutocorrection(true)
				.font(.system(.caption, design: .monospaced))
				
				Button {
					if let clipboardContent = UIPasteboard.general.string {
						_appStoreLinks[bundleId] = clipboardContent
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
					_saveAppStoreLink(for: bundleId)
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
					_lookupAppStoreLink(for: app)
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
			
			if !currentLink.isEmpty {
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
}
