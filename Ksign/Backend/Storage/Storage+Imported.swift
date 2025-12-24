//
//  Storage+Imported.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import CoreData
import UIKit.UIImpactFeedbackGenerator

// MARK: - Class extension: Imported Apps
extension Storage {
	func addImported(
		uuid: String,
		source: URL? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		let new = Imported(context: context)
		
		new.uuid = uuid
		new.source = source
		new.date = Date()
		// could possibly be nil, but thats fine.
		// ?
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
