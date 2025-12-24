//
//  Storage+Shared.swift
//  Feather
//
//  Created by samara on 17.04.2025.
//

import CoreData

// MARK: - Class extension: Apps (Shared)
extension Storage {
	func getUuidDirectory(for app: AppInfoPresentable) -> URL? {
		guard let uuid = app.uuid else { return nil }
		return app.isSigned
		? FileManager.default.signed(uuid)
		: FileManager.default.unsigned(uuid)
	}
	
	func getAppDirectory(for app: AppInfoPresentable) -> URL? {
		guard let url = getUuidDirectory(for: app) else { return nil }
		return FileManager.default.getPath(in: url, for: "app")
	}
	
	func deleteApp(for app: AppInfoPresentable) {
		do {
			if let url = getUuidDirectory(for: app) {
				try? FileManager.default.removeItem(at: url)
			}
			if let object = app as? NSManagedObject {
				context.delete(object)
			}
			saveContext()
		}
	}
	
	func getCertificate(from app: AppInfoPresentable) -> CertificatePair? {
		if let signed = app as? Signed {
			return signed.certificate
		}
		return nil
	}
}

// MARK: - Helpers
struct AnyApp: Identifiable {
	let base: AppInfoPresentable
	var archive: Bool = false
	var signAndInstall: Bool = false
	
	var id: String {
		base.uuid ?? UUID().uuidString
	}
}

// MARK: - App Type Enum
enum AppType: String {
	case ipa = "ipa"
	case app = "app"
	case unknown = "unknown"
}

protocol AppInfoPresentable {
	var name: String? { get }
	var version: String? { get }
	var identifier: String? { get }
	var date: Date? { get }
	var icon: String? { get }
	var uuid: String? { get }
	var isSigned: Bool { get }
	var size: Int64? { get }
	var type: AppType? { get }
	var expirationDate: Date? { get }
}

// Default implementations for optional properties
extension AppInfoPresentable {
	var size: Int64? { nil }
	var type: AppType? { nil }
	var expirationDate: Date? { nil }
	
	/// Computed URL from icon path
	var iconURL: URL? {
		guard let iconPath = icon else { return nil }
		// Check if it's a path string or already a URL string
		if iconPath.hasPrefix("http://") || iconPath.hasPrefix("https://") {
			return URL(string: iconPath)
		}
		// It's a local file path
		return URL(fileURLWithPath: iconPath)
	}
}

extension Signed: AppInfoPresentable {
	var isSigned: Bool { true }
}

extension Imported: AppInfoPresentable {
	var isSigned: Bool { false }
}

