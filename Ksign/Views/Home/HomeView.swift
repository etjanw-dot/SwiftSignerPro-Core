//
//  HomeView.swift
//  Ksign
//
//  Main home tab with device info, sign IPA, and download from URL
//

import SwiftUI
import CoreData
import NimbleViews

struct HomeView: View {
	@StateObject private var downloadManager = DownloadManager.shared
	@StateObject private var udidService = UDIDService.shared
	@State private var ipaURLString: String = ""
	@State private var isImportingPresenting = false
	@State private var showUDIDPromptAlert = false
	
	// Fetch counts from CoreData
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: []
	) private var importedApps: FetchedResults<Imported>
	
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: []
	) private var signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: []
	) private var certificates: FetchedResults<CertificatePair>
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					// App Title
					HStack {
						Text("SwiftSigner Pro")
							.font(.largeTitle)
							.fontWeight(.bold)
						Spacer()
					}
					.padding(.horizontal)
					.padding(.top, 8)
					
					// UDID Card (Prominent display)
					_udidCard
					
					// Device Info Card
					_deviceInfoCard
					
					// Certificate Status Card
					_certificateStatusCard
					
					// Sign IPA File Card
					_signIPACard
					
					// Download IPA from URL Card
					_downloadIPACard
					
					// Stats Cards
					_statsCards
					
					Spacer()
				}
				.padding(.vertical)
			}
			.background(Color(.systemGroupedBackground))
			.navigationBarHidden(true)
			.onAppear {
				// Check if we should prompt for UDID on first launch
				if udidService.shouldPromptForUDID {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
						showUDIDPromptAlert = true
					}
				}
			}
			.alert("Get Your Device UDID", isPresented: $showUDIDPromptAlert) {
				Button("Get UDID Now") {
					udidService.markPromptShown()
					udidService.openUDIDWebsite()
				}
				Button("Later", role: .cancel) {
					udidService.markPromptShown()
				}
			} message: {
				Text("Your real device UDID is needed for signing apps. Would you like to retrieve it now?")
			}
			.onReceive(NotificationCenter.default.publisher(for: .udidDidChange)) { _ in
				// Force UI refresh when UDID changes
			}
		}
	}
	
	// MARK: - UDID Card (Prominent Display)
	private var _udidCard: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				HStack(spacing: 8) {
					Image(systemName: "number.square.fill")
						.font(.title2)
						.foregroundStyle(
							LinearGradient(
								colors: [.blue, .purple],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Device UDID"))
						.font(.headline)
						.fontWeight(.bold)
				}
				
				Spacer()
				
				// Status badge
				HStack(spacing: 4) {
					Image(systemName: udidService.hasVerifiedUDID() ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
						.font(.caption)
					Text(udidService.hasVerifiedUDID() ? .localized("Verified") : .localized("Not Verified"))
						.font(.caption)
						.fontWeight(.medium)
				}
				.foregroundColor(udidService.hasVerifiedUDID() ? .green : .orange)
				.padding(.horizontal, 10)
				.padding(.vertical, 5)
				.background(
					Capsule()
						.fill(udidService.hasVerifiedUDID() ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
				)
			}
			
			// UDID Display
			HStack {
				Text(udidService.getUDID())
					.font(.system(.subheadline, design: .monospaced))
					.foregroundColor(udidService.hasVerifiedUDID() ? .primary : .secondary)
					.lineLimit(1)
					.minimumScaleFactor(0.7)
				
				Spacer()
				
				// Copy button
				Button {
					udidService.copyUDIDToClipboard()
					_showCopiedFeedback()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: _copied ? "checkmark" : "doc.on.clipboard")
							.font(.caption)
						Text(_copied ? .localized("Copied!") : .localized("Copy"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(_copied ? .green : .white)
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(
						Capsule()
							.fill(_copied ? Color.green.opacity(0.2) : Color(.tertiarySystemFill))
					)
				}
				.buttonStyle(.plain)
			}
			.padding(14)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(Color(.tertiarySystemBackground))
			)
			
			// Get Real UDID button - if not verified
			if !udidService.hasVerifiedUDID() {
				Button {
					udidService.openUDIDWebsite()
				} label: {
					HStack(spacing: 8) {
						Image(systemName: "globe")
							.font(.subheadline)
						Text(.localized("Get Real UDID via Web Profile"))
							.font(.subheadline)
							.fontWeight(.semibold)
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
					.cornerRadius(12)
				}
				.buttonStyle(.plain)
				
				// Paste UDID button
				Button {
					_pasteUDIDFromClipboard()
				} label: {
					HStack(spacing: 8) {
						Image(systemName: "doc.on.clipboard.fill")
							.font(.subheadline)
						Text(.localized("Paste UDID from Clipboard"))
							.font(.subheadline)
							.fontWeight(.semibold)
					}
					.foregroundColor(.primary)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 14)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(Color(.tertiarySystemFill))
					)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
				.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
		)
		.padding(.horizontal)
	}
	
	// MARK: - Paste UDID Helper
	private func _pasteUDIDFromClipboard() {
		guard let pastedString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) else {
			UIAlertController.showAlertWithOk(
				title: .localized("No UDID Found"),
				message: .localized("No text found in clipboard. Please copy your UDID from the website first.")
			)
			return
		}
		
		// Validate it looks like a UDID (40 hex characters or UUID format)
		let cleanUDID = pastedString.uppercased()
		let isValidUDID = cleanUDID.count >= 24 && cleanUDID.range(of: "^[A-F0-9\\-]+$", options: .regularExpression) != nil
		
		if isValidUDID {
			udidService.saveUDID(cleanUDID)
			UINotificationFeedbackGenerator().notificationOccurred(.success)
		} else {
			UIAlertController.showAlertWithOk(
				title: .localized("Invalid UDID"),
				message: .localized("The clipboard doesn't contain a valid UDID. Please copy your UDID from the website and try again.")
			)
		}
	}
	

	// MARK: - Device Info Card
	private var _deviceInfoCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text(.localized("Your Device"))
					.font(.headline)
					.fontWeight(.semibold)
				
				Spacer()
				
				// Verification badge
				HStack(spacing: 4) {
					Image(systemName: _isVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
						.font(.caption)
					Text(_isVerified ? .localized("Verified") : .localized("Not Verified"))
						.font(.caption)
						.fontWeight(.medium)
				}
				.foregroundColor(_isVerified ? .green : .orange)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(
					Capsule()
						.fill(_isVerified ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
				)
			}
			
			HStack(spacing: 14) {
				// Device Icon with green background
				ZStack {
					RoundedRectangle(cornerRadius: 12)
						.fill(Color.green.opacity(0.15))
						.frame(width: 50, height: 50)
					Image(systemName: "iphone")
						.font(.title2)
						.foregroundColor(.green)
				}
				
				VStack(alignment: .leading, spacing: 4) {
					// Device name and model
					Text(UIDevice.current.name)
						.font(.subheadline)
						.fontWeight(.semibold)
					
					HStack(spacing: 8) {
						// Model
						HStack(spacing: 4) {
							Image(systemName: "cpu")
								.font(.caption2)
								.foregroundColor(.green)
							Text(_deviceModel)
								.font(.caption)
								.foregroundColor(.secondary)
						}
						
						Text("•")
							.foregroundColor(.secondary)
						
						// iOS Version
						HStack(spacing: 4) {
							Image(systemName: "apple.logo")
								.font(.caption2)
								.foregroundColor(.green)
							Text("iOS \(UIDevice.current.systemVersion)")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Spacer()
			}
			
			Divider()
			
			// UDID Row
			HStack {
				HStack(spacing: 6) {
					Image(systemName: "number.square.fill")
						.font(.caption)
						.foregroundColor(.green)
					Text("UDID:")
						.font(.caption)
						.foregroundColor(.secondary)
				}
				
				Text(_deviceUDID)
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(1)
				
				Spacer()
				
				// Copy button
				Button {
					UIPasteboard.general.string = _deviceUDID
					_showCopiedFeedback()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: _copied ? "checkmark" : "doc.on.clipboard")
							.font(.caption)
						Text(_copied ? .localized("Copied!") : .localized("Copy"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(_copied ? .green : .secondary)
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(
						Capsule()
							.fill(Color(.tertiarySystemFill))
					)
				}
				.buttonStyle(.plain)
			}
			
			// Get Real UDID button - show if no verified UDID
			if !_hasVerifiedUDID {
				Button {
					UDIDService.shared.openUDIDWebsite()
				} label: {
					HStack {
						Image(systemName: "globe")
							.font(.caption)
						Text(.localized("Get Real UDID"))
							.font(.caption)
							.fontWeight(.medium)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.frame(maxWidth: .infinity)
					.background(
						LinearGradient(
							colors: [.blue, .purple],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.cornerRadius(10)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
		.padding(.horizontal)
	}
	
	@State private var _copied = false
	
	private func _showCopiedFeedback() {
		withAnimation(.spring(response: 0.3)) {
			_copied = true
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
			withAnimation {
				_copied = false
			}
		}
	}
	
	private var _isVerified: Bool {
		UserDefaults.standard.string(forKey: "SwiftSignerPro.verifiedUDID") != nil
	}
	
	private var _hasVerifiedUDID: Bool {
		UserDefaults.standard.string(forKey: "SwiftSignerPro.verifiedUDID") != nil
	}
	
	// MARK: - Certificate Status Card
	private var _certificateStatusCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text(.localized("Certificates"))
					.font(.headline)
					.fontWeight(.semibold)
				
				Spacer()
				
				// Certificate count badge
				HStack(spacing: 4) {
					Image(systemName: "signature")
						.font(.caption)
					Text("\(certificates.count)")
						.font(.caption)
						.fontWeight(.medium)
				}
				.foregroundColor(.orange)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(
					Capsule()
						.fill(Color.orange.opacity(0.15))
				)
			}
			
			if certificates.isEmpty {
				// No certificates
				HStack(spacing: 14) {
					ZStack {
						RoundedRectangle(cornerRadius: 12)
							.fill(Color.orange.opacity(0.15))
							.frame(width: 50, height: 50)
						Image(systemName: "exclamationmark.triangle.fill")
							.font(.title2)
							.foregroundColor(.orange)
					}
					
					VStack(alignment: .leading, spacing: 4) {
						Text(.localized("No Certificates"))
							.font(.subheadline)
							.fontWeight(.semibold)
						
						Text(.localized("Add a certificate to start signing apps"))
							.font(.caption)
							.foregroundColor(.secondary)
					}
					
					Spacer()
					
					NavigationLink {
						CertificatesView()
					} label: {
						Text(.localized("Add"))
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundColor(.white)
							.padding(.horizontal, 12)
							.padding(.vertical, 6)
							.background(Color.orange)
							.cornerRadius(8)
					}
				}
			} else {
				// Show first certificate info
				if let firstCert = certificates.first {
					HStack(spacing: 14) {
						ZStack {
							RoundedRectangle(cornerRadius: 12)
								.fill(_certStatusColor(for: firstCert).opacity(0.15))
								.frame(width: 50, height: 50)
							Image(systemName: _certIsValid(firstCert) ? "checkmark.seal.fill" : "xmark.seal.fill")
								.font(.title2)
								.foregroundColor(_certStatusColor(for: firstCert))
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text(firstCert.nickname ?? "Certificate")
								.font(.subheadline)
								.fontWeight(.semibold)
								.lineLimit(1)
							
							HStack(spacing: 8) {
								// Status
								HStack(spacing: 4) {
									Image(systemName: _certIsValid(firstCert) ? "checkmark.circle.fill" : "xmark.circle.fill")
										.font(.caption2)
										.foregroundColor(_certStatusColor(for: firstCert))
									Text(_certIsValid(firstCert) ? .localized("Valid") : .localized("Expired"))
										.font(.caption)
										.foregroundColor(_certStatusColor(for: firstCert))
								}
								
								if let expiration = firstCert.expiration {
									Text("•")
										.foregroundColor(.secondary)
									
									// Expiration date
									HStack(spacing: 4) {
										Image(systemName: "calendar")
											.font(.caption2)
											.foregroundColor(.secondary)
										Text(_formatExpiration(expiration))
											.font(.caption)
											.foregroundColor(.secondary)
									}
								}
							}
						}
						
						Spacer()
					}
					
					// Show more certs indicator
					if certificates.count > 1 {
						Divider()
						
						NavigationLink {
							CertificatesView()
						} label: {
							HStack {
								Text(.localized("+\(certificates.count - 1) more certificate\(certificates.count > 2 ? "s" : "")"))
									.font(.caption)
									.foregroundColor(.secondary)
								
								Spacer()
								
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundColor(.secondary)
							}
						}
					}
				}
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
		.padding(.horizontal)
	}
	
	private func _certIsValid(_ cert: CertificatePair) -> Bool {
		guard let expiration = cert.expiration else { return false }
		return expiration > Date()
	}
	
	private func _certStatusColor(for cert: CertificatePair) -> Color {
		return _certIsValid(cert) ? .green : .red
	}
	
	private func _formatExpiration(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}
	
	private var _deviceUDID: String {
		// Try to get UDID from UDIDManager if available, otherwise show placeholder
		if let udid = UserDefaults.standard.string(forKey: "SwiftSignerPro.verifiedUDID") {
			return udid
		}
		return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
	}
	
	private var _deviceModel: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		return _mapToDeviceName(identifier)
	}
	
	private func _mapToDeviceName(_ identifier: String) -> String {
		switch identifier {
		case "iPhone14,4": return "iPhone 13 mini"
		case "iPhone14,5": return "iPhone 13"
		case "iPhone14,2": return "iPhone 13 Pro"
		case "iPhone14,3": return "iPhone 13 Pro Max"
		case "iPhone14,7": return "iPhone 14"
		case "iPhone14,8": return "iPhone 14 Plus"
		case "iPhone15,2": return "iPhone 14 Pro"
		case "iPhone15,3": return "iPhone 14 Pro Max"
		case "iPhone15,4": return "iPhone 15"
		case "iPhone15,5": return "iPhone 15 Plus"
		case "iPhone16,1": return "iPhone 15 Pro"
		case "iPhone16,2": return "iPhone 15 Pro Max"
		case "iPhone17,1": return "iPhone 16 Pro"
		case "iPhone17,2": return "iPhone 16 Pro Max"
		case "iPhone17,3": return "iPhone 16"
		case "iPhone17,4": return "iPhone 16 Plus"
		case "x86_64", "arm64": return "Simulator"
		default: return identifier
		}
	}
	
	// MARK: - Sign IPA Card
	private var _signIPACard: some View {
		Button {
			isImportingPresenting = true
		} label: {
			VStack(spacing: 12) {
				ZStack {
					Circle()
						.fill(Color(.tertiarySystemFill))
						.frame(width: 48, height: 48)
					Image(systemName: "plus")
						.font(.title2)
						.foregroundColor(.secondary)
				}
				
				Text(.localized("Sign IPA file"))
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundColor(.primary)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 24)
			.background(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
					.foregroundColor(Color(.tertiarySystemFill))
			)
		}
		.buttonStyle(.plain)
		.padding(.horizontal)
		.sheet(isPresented: $isImportingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes: [.ipa, .tipa],
				allowsMultipleSelection: true,
				onDocumentsPicked: { urls in
					guard !urls.isEmpty else { return }
					for ipa in urls {
						let id = "FeatherManualDownload_\(UUID().uuidString)"
						let dl = downloadManager.startArchive(from: ipa, id: id)
						downloadManager.handlePachageFile(url: ipa, dl: dl) { err in
							if let error = err {
								UIAlertController.showAlertWithOk(
									title: "Error",
									message: .localized("Whoops!, something went wrong when extracting the file.")
								)
							}
						}
					}
				}
			)
		}
	}
	
	// MARK: - Download IPA Card
	private var _downloadIPACard: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(.localized("Download IPA from URL"))
				.font(.headline)
				.fontWeight(.semibold)
			
			TextField(.localized("Enter IPA URL"), text: $ipaURLString)
				.textFieldStyle(.plain)
				.padding(12)
				.background(
					RoundedRectangle(cornerRadius: 10)
						.fill(Color(.tertiarySystemFill))
				)
				.autocapitalization(.none)
				.keyboardType(.URL)
			
			HStack {
				Button {
					if let clipboardString = UIPasteboard.general.string {
						ipaURLString = clipboardString
					}
				} label: {
					Text(.localized("Paste"))
						.font(.subheadline)
						.fontWeight(.medium)
						.foregroundColor(.primary)
						.padding(.horizontal, 16)
						.padding(.vertical, 10)
						.background(
							RoundedRectangle(cornerRadius: 10)
								.stroke(Color(.separator), lineWidth: 1)
						)
				}
				.buttonStyle(.plain)
				
				Spacer()
				
				Button {
					guard let url = URL(string: ipaURLString), !ipaURLString.isEmpty else { return }
					_ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
					ipaURLString = ""
				} label: {
					HStack(spacing: 6) {
						Image(systemName: "arrow.down.circle.fill")
							.font(.subheadline)
						Text(.localized("Start Download"))
							.font(.subheadline)
							.fontWeight(.semibold)
					}
					.foregroundColor(.white)
					.padding(.horizontal, 16)
					.padding(.vertical, 10)
					.background(
						Capsule()
							.fill(
								LinearGradient(
									colors: [.blue, .purple],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
					)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
		.padding(.horizontal)
	}
	
	// MARK: - Stats Cards
	private var _statsCards: some View {
		VStack(spacing: 12) {
			HStack(spacing: 12) {
				_statCard(title: .localized("Downloaded"), count: importedApps.count, icon: "arrow.down.circle.fill", color: .blue)
				_statCard(title: .localized("Signed"), count: signedApps.count, icon: "signature", color: .orange)
			}
			
			HStack(spacing: 12) {
				_statCard(title: .localized("Certificates"), count: certificates.count, icon: "person.text.rectangle.fill", color: .green)
				_statCard(title: .localized("Total Apps"), count: importedApps.count + signedApps.count, icon: "square.stack.3d.up.fill", color: .purple)
			}
		}
		.padding(.horizontal)
	}
	
	private func _statCard(title: String, count: Int, icon: String, color: Color) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Image(systemName: icon)
					.font(.title3)
					.foregroundColor(color)
				Spacer()
				Text("\(count)")
					.font(.title)
					.fontWeight(.bold)
			}
			
			Text(title)
				.font(.caption)
				.foregroundColor(.secondary)
		}
		.padding(14)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(Color(.secondarySystemGroupedBackground))
				.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
		)
	}
}

#Preview {
	HomeView()
}
