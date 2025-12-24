//
//  InstallPreviewView.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//  Redesigned to match iOS 26 style
//

import SwiftUI
import NimbleViews

// MARK: - View
struct InstallPreviewView: View {
	@Environment(\.dismiss) var dismiss
	
	// Sharing
	@AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
	
	// Methods
	#if SERVER
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@State private var _isWebviewPresenting = false
	@State private var _isServerRunning = false
	#endif
	
	var app: AppInfoPresentable
	@StateObject var viewModel: InstallerStatusViewModel
	#if SERVER
	@StateObject var installer: ServerInstaller
	#endif
	@State var isSharing: Bool
	@State private var _showCopyConfirmation = false

	init(app: AppInfoPresentable, isSharing: Bool = false) {
		self.app = app
		self.isSharing = isSharing
		let viewModel = InstallerStatusViewModel()
		self._viewModel = StateObject(wrappedValue: viewModel)
		#if SERVER
		self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
		#endif
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
					
					// Device Information Card
					_deviceInfoCard()
					
					// Certificate/Signing Info Card
					_signingInfoCard()
					
					#if SERVER
					// HTTPS Server Section
					_serverSection()
					#endif
					
					// Installation Section
					_installationSection()
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
		#if SERVER
		.sheet(isPresented: $_isWebviewPresenting) {
			SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
		}
		.onReceive(viewModel.$status) { newStatus in
			#if DEBUG
			print(newStatus)
			#endif
			if case .ready = newStatus {
				_isServerRunning = true
				if _serverMethod == 0 {
					UIApplication.shared.open(URL(string: installer.iTunesLink)!)
				} else if _serverMethod == 1 {
					_isWebviewPresenting = true
				}
			}
			
			if case .sendingPayload = newStatus, _serverMethod == 1 {
				_isWebviewPresenting = false
			}
            
            if case .completed = newStatus {
                BackgroundAudioManager.shared.stop()
				_isServerRunning = false
            }
		}
		#endif
		.onAppear {
			BackgroundAudioManager.shared.start()
		}
		.onDisappear {
			BackgroundAudioManager.shared.stop()
		}
	}
}

// MARK: - View Components
extension InstallPreviewView {
	
	// MARK: Header Section
	@ViewBuilder
	private func _headerSection() -> some View {
		VStack(spacing: 12) {
			// App Icon
			FRAppIconView(app: app, size: 80)
				.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
			
			// App Name with Rainbow Gradient
			Text(app.name ?? .localized("Unknown App"))
				.font(.title2)
				.fontWeight(.bold)
				.foregroundStyle(
					LinearGradient(
						colors: [.red, .orange, .yellow, .green, .blue, .purple],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
			
			// Title
			Text(.localized("Install Signed App"))
				.font(.headline)
				.foregroundColor(.primary)
			
			// Subtitle
			Text(.localized("Start server and install"))
				.font(.subheadline)
				.foregroundColor(.secondary)
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
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			
			Divider()
				.padding(.leading, 16)
			
			// App Name
			_infoRow(label: .localized("App Name:"), value: app.name ?? .localized("Unknown"))
			
			Divider()
				.padding(.leading, 16)
			
			// Bundle ID
			_infoRow(label: .localized("Bundle ID:"), value: app.identifier ?? .localized("Unknown"))
			
			Divider()
				.padding(.leading, 16)
			
			// Version
			_infoRow(label: .localized("Version:"), value: app.version ?? .localized("Unknown"))
			
			// Days Remaining (if signed)
			if app.isSigned, let daysRemaining = _getDaysRemaining() {
				Divider()
					.padding(.leading, 16)
				
				_infoRow(label: .localized("Days Remaining:"), value: "\(daysRemaining)")
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: Device Info Card
	@ViewBuilder
	private func _deviceInfoCard() -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			HStack(spacing: 10) {
				Image(systemName: "iphone")
					.font(.title3)
					.foregroundColor(.orange)
				Text(.localized("Device Information"))
					.font(.headline)
					.fontWeight(.semibold)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			
			Divider()
				.padding(.leading, 16)
			
			// Device Model
			_infoRow(label: .localized("Device:"), value: _deviceModel)
			
			Divider()
				.padding(.leading, 16)
			
			// iOS Version
			_infoRow(label: .localized("iOS Version:"), value: UIDevice.current.systemVersion)
			
			Divider()
				.padding(.leading, 16)
			
			// Software Type
			_infoRow(label: .localized("Software:"), value: "iOS \(UIDevice.current.systemName)")
			
			Divider()
				.padding(.leading, 16)
			
			// UDID (device identifier)
			_infoRow(label: .localized("UDID:"), value: _deviceUDID)
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: Signing Info Card
	@ViewBuilder
	private func _signingInfoCard() -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			HStack(spacing: 10) {
				Image(systemName: "signature")
					.font(.title3)
					.foregroundColor(app.isSigned ? .green : .gray)
				Text(.localized("Signing Information"))
					.font(.headline)
					.fontWeight(.semibold)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			
			Divider()
				.padding(.leading, 16)
			
			// Signed Status
			_infoRow(label: .localized("Status:"), value: app.isSigned ? .localized("Signed") : .localized("Not Signed"))
			
			// Category (if available)
			if let category = Storage.shared.getCategory(for: app) {
				Divider()
					.padding(.leading, 16)
				
				_infoRow(label: .localized("Category:"), value: category.name ?? .localized("Unknown"))
			}
			
			// Certificate Info (if signed)
			if let cert = Storage.shared.getCertificate(from: app) {
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
				}
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	@ViewBuilder
	private func _infoRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.frame(width: 100, alignment: .leading)
			
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
	
	// MARK: Server Section
	#if SERVER
	@ViewBuilder
	private func _serverSection() -> some View {
		VStack(alignment: .leading, spacing: 12) {
			// Header with status
			HStack {
				HStack(spacing: 10) {
					Image(systemName: "server.rack")
						.font(.title3)
						.foregroundColor(.green)
					Text(.localized("HTTPS Server"))
						.font(.headline)
						.fontWeight(.semibold)
				}
				
				Spacer()
				
				// Status indicator
				HStack(spacing: 6) {
					Circle()
						.fill(_isServerRunning ? Color.green : Color.red)
						.frame(width: 8, height: 8)
					Text(_isServerRunning ? .localized("Running") : .localized("Stopped"))
						.font(.caption)
						.foregroundColor(_isServerRunning ? .green : .red)
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 14)
			
			// Start/Stop Server Button
			Button {
				if !_isServerRunning {
					_startInstall()
				}
			} label: {
				HStack(spacing: 8) {
					Image(systemName: _isServerRunning ? "stop.circle.fill" : "play.circle.fill")
						.font(.title3)
					Text(_isServerRunning ? .localized("Stop Server") : .localized("Start Server"))
						.font(.subheadline)
						.fontWeight(.semibold)
				}
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(_isServerRunning ? Color.red : Color.green)
				)
			}
			.buttonStyle(.plain)
			.padding(.horizontal, 16)
			
			// Configured Files
			VStack(alignment: .leading, spacing: 8) {
				Text(.localized("Configured Files:"))
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundColor(.secondary)
				
				HStack(spacing: 8) {
					Text("IPA:")
						.font(.caption)
						.foregroundColor(.secondary)
						.frame(width: 35, alignment: .leading)
					Text(installer.packageUrl?.lastPathComponent ?? app.identifier ?? "...")
						.font(.caption)
						.foregroundColor(.primary)
						.lineLimit(1)
						.minimumScaleFactor(0.7)
				}
				
				HStack(spacing: 8) {
					Text("Plist:")
						.font(.caption)
						.foregroundColor(.secondary)
						.frame(width: 35, alignment: .leading)
					Text("Install.plist")
						.font(.caption)
						.foregroundColor(.primary)
				}
			}
			.padding(.horizontal, 16)
			.padding(.bottom, 14)
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color.green.opacity(0.08))
				.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(Color.green.opacity(0.2), lineWidth: 1)
				)
		)
	}
	#endif
	
	// MARK: Installation Section
	@ViewBuilder
	private func _installationSection() -> some View {
		VStack(spacing: 12) {
			// Section Header
			HStack {
				Text(.localized("Installation"))
					.font(.headline)
					.fontWeight(.semibold)
				Spacer()
			}
			.padding(.horizontal, 4)
			
			// Install on iOS Device Button - Only show when server is running
			#if SERVER
			if _isServerRunning {
				Button {
					if _serverMethod == 0 {
						UIApplication.shared.open(URL(string: installer.iTunesLink)!)
					} else {
						_isWebviewPresenting = true
					}
					// Auto-close after 5 seconds
					DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
						dismiss()
					}
				} label: {
					HStack {
						HStack(spacing: 12) {
							Image(systemName: "iphone.and.arrow.forward")
								.font(.title2)
								.foregroundColor(.white)
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Install on This Device"))
									.font(.subheadline)
									.fontWeight(.semibold)
									.foregroundColor(.white)
								Text(.localized("Opens iOS installation dialog"))
									.font(.caption)
									.foregroundColor(.white.opacity(0.8))
							}
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundColor(.white.opacity(0.7))
					}
					.padding(16)
					.background(
						RoundedRectangle(cornerRadius: 14)
							.fill(Color.purple)
					)
				}
				.buttonStyle(.plain)
				
				// Copy Install URL Button
				Button {
					UIPasteboard.general.string = installer.iTunesLink
					_showCopyConfirmation = true
					UINotificationFeedbackGenerator().notificationOccurred(.success)
					
					DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
						_showCopyConfirmation = false
					}
				} label: {
					HStack(spacing: 10) {
						Image(systemName: _showCopyConfirmation ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
							.font(.title3)
						Text(_showCopyConfirmation ? .localized("Copied!") : .localized("Copy Install URL"))
							.font(.subheadline)
							.fontWeight(.semibold)
					}
					.foregroundColor(.white)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 14)
					.background(
						RoundedRectangle(cornerRadius: 14)
							.fill(Color.blue)
					)
				}
				.buttonStyle(.plain)
			}
			#endif
			
			// Progress indicator
			if !viewModel.isCompleted && !_isReady {
				HStack(spacing: 12) {
					ProgressView()
						.scaleEffect(0.8)
					
					Text(viewModel.statusLabel)
						.font(.caption)
						.foregroundColor(.secondary)
				}
				.padding(.top, 8)
			}
		}
	}
}

// MARK: - Helper Methods
extension InstallPreviewView {
	private var _isReady: Bool {
		if case .ready = viewModel.status {
			return true
		}
		return false
	}
	
	private var _deviceModel: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		return identifier
	}
	
	private var _deviceUDID: String {
		// Get vendor identifier (closest to UDID available without entitlements)
		return UIDevice.current.identifierForVendor?.uuidString ?? .localized("Unknown")
	}
	
	private func _getDaysRemaining() -> Int? {
		// Try to get certificate expiration from the app or storage
		guard let signed = app as? Signed,
			  let cert = signed.certificate,
			  let decoded = Storage.shared.getProvisionFileDecoded(for: cert) else {
			return nil
		}
		
		let expDate = decoded.ExpirationDate
		let days = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
		return days
	}
	
	private func _startInstall() {
		Task.detached {
			do {
				let handler = await ArchiveHandler(app: app, viewModel: viewModel)
				try await handler.move()
				
				let packageUrl = try await handler.archive()
				
				if await !isSharing {
					#if SERVER
					await MainActor.run {
						installer.packageUrl = packageUrl
						viewModel.status = .ready
					}
					#elseif IDEVICE
					let handler = await ConduitInstaller(viewModel: viewModel)
					try await handler.install(at: packageUrl)
					#endif
				} else {
					let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
					
					if await !_useShareSheet {
						await MainActor.run {
							dismiss()
						}
					} else {
						if let package {
							await MainActor.run {
								dismiss()
								UIActivityViewController.show(activityItems: [package])
							}
						}
					}
				}
			} catch {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: .localized("Install"),
						message: error.localizedDescription,
						action: {
							#if IDEVICE
							HeartbeatManager.shared.start(true)
							#endif
							dismiss()
						}
					)
				}
			}
		}
	}
}
