//
//  CertificatesAddView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import Zip

// MARK: - View
struct CertificatesAddView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var _p12URL: URL? = nil
	@State private var _provisionURL: URL? = nil
	@State private var _p12Password: String = ""
	@State private var _certificateName: String = ""
	
	@State private var _p12Data: Data? = nil
	@State private var _provisionData: Data? = nil
	@State private var _isFromKsign: Bool = false
	
	@State private var _isImportingP12Presenting = false
	@State private var _isImportingMobileProvisionPresenting = false
	@State private var _isImportingZipPresenting = false
	@State private var _isPasswordAlertPresenting = false
	@State private var _isKravasignAlertPresenting = false
	@State private var _errorMessage: String = ""
	@State private var _isErrorPresenting = false
	@State private var _isExtracting = false
	@State private var _extractionProgress: Double = 0
	
	// Expiration validation
	@State private var _expirationDate: Date? = nil
	@State private var _isExpirationWarningPresenting = false
	@State private var _expirationWarningMessage: String = ""
	@State private var _isExpired: Bool = false
	
	var saveButtonDisabled: Bool {
		if _isFromKsign {
			return _p12Data == nil || _provisionData == nil
		} else {
			return _p12URL == nil || _provisionURL == nil
		}
	}
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("New Certificate"), displayMode: .inline) {
			Form {
				// ZIP Import Section
				NBSection(.localized("Quick Import")) {
					Button {
						_isImportingZipPresenting = true
					} label: {
						HStack(spacing: 14) {
							ZStack {
								RoundedRectangle(cornerRadius: 10)
									.fill(Color.accentColor.opacity(0.15))
									.frame(width: 44, height: 44)
								Image(systemName: "doc.zipper")
									.font(.title2)
									.foregroundColor(.accentColor)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Import via ZIP"))
									.font(.subheadline)
									.fontWeight(.semibold)
									.foregroundColor(.primary)
								Text(.localized("Auto-extract .p12 & .mobileprovision"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							if _isExtracting {
								ProgressView()
									.scaleEffect(0.8)
							} else {
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundColor(.secondary)
							}
						}
					}
					.disabled(_isExtracting)
				}
				
				// Extraction Progress
				if _isExtracting {
					Section {
						VStack(spacing: 8) {
							ProgressView(value: _extractionProgress)
								.tint(.accentColor)
							Text(.localized("Extracting certificate files..."))
								.font(.caption)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 4)
					}
				}
				
				NBSection(.localized("Manual Import")) {
					// P12 Import Button
					Button {
						_isImportingP12Presenting = true
					} label: {
						HStack(spacing: 14) {
							ZStack {
								RoundedRectangle(cornerRadius: 10)
									.fill(Color.orange.opacity(0.15))
									.frame(width: 44, height: 44)
								Image(systemName: "key.fill")
									.font(.title2)
									.foregroundColor(.orange)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Certificate File"))
									.font(.subheadline)
									.fontWeight(.medium)
									.foregroundColor(.primary)
								Text(".p12")
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							if _p12URL != nil || _p12Data != nil {
								Image(systemName: "checkmark.circle.fill")
									.foregroundColor(.green)
									.font(.title3)
							} else {
								Image(systemName: "plus.circle")
									.foregroundColor(.accentColor)
									.font(.title3)
							}
						}
					}
					
					// Mobileprovision Import Button
					Button {
						_isImportingMobileProvisionPresenting = true
					} label: {
						HStack(spacing: 14) {
							ZStack {
								RoundedRectangle(cornerRadius: 10)
									.fill(Color.accentColor.opacity(0.15))
									.frame(width: 44, height: 44)
								Image(systemName: "doc.badge.gearshape.fill")
									.font(.title2)
									.foregroundColor(.purple)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Provisioning Profile"))
									.font(.subheadline)
									.fontWeight(.medium)
									.foregroundColor(.primary)
								Text(".mobileprovision")
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							if _provisionURL != nil || _provisionData != nil {
								Image(systemName: "checkmark.circle.fill")
									.foregroundColor(.green)
									.font(.title3)
							} else {
								Image(systemName: "plus.circle")
									.foregroundColor(.accentColor)
									.font(.title3)
							}
						}
					}
				}
				
				// Status indicators with expiration info
				if _p12URL != nil || _provisionURL != nil {
					Section {
						if let p12 = _p12URL {
							HStack {
								Image(systemName: "key.fill")
									.foregroundColor(.orange)
									.frame(width: 20)
								Text(p12.lastPathComponent)
									.font(.caption)
									.foregroundColor(.primary)
									.lineLimit(1)
								Spacer()
								Button {
									_p12URL = nil
								} label: {
									Image(systemName: "xmark.circle.fill")
										.foregroundColor(.secondary)
								}
							}
						}
						if let provision = _provisionURL {
							VStack(alignment: .leading, spacing: 6) {
								HStack {
									Image(systemName: "doc.badge.gearshape.fill")
										.foregroundColor(.purple)
										.frame(width: 20)
									Text(provision.lastPathComponent)
										.font(.caption)
										.foregroundColor(.primary)
										.lineLimit(1)
									Spacer()
									Button {
										_provisionURL = nil
										_expirationDate = nil
									} label: {
										Image(systemName: "xmark.circle.fill")
											.foregroundColor(.secondary)
									}
								}
								
								// Show expiration date
								if let expDate = _expirationDate {
									HStack(spacing: 6) {
										Image(systemName: _isExpired ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
											.font(.caption)
											.foregroundColor(_isExpired ? .red : (expDate.timeIntervalSinceNow < 604800 ? .orange : .green))
										
										Text(_isExpired ? .localized("Expired: ") : .localized("Expires: "))
											.font(.caption2)
											.foregroundColor(.secondary)
										
										Text(expDate, style: .date)
											.font(.caption2)
											.fontWeight(.medium)
											.foregroundColor(_isExpired ? .red : (expDate.timeIntervalSinceNow < 604800 ? .orange : .green))
									}
									.padding(.leading, 26)
								}
							}
						}
					} header: {
						Text(.localized("Selected Files"))
					}
				}
				
				NBSection(.localized("Password")) {
					HStack(spacing: 14) {
						ZStack {
							RoundedRectangle(cornerRadius: 10)
								.fill(Color.gray.opacity(0.15))
								.frame(width: 44, height: 44)
							Image(systemName: "lock.fill")
								.font(.title2)
								.foregroundColor(.gray)
						}
						
						SecureField(.localized("Enter Password"), text: $_p12Password)
					}
				} footer: {
					Text(.localized("Enter the password associated with the private key. Leave it blank if theres no password required."))
				}
				
				Section {
					HStack(spacing: 14) {
						ZStack {
							RoundedRectangle(cornerRadius: 10)
								.fill(Color.green.opacity(0.15))
								.frame(width: 44, height: 44)
							Image(systemName: "tag.fill")
								.font(.title2)
								.foregroundColor(.green)
						}
						
						TextField(.localized("Nickname (Optional)"), text: $_certificateName)
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				NBToolbarButton(
					.localized("Save"),
					style: .text,
					placement: .confirmationAction,
					isDisabled: saveButtonDisabled || _isExtracting
				) {
					_validateAndSave()
				}
			}
			.sheet(isPresented: $_isImportingP12Presenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [UTType.p12],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._p12URL = selectedFileURL
						self._isFromKsign = false
					}
				)
			}
			.sheet(isPresented: $_isImportingMobileProvisionPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [UTType.mobileProvision],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._provisionURL = selectedFileURL
						self._isFromKsign = false
						_validateProvisionExpiration(selectedFileURL)
					}
				)
			}
			.sheet(isPresented: $_isImportingZipPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [UTType.zip, UTType.archive],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						_extractCertificatesFromZip(selectedFileURL)
					}
				)
			}
			.alert(isPresented: $_isPasswordAlertPresenting) {
				Alert(
					title: Text(.localized("Bad Password")),
					message: Text(.localized("Please check the password and try again.")),
					dismissButton: .default(Text(.localized("OK")))
				)
			}
			.alert(isPresented: $_isErrorPresenting) {
				Alert(
					title: Text(.localized("Import Error")),
					message: Text(_errorMessage),
					dismissButton: .default(Text(.localized("OK")))
				)
			}
			.alert(isPresented: $_isKravasignAlertPresenting) {
				Alert(
					title: Text("Not a Kravasign Cert"),
					message: Text("Oh! Looks like you're not using a Krava Cert. This is a 3rd party Krava signer to help with some features. Please buy a cert here: https://kravasign.com/"),
					dismissButton: .default(Text(.localized("OK")))
				)
			}
			.alert(.localized("Certificate Expiration"), isPresented: $_isExpirationWarningPresenting) {
				Button(.localized("Cancel"), role: .cancel) { }
				Button(_isExpired ? .localized("Import Anyway") : .localized("Continue"), role: _isExpired ? .destructive : nil) {
					_saveCertificate()
				}
			} message: {
				Text(_expirationWarningMessage)
			}
		}
	}
}

// MARK: - Extension: Validation
extension CertificatesAddView {
	private func _validateProvisionExpiration(_ url: URL) {
		// Try to access the security-scoped resource
		guard url.startAccessingSecurityScopedResource() else { return }
		defer { url.stopAccessingSecurityScopedResource() }
		
		if let data = try? Data(contentsOf: url),
		   let cert = CertificateReader.parseData(data) {
			_expirationDate = cert.ExpirationDate
			_isExpired = cert.ExpirationDate < Date()
		}
	}
	
	private func _validateAndSave() {
		// First check if we have an expiration date and if it's concerning
		if let expDate = _expirationDate {
			let daysUntilExpiry = expDate.timeIntervalSinceNow / 86400
			
			if _isExpired {
				_expirationWarningMessage = String.localized("This certificate has EXPIRED on \(expDate.formatted(date: .abbreviated, time: .omitted)). It will not work for signing. Do you want to import it anyway?")
				_isExpirationWarningPresenting = true
				return
			} else if daysUntilExpiry < 7 {
				_expirationWarningMessage = String.localized("This certificate expires in \(Int(daysUntilExpiry)) days (\(expDate.formatted(date: .abbreviated, time: .omitted))). Do you want to continue?")
				_isExpirationWarningPresenting = true
				return
			} else if daysUntilExpiry < 30 {
				_expirationWarningMessage = String.localized("This certificate expires in \(Int(daysUntilExpiry)) days. It's still valid but you may want to renew it soon. Continue?")
				_isExpirationWarningPresenting = true
				return
			}
		}
		
		_saveCertificate()
	}
}

// MARK: - Extension: ZIP Extraction
extension CertificatesAddView {
	private func _extractCertificatesFromZip(_ zipURL: URL) {
		_isExtracting = true
		_extractionProgress = 0
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				// Create temp directory for extraction
				let tempDir = FileManager.default.temporaryDirectory
					.appendingPathComponent("cert_extract_\(UUID().uuidString)")
				try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
				
				DispatchQueue.main.async {
					_extractionProgress = 0.2
				}
				
				// Start accessing the security-scoped resource
				guard zipURL.startAccessingSecurityScopedResource() else {
					throw NSError(domain: "CertImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access the selected file"])
				}
				defer { zipURL.stopAccessingSecurityScopedResource() }
				
				// Copy ZIP to temp location first
				let tempZipPath = tempDir.appendingPathComponent("cert.zip")
				try FileManager.default.copyItem(at: zipURL, to: tempZipPath)
				
				DispatchQueue.main.async {
					_extractionProgress = 0.4
				}
				
				// Extract ZIP
				Zip.addCustomFileExtension("zip")
				try Zip.unzipFile(tempZipPath, destination: tempDir, overwrite: true, password: nil)
				
				DispatchQueue.main.async {
					_extractionProgress = 0.7
				}
				
				// Find .p12, .mobileprovision, and password.txt files recursively
				var foundP12: URL? = nil
				var foundProvision: URL? = nil
				var foundPassword: String? = nil
				
				let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil)
				while let fileURL = enumerator?.nextObject() as? URL {
					let ext = fileURL.pathExtension.lowercased()
					let fileName = fileURL.lastPathComponent.lowercased()
					
					if ext == "p12" && foundP12 == nil {
						foundP12 = fileURL
					} else if ext == "mobileprovision" && foundProvision == nil {
						foundProvision = fileURL
					} else if fileName == "password.txt" && foundPassword == nil {
						// Read password from password.txt
						if let passwordData = try? String(contentsOf: fileURL, encoding: .utf8) {
							let password = passwordData.trimmingCharacters(in: .whitespacesAndNewlines)
							// Only auto-fill if password is "kravasign"
							if password.lowercased() == "kravasign" {
								foundPassword = password
							}
						}
					}
				}
				
				DispatchQueue.main.async {
					_extractionProgress = 0.9
				}
				
				// Copy files to a persistent temp location
				let persistentDir = FileManager.default.temporaryDirectory
					.appendingPathComponent("cert_files_\(UUID().uuidString)")
				try FileManager.default.createDirectory(at: persistentDir, withIntermediateDirectories: true)
				
				var finalP12: URL? = nil
				var finalProvision: URL? = nil
				
				if let p12 = foundP12 {
					let destP12 = persistentDir.appendingPathComponent(p12.lastPathComponent)
					try FileManager.default.copyItem(at: p12, to: destP12)
					finalP12 = destP12
				}
				
				if let provision = foundProvision {
					let destProvision = persistentDir.appendingPathComponent(provision.lastPathComponent)
					try FileManager.default.copyItem(at: provision, to: destProvision)
					finalProvision = destProvision
					
					// Validate expiration from ZIP
					if let data = try? Data(contentsOf: destProvision),
					   let cert = CertificateReader.parseData(data) {
						DispatchQueue.main.async {
							_expirationDate = cert.ExpirationDate
							_isExpired = cert.ExpirationDate < Date()
						}
					}
				}
				
				// Clean up extraction temp dir
				try? FileManager.default.removeItem(at: tempDir)
				
				DispatchQueue.main.async {
					_extractionProgress = 1.0
					_isExtracting = false
					
					if finalP12 == nil && finalProvision == nil {
						_errorMessage = String.localized("No .p12 or .mobileprovision files found in the ZIP archive.")
						_isErrorPresenting = true
					} else {
						if let p12 = finalP12 {
							_p12URL = p12
						}
						if let provision = finalProvision {
							_provisionURL = provision
						}
						_isFromKsign = false
						
						// Auto-fill password if kravasign was found in password.txt
						if let password = foundPassword {
							_p12Password = password
						}
						
						// Show partial success message if one is missing
						if finalP12 == nil {
							_errorMessage = String.localized("Found provisioning file, but no .p12 certificate file in the ZIP.")
							_isErrorPresenting = true
						} else if finalProvision == nil {
							_errorMessage = String.localized("Found .p12 certificate, but no .mobileprovision file in the ZIP.")
							_isErrorPresenting = true
						}
					}
				}
				
			} catch {
				DispatchQueue.main.async {
					_isExtracting = false
					_errorMessage = error.localizedDescription
					_isErrorPresenting = true
				}
			}
		}
	}
}

// MARK: - Extension: Save
extension CertificatesAddView {
	private func _saveCertificate() {
        guard
            let p12URL = _p12URL,
            let provisionURL = _provisionURL
        else {
            _isPasswordAlertPresenting = true
            return
        }
        
        // Validate password with certificate
        guard FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL) else {
            _isPasswordAlertPresenting = true
            return
        }
        
        FR.handleCertificateFiles(
            p12URL: p12URL,
            provisionURL: provisionURL,
            p12Password: _p12Password,
            certificateName: _certificateName
        ) { _ in
            dismiss()
        }
	}
}

