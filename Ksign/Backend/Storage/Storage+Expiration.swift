//
//  Storage+Expiration.swift
//  Feather
//
//  App expiration management - auto-delete functionality
//

import CoreData
import SwiftUI

// MARK: - Class extension: App Expiration Management
extension Storage {
    
    /// Check and delete expired apps (both signed and imported)
    /// Called on app launch
    func cleanupExpiredApps() {
        let now = Date()
        
        // Cleanup expired signed apps
        let signedRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
        signedRequest.predicate = NSPredicate(format: "expirationDate != nil AND expirationDate < %@", now as NSDate)
        
        if let expiredSigned = try? context.fetch(signedRequest) {
            for app in expiredSigned {
                print("[Expiration] Deleting expired signed app: \(app.name ?? "Unknown")")
                deleteApp(for: app)
            }
        }
        
        // Cleanup expired imported apps
        let importedRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
        importedRequest.predicate = NSPredicate(format: "expirationDate != nil AND expirationDate < %@", now as NSDate)
        
        if let expiredImported = try? context.fetch(importedRequest) {
            for app in expiredImported {
                print("[Expiration] Deleting expired imported app: \(app.name ?? "Unknown")")
                deleteApp(for: app)
            }
        }
        
        // Also cleanup orphaned records (files no longer exist)
        cleanupOrphanedRecords()
    }
    
    /// Remove CoreData entries where the actual app files no longer exist on disk
    /// This prevents crashes when loading records that point to deleted files
    func cleanupOrphanedRecords() {
        // Cleanup orphaned signed apps
        let signedRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
        if let allSigned = try? context.fetch(signedRequest) {
            for app in allSigned {
                guard let uuid = app.uuid else {
                    // No UUID = invalid record, delete it
                    context.delete(app)
                    continue
                }
                
                let appDir = FileManager.default.signed(uuid)
                if !FileManager.default.fileExists(atPath: appDir.path) {
                    print("[Cleanup] Removing orphaned signed app record: \(app.name ?? "Unknown") - files not found")
                    context.delete(app)
                }
            }
        }
        
        // Cleanup orphaned imported apps
        let importedRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
        if let allImported = try? context.fetch(importedRequest) {
            for app in allImported {
                guard let uuid = app.uuid else {
                    // No UUID = invalid record, delete it
                    context.delete(app)
                    continue
                }
                
                let appDir = FileManager.default.unsigned(uuid)
                if !FileManager.default.fileExists(atPath: appDir.path) {
                    print("[Cleanup] Removing orphaned imported app record: \(app.name ?? "Unknown") - files not found")
                    context.delete(app)
                }
            }
        }
        
        saveContext()
    }
    
    /// Set expiration date for an app
    func setExpirationDate(_ date: Date?, for app: AppInfoPresentable) {
        if let signed = app as? Signed {
            signed.expirationDate = date
            saveContext()
        } else if let imported = app as? Imported {
            imported.expirationDate = date
            saveContext()
        }
    }
    
    /// Get expiration info for an app (for badge display)
    func getExpirationInfo(for app: AppInfoPresentable) -> AppExpirationInfo? {
        var expirationDate: Date?
        
        if let signed = app as? Signed {
            expirationDate = signed.expirationDate
        } else if let imported = app as? Imported {
            expirationDate = imported.expirationDate
        }
        
        guard let expDate = expirationDate else { return nil }
        
        let now = Date()
        let timeInterval = expDate.timeIntervalSince(now)
        let daysRemaining = Int(timeInterval / 86400)
        
        return AppExpirationInfo(
            expirationDate: expDate,
            daysRemaining: daysRemaining,
            isExpired: timeInterval <= 0
        )
    }
}

// MARK: - App Expiration Info Model
struct AppExpirationInfo {
    let expirationDate: Date
    let daysRemaining: Int
    let isExpired: Bool
    
    var color: Color {
        if isExpired { return .gray }
        if daysRemaining <= 1 { return .red }
        if daysRemaining <= 3 { return .orange }
        if daysRemaining <= 7 { return .yellow }
        return .secondary
    }
    
    var shouldShowBadge: Bool {
        // Show badge if expires within 7 days or is already expired
        return daysRemaining <= 7 || isExpired
    }
    
    var formatted: String {
        if isExpired {
            return String.localized("Expired")
        }
        if daysRemaining == 0 {
            return String.localized("Today")
        }
        if daysRemaining == 1 {
            return String.localized("1 day")
        }
        return String.localized("%lld days", arguments: daysRemaining)
    }
}
