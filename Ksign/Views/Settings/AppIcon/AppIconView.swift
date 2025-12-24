//
//  AppIconView.swift
//  Ksign
//
//  Created by Nagata Asami on 6/28/25.
//

import SwiftUI
import NimbleViews
import PhotosUI

// MARK: - Models
struct AppIconOption {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let alternateIconName: String?
}

// MARK: - View
struct AppIconView: View {
    @State private var selectedIcon: String? = UIApplication.shared.alternateIconName
    @State private var customIcons: [Int: UIImage] = CustomAppIconManager.shared.getAllSlots()
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var addingToSlot: Int = 0
    
    // Custom icon slots that map to bundled alternate icons
    private let customSlotNames = ["custom_1", "custom_2", "custom_3", "custom_4", "custom_5", "custom_6", "custom_7"]
    
    private let presetIcons: [AppIconOption] = [
        AppIconOption(
            id: "primary",
            title: "Default",
            subtitle: "SwiftSigner Pro",
            iconName: "AppIcon",
            alternateIconName: nil
        ),
        
        AppIconOption(id: "kana_peek", title: "Peek", subtitle: "Kana", iconName: "kana_peek", alternateIconName: "kana_peek"),
        AppIconOption(id: "kana_love", title: "Love", subtitle: "Kana", iconName: "kana_love", alternateIconName: "kana_love"),
        AppIconOption(id: "kana_ded", title: "Skull", subtitle: "Kana", iconName: "kana_ded", alternateIconName: "kana_ded"),
    ]
    
    // MARK: Body
    var body: some View {
        NBList(.localized("App Icon")) {
            // Custom Icons Section
            NBSection(.localized("Custom Icons (\(customIcons.count)/7)")) {
                // Existing custom icons
                ForEach(Array(customIcons.keys.sorted()), id: \.self) { slot in
                    if let icon = customIcons[slot] {
                        _customIconRow(slot: slot, icon: icon)
                    }
                }
                
                // Add new icon button (only show if less than 7)
                if customIcons.count < 7 {
                    Button {
                        // Find first empty slot
                        for i in 0..<7 {
                            if customIcons[i] == nil {
                                addingToSlot = i
                                showingPhotoPicker = true
                                break
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13.5)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(.localized("Add Custom Icon"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(.localized("Pick from Photos"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Preset Icons Section
            NBSection(.localized("Preset Icons")) {
                ForEach(presetIcons, id: \.id) { iconOption in
                    _presetIconCell(for: iconOption)
                }
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newValue in
            Task {
                await _handlePhotoSelection(newValue, toSlot: addingToSlot)
            }
        }
        .onAppear {
            _refreshState()
        }
    }
    
    private func _refreshState() {
        selectedIcon = UIApplication.shared.alternateIconName
        customIcons = CustomAppIconManager.shared.getAllSlots()
    }
}

// MARK: - View extension
extension AppIconView {
    @ViewBuilder
    private func _customIconRow(slot: Int, icon: UIImage) -> some View {
        let slotName = customSlotNames[slot]
        let isSelected = selectedIcon == slotName
        
        Button {
            _applyCustomIcon(slot: slot)
        } label: {
            HStack(spacing: 12) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13.5)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom \(slot + 1)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(.localized("Tap to apply"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.headline)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                _removeCustomIcon(slot: slot)
            } label: {
                Label(.localized("Delete"), systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                _applyCustomIcon(slot: slot)
            } label: {
                Label(.localized("Apply Icon"), systemImage: "checkmark")
            }
            
            Button {
                addingToSlot = slot
                showingPhotoPicker = true
            } label: {
                Label(.localized("Replace Image"), systemImage: "photo")
            }
            
            Button(role: .destructive) {
                _removeCustomIcon(slot: slot)
            } label: {
                Label(.localized("Delete"), systemImage: "trash")
            }
        }
    }
    
    private func _applyCustomIcon(slot: Int) {
        let slotName = customSlotNames[slot]
        UIApplication.shared.setAlternateIconName(slotName) { error in
            if error == nil {
                selectedIcon = slotName
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func _removeCustomIcon(slot: Int) {
        CustomAppIconManager.shared.removeCustomIcon(fromSlot: slot)
        customIcons.removeValue(forKey: slot)
        // If this was the active icon, reset to default
        if selectedIcon == customSlotNames[slot] {
            UIApplication.shared.setAlternateIconName(nil) { error in
                if error == nil {
                    selectedIcon = nil
                }
            }
        }
    }
    
    private func _handlePhotoSelection(_ item: PhotosPickerItem?, toSlot slot: Int) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let resizedImage = image.resizeToSquare() {
                CustomAppIconManager.shared.saveCustomIcon(resizedImage, toSlot: slot)
                await MainActor.run {
                    customIcons[slot] = resizedImage
                }
            }
        } catch {
            print("Failed to load image: \(error.localizedDescription)")
        }
    }
    
    @ViewBuilder
    private func _presetIconCell(for iconOption: AppIconOption) -> some View {
        Button {
            _changeAppIcon(to: iconOption)
        } label: {
            HStack(spacing: 12) {
                if let image = UIImage(named: iconOption.iconName) ?? UIImage(named: Bundle.main.iconFileName ?? "") {
                    Image(uiImage: image)
                        .appIconStyle(size: 60)
                } else {
                    Image("App_Unknown")
                        .appIconStyle(size: 60)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(iconOption.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(iconOption.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedIcon == iconOption.alternateIconName {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.headline)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func _changeAppIcon(to iconOption: AppIconOption) {
        guard selectedIcon != iconOption.alternateIconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconOption.alternateIconName) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to change app icon: \(error.localizedDescription)")
                } else {
                    self.selectedIcon = iconOption.alternateIconName
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
}

// MARK: - Custom App Icon Manager
class CustomAppIconManager {
    static let shared = CustomAppIconManager()
    
    static let maxSlots = 7
    
    private let customIconKeyPrefix = "customAppIcon_"
    private let customIconActiveKey = "customAppIconActive"
    private let selectedSlotKey = "customAppIconSelectedSlot"
    
    private init() {}
    
    // MARK: - Slot-based methods
    
    func saveCustomIcon(_ image: UIImage, toSlot slot: Int) {
        guard slot >= 0 && slot < Self.maxSlots else { return }
        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: "\(customIconKeyPrefix)\(slot)")
        }
    }
    
    func loadCustomIcon(fromSlot slot: Int) -> UIImage? {
        guard slot >= 0 && slot < Self.maxSlots else { return nil }
        guard let data = UserDefaults.standard.data(forKey: "\(customIconKeyPrefix)\(slot)") else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func removeCustomIcon(fromSlot slot: Int) {
        guard slot >= 0 && slot < Self.maxSlots else { return }
        UserDefaults.standard.removeObject(forKey: "\(customIconKeyPrefix)\(slot)")
        // If this was the selected slot, deactivate
        if getSelectedSlot() == slot {
            setCustomIconActive(false)
        }
    }
    
    func hasIcon(inSlot slot: Int) -> Bool {
        guard slot >= 0 && slot < Self.maxSlots else { return false }
        return UserDefaults.standard.data(forKey: "\(customIconKeyPrefix)\(slot)") != nil
    }
    
    func selectSlot(_ slot: Int) {
        guard slot >= 0 && slot < Self.maxSlots else { return }
        guard hasIcon(inSlot: slot) else { return }
        UserDefaults.standard.set(slot, forKey: selectedSlotKey)
        setCustomIconActive(true)
    }
    
    func getSelectedSlot() -> Int {
        return UserDefaults.standard.integer(forKey: selectedSlotKey)
    }
    
    func getAllSlots() -> [Int: UIImage] {
        var slots: [Int: UIImage] = [:]
        for i in 0..<Self.maxSlots {
            if let icon = loadCustomIcon(fromSlot: i) {
                slots[i] = icon
            }
        }
        return slots
    }
    
    func getFilledSlotCount() -> Int {
        return (0..<Self.maxSlots).filter { hasIcon(inSlot: $0) }.count
    }
    
    // MARK: - Legacy compatibility methods
    
    func saveCustomIcon(_ image: UIImage) {
        // Save to the next available slot, or slot 0 if none available
        for i in 0..<Self.maxSlots {
            if !hasIcon(inSlot: i) {
                saveCustomIcon(image, toSlot: i)
                selectSlot(i)
                return
            }
        }
        // All slots full, overwrite slot 0
        saveCustomIcon(image, toSlot: 0)
        selectSlot(0)
    }
    
    func loadCustomIcon() -> UIImage? {
        guard isCustomIconActive() else { return nil }
        return loadCustomIcon(fromSlot: getSelectedSlot())
    }
    
    func removeCustomIcon() {
        removeCustomIcon(fromSlot: getSelectedSlot())
        setCustomIconActive(false)
    }
    
    func isCustomIconActive() -> Bool {
        return UserDefaults.standard.bool(forKey: customIconActiveKey)
    }
    
    func setCustomIconActive(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: customIconActiveKey)
    }
} 
