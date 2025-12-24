//
//  AppInfoView.swift
//  SwiftSigner Pro
//
//  Comprehensive App Info View with all app details
//

import SwiftUI
import NimbleViews

// MARK: - View
struct AppInfoView: View {
	@Environment(\.dismiss) var dismiss
	
	let app: AppInfoPresentable
	
	// Extraction state
	@State private var _isExtracting = false
	@State private var _extractionProgress: Double = 0
	@State private var _extractedFolderURL: URL?
	@State private var _showShareSheet = false
	
	// Certificate info for signed apps
	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	var certificate: CertificatePair? {
		Storage.shared.getCertificate(from: app)
	}
	
	var categoryInfo: AppCategory? {
		Storage.shared.getCategory(for: app)
	}
	
	// MARK: Body
	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 20) {
					// Header with App Icon
					_headerSection()
					
					// App Information Card
					_appInfoCard()
					
					// Certificate/Signing Info Card (if signed)
					if app.isSigned {
						_signingInfoCard()
					}
					
					// Category Card (if assigned)
					if let category = categoryInfo {
						_categoryCard(category)
					}
					
					// Actions Section
					_actionsSection()
				}
				.padding(.horizontal)
				.padding(.top, 8)
				.padding(.bottom, 24)
			}
			.background(Color(.systemGroupedBackground))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(.localized("Done")) {
						dismiss()
					}
					.fontWeight(.semibold)
				}
			}
		}
	}
}

// MARK: - View Components
extension AppInfoView {
	
	// MARK: Header Section
	@ViewBuilder
	private func _headerSection() -> some View {
		VStack(spacing: 16) {
			// App Icon with rainbow border
			ZStack {
				// Rainbow gradient border
				RoundedRectangle(cornerRadius: 24)
					.stroke(
						AngularGradient(
							gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
							center: .center
						),
						lineWidth: 4
					)
					.frame(width: 110, height: 110)
				
				FRAppIconView(app: app, size: 90)
					.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
			}
			
			// App Name with gradient
			Text(app.name ?? .localized("Unknown App"))
				.font(.title)
				.fontWeight(.bold)
				.foregroundStyle(
					LinearGradient(
						colors: [.primary, .primary.opacity(0.7)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
			
			// Version & Bundle ID
			VStack(spacing: 4) {
				Text(app.version ?? "Unknown")
					.font(.subheadline)
					.foregroundColor(.secondary)
				Text(app.identifier ?? "Unknown")
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}
			
			// Status pill
			if app.isSigned {
				HStack(spacing: 6) {
					Image(systemName: "checkmark.seal.fill")
						.font(.system(size: 12))
					Text(.localized("Signed"))
						.font(.caption)
						.fontWeight(.semibold)
					if let certInfo = certInfo {
						Text("• \(certInfo.formatted)")
							.font(.caption)
					}
				}
				.foregroundColor(.white)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(certInfo?.color ?? .green)
				.clipShape(Capsule())
			} else {
				HStack(spacing: 6) {
					Image(systemName: "xmark.seal")
						.font(.system(size: 12))
					Text(.localized("Not Signed"))
						.font(.caption)
						.fontWeight(.semibold)
				}
				.foregroundColor(.white)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(Color.gray)
				.clipShape(Capsule())
			}
		}
		.padding(.top, 12)
	}
	
	// MARK: App Info Card
	@ViewBuilder
	private func _appInfoCard() -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			HStack(spacing: 10) {
				Image(systemName: "info.circle.fill")
					.font(.title3)
					.foregroundColor(.blue)
				Text(.localized("App Information"))
					.font(.headline)
					.fontWeight(.semibold)
				
				Spacer()
				
				// Copy all info button
				Button {
					_copyAllInfo()
				} label: {
					Image(systemName: "doc.on.doc")
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			
			Divider()
				.padding(.leading, 16)
			
			// App Name
			_infoRowWithCopy(label: .localized("Name:"), value: app.name ?? .localized("Unknown"))
			
			Divider()
				.padding(.leading, 16)
			
			// Bundle ID
			_infoRowWithCopy(label: .localized("Bundle ID:"), value: app.identifier ?? .localized("Unknown"))
			
			Divider()
				.padding(.leading, 16)
			
			// Version
			_infoRowWithCopy(label: .localized("Version:"), value: app.version ?? .localized("Unknown"))
			
			Divider()
				.padding(.leading, 16)
			
			// Size
			_infoRowWithCopy(label: .localized("Size:"), value: _formattedSize)
			
			Divider()
				.padding(.leading, 16)
			
			// Type
			_infoRowWithCopy(label: .localized("Type:"), value: app.type?.rawValue.capitalized ?? .localized("Unknown"))
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
		.contextMenu {
			// Copy all info
			Button {
				_copyAllInfo()
			} label: {
				Label(.localized("Copy All Info"), systemImage: "doc.on.doc.fill")
			}
			
			Divider()
			
			// Individual copy options
			if let name = app.name {
				Button {
					UIPasteboard.general.string = name
					UINotificationFeedbackGenerator().notificationOccurred(.success)
				} label: {
					Label(.localized("Copy Name"), systemImage: "textformat")
				}
			}
			
			if let identifier = app.identifier {
				Button {
					UIPasteboard.general.string = identifier
					UINotificationFeedbackGenerator().notificationOccurred(.success)
				} label: {
					Label(.localized("Copy Bundle ID"), systemImage: "shippingbox")
				}
			}
			
			if let version = app.version {
				Button {
					UIPasteboard.general.string = version
					UINotificationFeedbackGenerator().notificationOccurred(.success)
				} label: {
					Label(.localized("Copy Version"), systemImage: "number")
				}
			}
		}
	}
	
	// Copy all app info to clipboard
	private func _copyAllInfo() {
		var info = ""
		info += "Name: \(app.name ?? "Unknown")\n"
		info += "Bundle ID: \(app.identifier ?? "Unknown")\n"
		info += "Version: \(app.version ?? "Unknown")\n"
		info += "Size: \(_formattedSize)\n"
		info += "Type: \(app.type?.rawValue.capitalized ?? "Unknown")\n"
		info += "Signed: \(app.isSigned ? "Yes" : "No")"
		
		if app.isSigned, let cert = certificate {
			info += "\nCertificate: \(cert.nickname ?? "Unknown")"
			if let decoded = Storage.shared.getProvisionFileDecoded(for: cert) {
				info += "\nTeam: \(decoded.TeamName ?? "Unknown")"
				info += "\nExpires: \(decoded.ExpirationDate.formatted(date: .abbreviated, time: .omitted))"
			}
		}
		
		UIPasteboard.general.string = info
		UINotificationFeedbackGenerator().notificationOccurred(.success)
	}
	
	// MARK: Signing Info Card
	@ViewBuilder
	private func _signingInfoCard() -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			HStack(spacing: 10) {
				Image(systemName: "signature")
					.font(.title3)
					.foregroundColor(.green)
				Text(.localized("Signing Information"))
					.font(.headline)
					.fontWeight(.semibold)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			
			Divider()
				.padding(.leading, 16)
			
			// Status
			_infoRow(label: .localized("Status:"), value: .localized("Signed"))
			
			// Certificate Info
			if let cert = certificate {
				Divider()
					.padding(.leading, 16)
				
				_infoRow(label: .localized("Certificate:"), value: cert.nickname ?? Storage.shared.getProvisionFileDecoded(for: cert)?.Name ?? .localized("Unknown"))
				
				if let decoded = Storage.shared.getProvisionFileDecoded(for: cert) {
					Divider()
						.padding(.leading, 16)
					
					_infoRow(label: .localized("Team:"), value: decoded.TeamName ?? .localized("Unknown"))
					
					Divider()
						.padding(.leading, 16)
					
					let expDate = decoded.ExpirationDate
					_infoRow(label: .localized("Expires:"), value: expDate.formatted(date: .abbreviated, time: .omitted))
					
					Divider()
						.padding(.leading, 16)
					
					// Days remaining
					let days = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
					_infoRow(label: .localized("Days Left:"), value: "\(max(0, days))")
				}
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: Category Card
	@ViewBuilder
	private func _categoryCard(_ category: AppCategory) -> some View {
		let categoryColor = Color(category.color ?? "blue")
		
		VStack(alignment: .leading, spacing: 0) {
			HStack(spacing: 10) {
				Image(systemName: category.icon ?? "folder.fill")
					.font(.title3)
					.foregroundColor(categoryColor)
				VStack(alignment: .leading) {
					Text(.localized("Category"))
						.font(.headline)
						.fontWeight(.semibold)
					Text(category.name ?? "Folder")
						.font(.subheadline)
						.foregroundColor(categoryColor)
				}
				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: Actions Section
	@ViewBuilder
	private func _actionsSection() -> some View {
		VStack(spacing: 12) {
			// Share button
			Button {
				// Share action
				if let url = app.uuid {
					UIActivityViewController.show(activityItems: [url])
				}
			} label: {
				HStack {
					Image(systemName: "square.and.arrow.up")
					Text(.localized("Share"))
				}
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(Color.blue)
				.cornerRadius(12)
			}
			
			// Extract Source button
			Button {
				_extractSource()
			} label: {
				HStack {
					if _isExtracting {
						ProgressView()
							.progressViewStyle(CircularProgressViewStyle(tint: .white))
							.scaleEffect(0.8)
					} else {
						Image(systemName: "doc.zipper")
					}
					Text(_isExtracting ? .localized("Extracting...") : .localized("Extract Source"))
				}
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(Color.orange)
				.cornerRadius(12)
			}
			.disabled(_isExtracting)
			
			// Delete button
			Button(role: .destructive) {
				Storage.shared.deleteApp(for: app)
				dismiss()
			} label: {
				HStack {
					Image(systemName: "trash")
					Text(.localized("Delete App"))
				}
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(Color.red)
				.cornerRadius(12)
			}
		}
		.sheet(isPresented: $_showShareSheet) {
			if let url = _extractedFolderURL {
				ShareSheet(activityItems: [url])
			}
		}
	}
	
	// MARK: Extract Source Logic
	private func _extractSource() {
		guard let appDir = Storage.shared.getAppDirectory(for: app) else { return }
		
		_isExtracting = true
		
		Task.detached(priority: .userInitiated) {
			do {
				let fileManager = FileManager.default
				let tempDir = fileManager.temporaryDirectory.appendingPathComponent("extract_\(UUID().uuidString)")
				try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
				
				// The appDir IS the .app bundle
				let appBundlePath = appDir
				
				// Create Payload folder structure
				let payloadDir = tempDir.appendingPathComponent("Payload")
				try fileManager.createDirectory(at: payloadDir, withIntermediateDirectories: true)
				
				// Copy app bundle to Payload
				let destAppPath = payloadDir.appendingPathComponent(appBundlePath.lastPathComponent)
				try fileManager.copyItem(at: appBundlePath, to: destAppPath)
				
				// Create the extracted folder name
				let appName = app.name ?? "App"
				let extractedFolder = tempDir.appendingPathComponent("\(appName)_Source")
				try fileManager.createDirectory(at: extractedFolder, withIntermediateDirectories: true)
				
				// Copy all contents for user to explore
				let itemsToCopy = try fileManager.contentsOfDirectory(at: destAppPath, includingPropertiesForKeys: nil)
				for item in itemsToCopy {
					let dest = extractedFolder.appendingPathComponent(item.lastPathComponent)
					try? fileManager.copyItem(at: item, to: dest)
				}
				
				await MainActor.run {
					_isExtracting = false
					_extractedFolderURL = extractedFolder
					_showShareSheet = true
				}
			} catch {
				await MainActor.run {
					_isExtracting = false
					UIAlertController.showAlertWithOk(
						title: .localized("Extraction Failed"),
						message: error.localizedDescription
					)
				}
			}
		}
	}
	
	// MARK: Helper View
	@ViewBuilder
	private func _infoRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.frame(width: 90, alignment: .leading)
			
			Text(value)
				.font(.subheadline)
				.fontWeight(.medium)
				.lineLimit(1)
				.minimumScaleFactor(0.7)
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}
	
	@ViewBuilder
	private func _infoRowWithCopy(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.frame(width: 90, alignment: .leading)
			
			Text(value)
				.font(.subheadline)
				.fontWeight(.medium)
				.lineLimit(1)
				.minimumScaleFactor(0.7)
			
			Spacer()
			
			// Copy button
			Button {
				UIPasteboard.general.string = value
				UINotificationFeedbackGenerator().notificationOccurred(.success)
			} label: {
				Image(systemName: "doc.on.doc")
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.contentShape(Rectangle())
		.contextMenu {
			Button {
				UIPasteboard.general.string = value
				UINotificationFeedbackGenerator().notificationOccurred(.success)
			} label: {
				Label(.localized("Copy"), systemImage: "doc.on.doc")
			}
		}
	}
	
	// MARK: Computed Properties
	private var _formattedSize: String {
		if let size = app.size {
			return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
		}
		return .localized("Unknown")
	}
}
