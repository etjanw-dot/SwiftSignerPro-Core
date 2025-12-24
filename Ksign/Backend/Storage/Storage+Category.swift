//
//  Storage+Category.swift
//  Feather
//
//  Category/Folder management for organizing apps
//

import CoreData
import SwiftUI
import UIKit.UIImpactFeedbackGenerator

// MARK: - Class extension: App Categories
extension Storage {
    
    // MARK: - Add Category
    func addCategory(
        name: String,
        icon: String? = "folder.fill",
        color: String? = "blue",
        completion: @escaping (AppCategory?, Error?) -> Void
    ) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        
        let new = AppCategory(context: context)
        new.uuid = UUID().uuidString
        new.name = name
        new.icon = icon
        new.color = color
        new.date = Date()
        
        saveContext()
        generator.impactOccurred()
        completion(new, nil)
    }
    
    // MARK: - Delete Category
    func deleteCategory(_ category: AppCategory) {
        // Remove category reference from all apps first
        if let signedApps = category.signedApps as? Set<Signed> {
            for app in signedApps {
                app.category = nil
            }
        }
        if let importedApps = category.importedApps as? Set<Imported> {
            for app in importedApps {
                app.category = nil
            }
        }
        
        context.delete(category)
        saveContext()
    }
    
    // MARK: - Update Category
    func updateCategory(_ category: AppCategory, name: String? = nil, icon: String? = nil, color: String? = nil) {
        if let name = name { category.name = name }
        if let icon = icon { category.icon = icon }
        if let color = color { category.color = color }
        saveContext()
    }
    
    // MARK: - Set App Category
    func setCategory(_ category: AppCategory?, for app: AppInfoPresentable) {
        if let signed = app as? Signed {
            signed.category = category
            saveContext()
        } else if let imported = app as? Imported {
            imported.category = category
            saveContext()
        }
    }
    
    // MARK: - Get Category for App
    func getCategory(for app: AppInfoPresentable) -> AppCategory? {
        if let signed = app as? Signed {
            return signed.category
        } else if let imported = app as? Imported {
            return imported.category
        }
        return nil
    }
    
    // MARK: - Fetch All Categories
    func fetchCategories() -> [AppCategory] {
        let request: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Get Apps in Category
    func getAppsInCategory(_ category: AppCategory) -> [AppInfoPresentable] {
        var apps: [AppInfoPresentable] = []
        
        if let signedApps = category.signedApps as? Set<Signed> {
            apps.append(contentsOf: signedApps.map { $0 as AppInfoPresentable })
        }
        if let importedApps = category.importedApps as? Set<Imported> {
            apps.append(contentsOf: importedApps.map { $0 as AppInfoPresentable })
        }
        
        return apps.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // MARK: - Get Category Count
    func getCategoryAppCount(_ category: AppCategory) -> Int {
        let signedCount = (category.signedApps as? Set<Signed>)?.count ?? 0
        let importedCount = (category.importedApps as? Set<Imported>)?.count ?? 0
        return signedCount + importedCount
    }
}

// MARK: - Category Info Helper
struct CategoryInfo {
    let category: AppCategory
    let name: String
    let icon: String
    let color: Color
    
    init(category: AppCategory) {
        self.category = category
        self.name = category.name ?? "Folder"
        self.icon = category.icon ?? "folder.fill"
        self.color = Color(category.color ?? "blue")
    }
}

// MARK: - Color Extension for Category
extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "red": self = .red
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "green": self = .green
        case "mint": self = .mint
        case "teal": self = .teal
        case "cyan": self = .cyan
        case "blue": self = .blue
        case "indigo": self = .indigo
        case "purple": self = .purple
        case "pink": self = .pink
        case "brown": self = .brown
        case "gray", "grey": self = .gray
        default: self = .accentColor
        }
    }
    
    static let categoryColors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("teal", .teal),
        ("cyan", .cyan),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink),
        ("brown", .brown),
        ("gray", .gray)
    ]
}

// MARK: - Category Icons
struct CategoryIcons {
    static let all: [(name: String, icon: String)] = [
        ("Folder", "folder.fill"),
        ("Games", "gamecontroller.fill"),
        ("Social", "bubble.left.and.bubble.right.fill"),
        ("Utilities", "wrench.and.screwdriver.fill"),
        ("Entertainment", "tv.fill"),
        ("Music", "music.note"),
        ("Photo", "photo.fill"),
        ("Video", "video.fill"),
        ("Productivity", "briefcase.fill"),
        ("Finance", "dollarsign.circle.fill"),
        ("Education", "book.fill"),
        ("Health", "heart.fill"),
        ("Travel", "airplane"),
        ("Food", "fork.knife"),
        ("Shopping", "cart.fill"),
        ("News", "newspaper.fill"),
        ("Sports", "sportscourt.fill"),
        ("Weather", "cloud.sun.fill"),
        ("Developer", "hammer.fill"),
        ("Star", "star.fill"),
        ("Heart", "heart.fill"),
        ("Flag", "flag.fill"),
        ("Bookmark", "bookmark.fill")
    ]
}
