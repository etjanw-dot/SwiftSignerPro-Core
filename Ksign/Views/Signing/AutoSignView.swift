//
//  AutoSignView.swift
//  SwiftSigner Pro
//
//  Configure auto-sign settings - tweaks, icons, options that apply automatically when signing
//

import SwiftUI
import NimbleViews
import PhotosUI
import CoreData

struct AutoSignView: View {
	@Environment(\.dismiss) var dismiss
	
	@StateObject private var _optionsManager = OptionsManager.shared
	@State private var _autoSignEnabled: Bool = UserDefaults.standard.bool(forKey: "ksign.autoSignEnabled")
	@State private var _autoSignOptions: Options = OptionsManager.shared.options
	
	// Auto-sign specific settings
	@State private var _autoInjectTweaks: Bool = UserDefaults.standard.bool(forKey: "ksign.autoInjectTweaks")
	@State private var _autoChangeIcon: Bool = UserDefaults.standard.bool(forKey: "ksign.autoChangeIcon")
	@State private var _autoChangeName: Bool = UserDefaults.standard.bool(forKey: "ksign.autoChangeName")
	@State private var _autoChangeBundleId: Bool = UserDefaults.standard.bool(forKey: "ksign.autoChangeBundleId")
	@State private var _autoPPQProtection: Bool = UserDefaults.standard.bool(forKey: "ksign.autoPPQProtection")
	
	// Custom values
	@State private var _customIcon: UIImage?
	@State private var _customNameSuffix: String = UserDefaults.standard.string(forKey: "ksign.customNameSuffix") ?? ""
	@State private var _customBundleIdSuffix: String = UserDefaults.standard.string(forKey: "ksign.customBundleIdSuffix") ?? ""
	
	// Photo picker
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	
	var body: some View {
		NBNavigationView(.localized("Auto-Sign Settings"), displayMode: .inline) {
			Form {
				// Enable/Disable Section
				Section {
					Toggle(isOn: $_autoSignEnabled) {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Enable Auto-Sign"))
									.fontWeight(.semibold)
								Text(.localized("Automatically apply these settings when signing any app"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
						} icon: {
							Image(systemName: "wand.and.stars")
								.foregroundColor(.purple)
						}
					}
					.onChange(of: _autoSignEnabled) { newValue in
						UserDefaults.standard.set(newValue, forKey: "ksign.autoSignEnabled")
					}
				} header: {
					Text(.localized("Auto-Sign"))
				} footer: {
					Text(.localized("When enabled, these settings will be applied automatically to every app you sign."))
				}
				
				if _autoSignEnabled {
					// Icon Section
					Section {
						Toggle(isOn: $_autoChangeIcon) {
							Label {
								Text(.localized("Auto Change Icon"))
							} icon: {
								Image(systemName: "photo.on.rectangle")
									.foregroundColor(.orange)
							}
						}
						.onChange(of: _autoChangeIcon) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoChangeIcon")
						}
						
						if _autoChangeIcon {
							HStack {
								Text(.localized("Custom Icon"))
								Spacer()
								Menu {
									Button(.localized("Choose from Files")) { _isFilePickerPresenting = true }
									Button(.localized("Choose from Photos")) { _isImagePickerPresenting = true }
									if _customIcon != nil {
										Divider()
										Button(.localized("Remove"), role: .destructive) { _customIcon = nil }
									}
								} label: {
									if let icon = _customIcon {
										Image(uiImage: icon)
											.resizable()
											.aspectRatio(contentMode: .fill)
											.frame(width: 44, height: 44)
											.clipShape(RoundedRectangle(cornerRadius: 10))
									} else {
										Label(.localized("Select"), systemImage: "photo.badge.plus")
									}
								}
							}
						}
					} header: {
						Text(.localized("Icon"))
					}
					
					// Name & Bundle ID Section
					Section {
						Toggle(isOn: $_autoChangeName) {
							Label {
								Text(.localized("Auto Modify Name"))
							} icon: {
								Image(systemName: "textformat")
									.foregroundColor(.blue)
							}
						}
						.onChange(of: _autoChangeName) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoChangeName")
						}
						
						if _autoChangeName {
							HStack {
								Text(.localized("Name Suffix"))
								Spacer()
								TextField(.localized("e.g. (Signed)"), text: $_customNameSuffix)
									.textFieldStyle(.roundedBorder)
									.frame(maxWidth: 150)
									.multilineTextAlignment(.trailing)
									.onChange(of: _customNameSuffix) { newValue in
										UserDefaults.standard.set(newValue, forKey: "ksign.customNameSuffix")
									}
							}
						}
						
						Toggle(isOn: $_autoChangeBundleId) {
							Label {
								Text(.localized("Auto Modify Bundle ID"))
							} icon: {
								Image(systemName: "rectangle.and.text.magnifyingglass")
									.foregroundColor(.green)
							}
						}
						.onChange(of: _autoChangeBundleId) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoChangeBundleId")
						}
						
						if _autoChangeBundleId {
							HStack {
								Text(.localized("Bundle ID Suffix"))
								Spacer()
								TextField(.localized("e.g. .signed"), text: $_customBundleIdSuffix)
									.textFieldStyle(.roundedBorder)
									.frame(maxWidth: 150)
									.multilineTextAlignment(.trailing)
									.onChange(of: _customBundleIdSuffix) { newValue in
										UserDefaults.standard.set(newValue, forKey: "ksign.customBundleIdSuffix")
									}
							}
						}
					} header: {
						Text(.localized("Name & Bundle ID"))
					}
					
					// Tweaks Section
					Section {
						Toggle(isOn: $_autoInjectTweaks) {
							Label {
								VStack(alignment: .leading, spacing: 2) {
									Text(.localized("Auto Inject Saved Tweaks"))
									Text(.localized("Automatically inject tweaks from your library"))
										.font(.caption)
										.foregroundColor(.secondary)
								}
							} icon: {
								Image(systemName: "puzzlepiece.extension.fill")
									.foregroundColor(.purple)
							}
						}
						.onChange(of: _autoInjectTweaks) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoInjectTweaks")
						}
						
						if _autoInjectTweaks {
							NavigationLink {
								SigningTweaksView(options: $_autoSignOptions)
							} label: {
								Label {
									Text(.localized("Configure Tweaks"))
								} icon: {
									Image(systemName: "gear")
										.foregroundColor(.secondary)
								}
							}
						}
					} header: {
						Text(.localized("Tweaks & Mods"))
					}
					
					// Security Section
					Section {
						Toggle(isOn: $_autoPPQProtection) {
							Label {
								VStack(alignment: .leading, spacing: 2) {
									Text(.localized("PPQ Protection"))
									Text(.localized("Automatically enable PPQ protection"))
										.font(.caption)
										.foregroundColor(.secondary)
								}
							} icon: {
								Image(systemName: "shield.fill")
									.foregroundColor(.green)
							}
						}
						.onChange(of: _autoPPQProtection) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoPPQProtection")
						}
					} header: {
						Text(.localized("Security"))
					}
					
					// All Properties
					Section {
						NavigationLink {
							Form { 
								SigningOptionsView(
									options: $_autoSignOptions,
									temporaryOptions: _optionsManager.options
								)
							}
							.navigationTitle(.localized("All Auto-Sign Properties"))
						} label: {
							Label {
								VStack(alignment: .leading, spacing: 2) {
									Text(.localized("All Auto-Sign Options"))
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
					} header: {
						Text(.localized("Advanced"))
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
					_resetToDefaults()
				}
			}
			.sheet(isPresented: $_isFilePickerPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.image],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._customIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
					}
				)
			}
			.photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
			.onChange(of: _selectedPhoto) { newValue in
				guard let newValue else { return }
				
				Task {
					if let data = try? await newValue.loadTransferable(type: Data.self),
					   let image = UIImage(data: data)?.resizeToSquare() {
						_customIcon = image
					}
				}
			}
		}
	}
	
	private func _resetToDefaults() {
		_autoSignEnabled = false
		_autoInjectTweaks = false
		_autoChangeIcon = false
		_autoChangeName = false
		_autoChangeBundleId = false
		_autoPPQProtection = false
		_customNameSuffix = ""
		_customBundleIdSuffix = ""
		_customIcon = nil
		
		UserDefaults.standard.set(false, forKey: "ksign.autoSignEnabled")
		UserDefaults.standard.set(false, forKey: "ksign.autoInjectTweaks")
		UserDefaults.standard.set(false, forKey: "ksign.autoChangeIcon")
		UserDefaults.standard.set(false, forKey: "ksign.autoChangeName")
		UserDefaults.standard.set(false, forKey: "ksign.autoChangeBundleId")
		UserDefaults.standard.set(false, forKey: "ksign.autoPPQProtection")
		UserDefaults.standard.set("", forKey: "ksign.customNameSuffix")
		UserDefaults.standard.set("", forKey: "ksign.customBundleIdSuffix")
	}
}

// MARK: - Auto-Sign Manager (to be called from SigningView)
class AutoSignManager {
	static let shared = AutoSignManager()
	
	var isEnabled: Bool {
		UserDefaults.standard.bool(forKey: "ksign.autoSignEnabled")
	}
	
	var shouldInjectTweaks: Bool {
		isEnabled && UserDefaults.standard.bool(forKey: "ksign.autoInjectTweaks")
	}
	
	var shouldChangeIcon: Bool {
		isEnabled && UserDefaults.standard.bool(forKey: "ksign.autoChangeIcon")
	}
	
	var shouldChangeName: Bool {
		isEnabled && UserDefaults.standard.bool(forKey: "ksign.autoChangeName")
	}
	
	var nameSuffix: String {
		UserDefaults.standard.string(forKey: "ksign.customNameSuffix") ?? ""
	}
	
	var shouldChangeBundleId: Bool {
		isEnabled && UserDefaults.standard.bool(forKey: "ksign.autoChangeBundleId")
	}
	
	var bundleIdSuffix: String {
		UserDefaults.standard.string(forKey: "ksign.customBundleIdSuffix") ?? ""
	}
	
	var shouldEnablePPQ: Bool {
		isEnabled && UserDefaults.standard.bool(forKey: "ksign.autoPPQProtection")
	}
	
	/// Apply auto-sign settings to options
	func applyAutoSignSettings(to options: inout Options, for app: AppInfoPresentable) {
		guard isEnabled else { return }
		
		if shouldChangeName, let currentName = app.name {
			options.appName = currentName + nameSuffix
		}
		
		if shouldChangeBundleId, let currentId = app.identifier {
			options.appIdentifier = currentId + bundleIdSuffix
		}
		
		if shouldEnablePPQ {
			options.ppqProtection = true
		}
	}
	
	/// Get the currently selected certificate from the database
	func getSelectedCertificate() -> CertificatePair? {
		let certIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		
		let request: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
		
		guard let certificates = try? Storage.shared.context.fetch(request),
			  certificates.indices.contains(certIndex) else {
			return nil
		}
		
		return certificates[certIndex]
	}
	
	/// Perform auto-sign for a newly imported app
	/// - Parameters:
	///   - uuid: The UUID of the newly imported app
	///   - completion: Callback with optional error
	func performAutoSign(forAppWithUUID uuid: String, completion: @escaping (Error?) -> Void) {
		guard isEnabled else {
			completion(nil)
			return
		}
		
		// Find the imported app by UUID
		let request: NSFetchRequest<Imported> = Imported.fetchRequest()
		request.predicate = NSPredicate(format: "uuid == %@", uuid)
		request.fetchLimit = 1
		
		guard let importedApp = try? Storage.shared.context.fetch(request).first else {
			print("[AutoSign] Could not find imported app with UUID: \(uuid)")
			completion(nil)
			return
		}
		
		// Get selected certificate
		guard let certificate = getSelectedCertificate() else {
			print("[AutoSign] No certificate selected, skipping auto-sign")
			completion(nil)
			return
		}
		
		print("[AutoSign] Auto-signing app: \(importedApp.name ?? "Unknown") with certificate: \(certificate.nickname ?? "Unknown")")
		
		// Create options and apply auto-sign settings
		var options = OptionsManager.shared.options
		applyAutoSignSettings(to: &options, for: importedApp)
		
		// Trigger signing
		FR.signPackageFile(
			importedApp,
			using: options,
			icon: nil, // TODO: Support auto-icon from saved icon
			certificate: certificate
		) { error in
			if let error = error {
				print("[AutoSign] Error: \(error.localizedDescription)")
			} else {
				print("[AutoSign] Successfully auto-signed: \(importedApp.name ?? "Unknown")")
				// Send notification for UI update
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: NSNotification.Name("ksign.autoSignCompleted"), object: nil)
				}
			}
			completion(error)
		}
	}
}
