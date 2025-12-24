//
//  ThemeManager.swift
//  Ksign
//
//  Created for custom theme customization.
//

import SwiftUI
import UIKit

// MARK: - Theme Element Types
enum ThemeElement: String, CaseIterable, Identifiable {
    case accentColor = "Accent Color"
    case backgroundColor = "Background Color"
    case secondaryBackgroundColor = "Secondary Background"
    case primaryTextColor = "Primary Text"
    case secondaryTextColor = "Secondary Text"
    case navigationBarColor = "Navigation Bar"
    case tabBarColor = "Tab Bar"
    case buttonColor = "Button Color"
    case cardBackgroundColor = "Card Background"
    case borderColor = "Border Color"
    case successColor = "Success Color"
    case warningColor = "Warning Color"
    case errorColor = "Error Color"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .accentColor: return "paintbrush.fill"
        case .backgroundColor: return "rectangle.fill"
        case .secondaryBackgroundColor: return "rectangle.grid.2x2.fill"
        case .primaryTextColor: return "textformat"
        case .secondaryTextColor: return "textformat.alt"
        case .navigationBarColor: return "rectangle.topthird.inset.filled"
        case .tabBarColor: return "rectangle.bottomthird.inset.filled"
        case .buttonColor: return "button.horizontal.fill"
        case .cardBackgroundColor: return "rectangle.on.rectangle.fill"
        case .borderColor: return "rectangle.inset.filled"
        case .successColor: return "checkmark.circle.fill"
        case .warningColor: return "exclamationmark.triangle.fill"
        case .errorColor: return "xmark.circle.fill"
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .accentColor: return Color(red: 0x53/255, green: 0x94/255, blue: 0xF7/255)
        case .backgroundColor: return Color(.systemBackground)
        case .secondaryBackgroundColor: return Color(.secondarySystemBackground)
        case .primaryTextColor: return Color(.label)
        case .secondaryTextColor: return Color(.secondaryLabel)
        case .navigationBarColor: return Color(.systemBackground)
        case .tabBarColor: return Color(.systemBackground)
        case .buttonColor: return Color(red: 0x53/255, green: 0x94/255, blue: 0xF7/255)
        case .cardBackgroundColor: return Color(.secondarySystemBackground)
        case .borderColor: return Color(.separator)
        case .successColor: return .green
        case .warningColor: return .orange
        case .errorColor: return .red
        }
    }
    
    var storageKey: String {
        return "Ksign.theme.\(self.rawValue.replacingOccurrences(of: " ", with: ""))"
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published private var customColors: [ThemeElement: Color] = [:]
    @Published var useCustomTheme: Bool {
        didSet {
            UserDefaults.standard.set(useCustomTheme, forKey: "Ksign.theme.useCustomTheme")
            objectWillChange.send()
            applyTheme()
        }
    }
    
    private init() {
        self.useCustomTheme = UserDefaults.standard.bool(forKey: "Ksign.theme.useCustomTheme")
        loadSavedColors()
    }
    
    // MARK: - Color Management
    
    func color(for element: ThemeElement) -> Color {
        if useCustomTheme, let customColor = customColors[element] {
            return customColor
        }
        return element.defaultColor
    }
    
    func setColor(_ color: Color, for element: ThemeElement) {
        customColors[element] = color
        saveColor(color, for: element)
        objectWillChange.send()
        applyTheme()
    }
    
    func resetColor(for element: ThemeElement) {
        customColors.removeValue(forKey: element)
        UserDefaults.standard.removeObject(forKey: element.storageKey)
        objectWillChange.send()
        applyTheme()
    }
    
    func resetAllColors() {
        for element in ThemeElement.allCases {
            customColors.removeValue(forKey: element)
            UserDefaults.standard.removeObject(forKey: element.storageKey)
        }
        objectWillChange.send()
        applyTheme()
    }
    
    // MARK: - Persistence
    
    private func saveColor(_ color: Color, for element: ThemeElement) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let colorData: [CGFloat] = [red, green, blue, alpha]
        UserDefaults.standard.set(colorData, forKey: element.storageKey)
    }
    
    private func loadSavedColors() {
        for element in ThemeElement.allCases {
            if let colorData = UserDefaults.standard.array(forKey: element.storageKey) as? [CGFloat],
               colorData.count == 4 {
                let color = Color(
                    red: Double(colorData[0]),
                    green: Double(colorData[1]),
                    blue: Double(colorData[2]),
                    opacity: Double(colorData[3])
                )
                customColors[element] = color
            }
        }
    }
    
    // MARK: - Apply Theme
    
    func applyTheme() {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { window in
                    // Apply accent/tint color
                    window.tintColor = UIColor(self.color(for: .accentColor))
                    
                    // Apply navigation bar appearance
                    let navAppearance = UINavigationBarAppearance()
                    navAppearance.configureWithDefaultBackground()
                    navAppearance.backgroundColor = UIColor(self.color(for: .navigationBarColor))
                    navAppearance.titleTextAttributes = [.foregroundColor: UIColor(self.color(for: .primaryTextColor))]
                    navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(self.color(for: .primaryTextColor))]
                    
                    UINavigationBar.appearance().standardAppearance = navAppearance
                    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
                    UINavigationBar.appearance().compactAppearance = navAppearance
                    
                    // Apply tab bar appearance
                    let tabAppearance = UITabBarAppearance()
                    tabAppearance.configureWithDefaultBackground()
                    tabAppearance.backgroundColor = UIColor(self.color(for: .tabBarColor))
                    
                    UITabBar.appearance().standardAppearance = tabAppearance
                    if #available(iOS 15.0, *) {
                        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
                    }
                }
        }
    }
    
    // MARK: - UIColor Helpers
    
    func uiColor(for element: ThemeElement) -> UIColor {
        return UIColor(color(for: element))
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

// MARK: - Preset Themes
struct PresetTheme: Identifiable, Codable {
    var id = UUID()
    let name: String
    let colors: [String: String] // Store as hex strings for Codable
    let icon: String
    var isUserPreset: Bool = false
    
    // Convert to ThemeElement colors
    func getColors() -> [ThemeElement: Color] {
        var result: [ThemeElement: Color] = [:]
        for (key, hexValue) in colors {
            if let element = ThemeElement.allCases.first(where: { $0.rawValue == key }) {
                result[element] = Color(hex: hexValue)
            }
        }
        return result
    }
    
    // Create from ThemeElement colors
    init(name: String, colors: [ThemeElement: Color], icon: String, isUserPreset: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isUserPreset = isUserPreset
        
        var colorDict: [String: String] = [:]
        for (element, color) in colors {
            colorDict[element.rawValue] = color.toHex()
        }
        self.colors = colorDict
    }
    
    // For Codable
    init(id: UUID = UUID(), name: String, colors: [String: String], icon: String, isUserPreset: Bool = false) {
        self.id = id
        self.name = name
        self.colors = colors
        self.icon = icon
        self.isUserPreset = isUserPreset
    }
    
    static let presets: [PresetTheme] = [
        PresetTheme(
            name: "Ocean Blue",
            colors: [
                .accentColor: Color(hex: "0077B6"),
                .backgroundColor: Color(hex: "03045E"),
                .secondaryBackgroundColor: Color(hex: "023E8A"),
                .primaryTextColor: .white,
                .secondaryTextColor: Color(hex: "90E0EF"),
                .navigationBarColor: Color(hex: "03045E"),
                .tabBarColor: Color(hex: "03045E"),
                .buttonColor: Color(hex: "00B4D8"),
                .cardBackgroundColor: Color(hex: "023E8A"),
                .borderColor: Color(hex: "0077B6"),
                .successColor: Color(hex: "06D6A0"),
                .warningColor: Color(hex: "FFD166"),
                .errorColor: Color(hex: "EF476F")
            ],
            icon: "water.waves"
        ),
        PresetTheme(
            name: "Sunset",
            colors: [
                .accentColor: Color(hex: "FF6B6B"),
                .backgroundColor: Color(hex: "2D2D2D"),
                .secondaryBackgroundColor: Color(hex: "3D3D3D"),
                .primaryTextColor: .white,
                .secondaryTextColor: Color(hex: "C4A77D"),
                .navigationBarColor: Color(hex: "2D2D2D"),
                .tabBarColor: Color(hex: "2D2D2D"),
                .buttonColor: Color(hex: "FF8E53"),
                .cardBackgroundColor: Color(hex: "3D3D3D"),
                .borderColor: Color(hex: "FF6B6B"),
                .successColor: Color(hex: "4ECDC4"),
                .warningColor: Color(hex: "FFE66D"),
                .errorColor: Color(hex: "FF6B6B")
            ],
            icon: "sunset.fill"
        ),
        PresetTheme(
            name: "Forest",
            colors: [
                .accentColor: Color(hex: "2D6A4F"),
                .backgroundColor: Color(hex: "1B4332"),
                .secondaryBackgroundColor: Color(hex: "2D6A4F"),
                .primaryTextColor: .white,
                .secondaryTextColor: Color(hex: "95D5B2"),
                .navigationBarColor: Color(hex: "1B4332"),
                .tabBarColor: Color(hex: "1B4332"),
                .buttonColor: Color(hex: "40916C"),
                .cardBackgroundColor: Color(hex: "2D6A4F"),
                .borderColor: Color(hex: "52B788"),
                .successColor: Color(hex: "74C69D"),
                .warningColor: Color(hex: "FFD166"),
                .errorColor: Color(hex: "E76F51")
            ],
            icon: "leaf.fill"
        ),
        PresetTheme(
            name: "Midnight Purple",
            colors: [
                .accentColor: Color(hex: "9D4EDD"),
                .backgroundColor: Color(hex: "10002B"),
                .secondaryBackgroundColor: Color(hex: "240046"),
                .primaryTextColor: .white,
                .secondaryTextColor: Color(hex: "C77DFF"),
                .navigationBarColor: Color(hex: "10002B"),
                .tabBarColor: Color(hex: "10002B"),
                .buttonColor: Color(hex: "7B2CBF"),
                .cardBackgroundColor: Color(hex: "240046"),
                .borderColor: Color(hex: "9D4EDD"),
                .successColor: Color(hex: "06D6A0"),
                .warningColor: Color(hex: "FFD166"),
                .errorColor: Color(hex: "FF6B6B")
            ],
            icon: "moon.stars.fill"
        ),
        PresetTheme(
            name: "Cherry Blossom",
            colors: [
                .accentColor: Color(hex: "FF69B4"),
                .backgroundColor: Color(hex: "FFF0F5"),
                .secondaryBackgroundColor: Color(hex: "FFE4E9"),
                .primaryTextColor: Color(hex: "4A4A4A"),
                .secondaryTextColor: Color(hex: "8B7D7B"),
                .navigationBarColor: Color(hex: "FFF0F5"),
                .tabBarColor: Color(hex: "FFF0F5"),
                .buttonColor: Color(hex: "FF85A2"),
                .cardBackgroundColor: Color(hex: "FFE4E9"),
                .borderColor: Color(hex: "FFB6C1"),
                .successColor: Color(hex: "90EE90"),
                .warningColor: Color(hex: "F0E68C"),
                .errorColor: Color(hex: "CD5C5C")
            ],
            icon: "camera.macro"
        ),
        PresetTheme(
            name: "Cyberpunk",
            colors: [
                .accentColor: Color(hex: "00FF41"),
                .backgroundColor: Color(hex: "0D0D0D"),
                .secondaryBackgroundColor: Color(hex: "1A1A2E"),
                .primaryTextColor: Color(hex: "00FF41"),
                .secondaryTextColor: Color(hex: "0ABDC6"),
                .navigationBarColor: Color(hex: "0D0D0D"),
                .tabBarColor: Color(hex: "0D0D0D"),
                .buttonColor: Color(hex: "FF2A6D"),
                .cardBackgroundColor: Color(hex: "1A1A2E"),
                .borderColor: Color(hex: "00FF41"),
                .successColor: Color(hex: "00FF41"),
                .warningColor: Color(hex: "FFD300"),
                .errorColor: Color(hex: "FF2A6D")
            ],
            icon: "sparkles"
        )
    ]
}

// MARK: - User Preset Manager
class UserPresetManager: ObservableObject {
    static let shared = UserPresetManager()
    
    @Published var userPresets: [PresetTheme] = []
    
    private let presetsKey = "Ksign.theme.userPresets"
    
    private init() {
        loadUserPresets()
    }
    
    // MARK: - Save / Load
    
    func saveCurrentAsPreset(name: String, icon: String) {
        let themeManager = ThemeManager.shared
        var colors: [ThemeElement: Color] = [:]
        
        for element in ThemeElement.allCases {
            colors[element] = themeManager.color(for: element)
        }
        
        let preset = PresetTheme(name: name, colors: colors, icon: icon, isUserPreset: true)
        userPresets.append(preset)
        saveUserPresets()
    }
    
    func deletePreset(_ preset: PresetTheme) {
        userPresets.removeAll { $0.id == preset.id }
        saveUserPresets()
    }
    
    func applyPreset(_ preset: PresetTheme) {
        let themeManager = ThemeManager.shared
        let colors = preset.getColors()
        
        for (element, color) in colors {
            themeManager.setColor(color, for: element)
        }
        
        // Ensure theme is applied
        themeManager.applyTheme()
    }
    
    private func saveUserPresets() {
        if let data = try? JSONEncoder().encode(userPresets) {
            UserDefaults.standard.set(data, forKey: presetsKey)
        }
    }
    
    private func loadUserPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let presets = try? JSONDecoder().decode([PresetTheme].self, from: data) {
            userPresets = presets
        }
    }
    
    // MARK: - Import / Export
    
    func exportPreset(_ preset: PresetTheme) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(preset) else { return nil }
        
        let fileName = "\(preset.name.replacingOccurrences(of: " ", with: "_")).ksigntheme"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export preset: \(error)")
            return nil
        }
    }
    
    func exportAllPresets() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(userPresets) else { return nil }
        
        let fileName = "KsignThemes_\(Date().timeIntervalSince1970).ksignthemes"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export presets: \(error)")
            return nil
        }
    }
    
    func importPreset(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            
            // Try single preset first
            if let preset = try? JSONDecoder().decode(PresetTheme.self, from: data) {
                var newPreset = preset
                newPreset.isUserPreset = true
                userPresets.append(newPreset)
                saveUserPresets()
                return true
            }
            
            // Try array of presets
            if let presets = try? JSONDecoder().decode([PresetTheme].self, from: data) {
                for var preset in presets {
                    preset.isUserPreset = true
                    userPresets.append(preset)
                }
                saveUserPresets()
                return true
            }
            
            return false
        } catch {
            print("Failed to import preset: \(error)")
            return false
        }
    }
}

// MARK: - Available Icons for User Presets
enum ThemeIcons {
    static let all: [String] = [
        "paintpalette.fill",
        "paintbrush.fill",
        "drop.fill",
        "sparkles",
        "star.fill",
        "heart.fill",
        "moon.fill",
        "sun.max.fill",
        "cloud.fill",
        "leaf.fill",
        "flame.fill",
        "bolt.fill",
        "wand.and.stars",
        "hexagon.fill",
        "diamond.fill",
        "circle.hexagongrid.fill",
        "peacesign",
        "infinity",
        "crown.fill",
        "globe.americas.fill"
    ]
}
