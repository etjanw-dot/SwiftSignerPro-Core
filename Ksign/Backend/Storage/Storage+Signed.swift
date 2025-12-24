//
//  Storage+Signed.swift
//  Feather
//
//  Created by samara on 17.04.2025.
//

import CoreData
import UIKit.UIImpactFeedbackGenerator

// MARK: - Class extension: Signed Apps
extension Storage {
	func addSigned(
		uuid: String,
		source: URL? = nil,
		certificate: CertificatePair? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		let new = Signed(context: context)
		
		new.uuid = uuid
		new.source = source
		new.date = Date()
		// if nil, we assume adhoc or certificate was deleted afterwards
		new.certificate = certificate
		// could possibly be nil, but thats fine.
		new.identifier = appIdentifier
		new.name = appName
		new.icon = appIcon
		new.version = appVersion
		
		// Apply default expiration if enabled
		if UserDefaults.standard.bool(forKey: "Feather.defaultAutoDelete") {
			let days = UserDefaults.standard.integer(forKey: "Feather.defaultAutoDeleteDays")
			let actualDays = days > 0 ? days : 7 // Default to 7 days if not set
			new.expirationDate = Date().addingTimeInterval(Double(actualDays) * 86400)
		}
		
        saveContext()
        generator.impactOccurred()
        completion(nil)
	}
}
