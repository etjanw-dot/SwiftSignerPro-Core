//
//  ThemeCustomizationView.swift
//  Ksign
//
//  Custom theme color picker for all UI elements.
//

import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - Theme Customization View
struct ThemeCustomizationView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var expandedElement: ThemeElement?
    @State private var showPresetSheet = false
    @State private var showResetAlert = false
    
    var body: some View {
        NBList(.localized("Theme Customization")) {
            // Enable/Disable Custom Theme
            Section {
                Toggle(.localized("Enable Custom Theme"), isOn: $themeManager.useCustomTheme)
            } footer: {
                Text(.localized("When enabled, your custom colors will be applied throughout the app."))
            }
            
            if themeManager.useCustomTheme {
                // Preset Themes Section
                Section {
                    Button {
                        showPresetSheet = true
                    } label: {
                        HStack {
                            Label(.localized("Apply Preset Theme"), systemImage: "paintpalette.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label(.localized("Reset All Colors"), systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text(.localized("Quick Actions"))
                }
                
                // Primary Colors
                NBSection(.localized("Primary Colors")) {
                    ColorPickerRow(element: .accentColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .buttonColor, themeManager: themeManager, expandedElement: $expandedElement)
                }
                
                // Background Colors
                NBSection(.localized("Background Colors")) {
                    ColorPickerRow(element: .backgroundColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .secondaryBackgroundColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .cardBackgroundColor, themeManager: themeManager, expandedElement: $expandedElement)
                }
                
                // Text Colors
                NBSection(.localized("Text Colors")) {
                    ColorPickerRow(element: .primaryTextColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .secondaryTextColor, themeManager: themeManager, expandedElement: $expandedElement)
                }
                
                // Navigation Colors
                NBSection(.localized("Navigation Colors")) {
                    ColorPickerRow(element: .navigationBarColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .tabBarColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .borderColor, themeManager: themeManager, expandedElement: $expandedElement)
                }
                
                // Status Colors
                NBSection(.localized("Status Colors")) {
                    ColorPickerRow(element: .successColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .warningColor, themeManager: themeManager, expandedElement: $expandedElement)
                    ColorPickerRow(element: .errorColor, themeManager: themeManager, expandedElement: $expandedElement)
                }
            }
        }
        .sheet(isPresented: $showPresetSheet) {
            PresetThemesSheet(themeManager: themeManager)
        }
        .alert(.localized("Reset All Colors"), isPresented: $showResetAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                themeManager.resetAllColors()
            }
        } message: {
            Text(.localized("This will reset all custom colors to their default values. This action cannot be undone."))
        }
        .animation(.spring(response: 0.3), value: themeManager.useCustomTheme)
    }
}

// MARK: - Color Picker Row with Modern Design
struct ColorPickerRow: View {
    let element: ThemeElement
    @ObservedObject var themeManager: ThemeManager
    @Binding var expandedElement: ThemeElement?
    
    @State private var tempColor: Color
    @State private var originalColor: Color
    @State private var hexInput: String = ""
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    
    init(element: ThemeElement, themeManager: ThemeManager, expandedElement: Binding<ThemeElement?>) {
        self.element = element
        self.themeManager = themeManager
        self._expandedElement = expandedElement
        let currentColor = themeManager.color(for: element)
        self._tempColor = State(initialValue: currentColor)
        self._originalColor = State(initialValue: currentColor)
    }
    
    var isExpanded: Bool {
        expandedElement == element
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row - Collapsed View
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedElement = nil
                    } else {
                        expandedElement = element
                        let currentColor = themeManager.color(for: element)
                        tempColor = currentColor
                        originalColor = currentColor
                        hexInput = tempColor.toHex()
                        extractHSB(from: currentColor)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    // Color Preview Circle with glow
                    Circle()
                        .fill(themeManager.color(for: element))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: themeManager.color(for: element).opacity(0.5), radius: 6, x: 0, y: 2)
                    
                    // Element Name and Icon
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: element.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.color(for: element))
                            
                            Text(.localized(element.rawValue))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Text(themeManager.color(for: element).toHex())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(isExpanded ? themeManager.color(for: element) : .secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Color Picker - Clean Modern Design
            if isExpanded {
                VStack(spacing: 20) {
                    // Divider with gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, tempColor.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.top, 12)
                    
                    // Live Preview Cards
                    HStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text(.localized("Current"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(originalColor)
                                .frame(width: 60, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: originalColor.opacity(0.3), radius: 4)
                        }
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 6) {
                            Text(.localized("New"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tempColor)
                                .frame(width: 60, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: tempColor.opacity(0.5), radius: 6)
                        }
                    }
                    
                    // Hue Gradient Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.localized("Color"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: (0...10).map { Color(hue: Double($0) / 10.0, saturation: 1, brightness: 1) },
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 32)
                            
                            // Slider thumb
                            Circle()
                                .fill(Color(hue: hue, saturation: 1, brightness: 1))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .offset(x: CGFloat(hue) * (UIScreen.main.bounds.width - 80) - 14)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let width = UIScreen.main.bounds.width - 80
                                            hue = max(0, min(1, Double(value.location.x / width)))
                                            updateColor()
                                        }
                                )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 4)
                    
                    // Saturation & Brightness Sliders
                    HStack(spacing: 16) {
                        // Saturation
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(.localized("Saturation"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(saturation * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .monospaced()
                            }
                            
                            Slider(value: $saturation, in: 0...1)
                                .tint(tempColor)
                                .onChange(of: saturation) { _ in updateColor() }
                        }
                        
                        // Brightness
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(.localized("Brightness"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(brightness * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .monospaced()
                            }
                            
                            Slider(value: $brightness, in: 0...1)
                                .tint(tempColor)
                                .onChange(of: brightness) { _ in updateColor() }
                        }
                    }
                    
                    // HEX Input with System Picker
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Text("HEX")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("#000000", text: $hexInput)
                                .font(.system(.body, design: .monospaced))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: hexInput) { newValue in
                                    if newValue.count >= 6 {
                                        tempColor = Color(hex: newValue)
                                        extractHSB(from: tempColor)
                                    }
                                }
                        }
                        
                        // System Color Picker
                        ColorPicker("", selection: $tempColor, supportsOpacity: false)
                            .labelsHidden()
                            .scaleEffect(1.3)
                            .onChange(of: tempColor) { newColor in
                                hexInput = newColor.toHex()
                                extractHSB(from: newColor)
                            }
                    }
                    
                    // Quick Color Presets - Larger and cleaner
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(QuickColors.all, id: \.self) { color in
                                Button {
                                    tempColor = color
                                    hexInput = color.toHex()
                                    extractHSB(from: color)
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(tempColor.toHex() == color.toHex() ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(color: color.opacity(0.4), radius: 3)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    
                    // Action Buttons - BIG and Beautiful
                    HStack(spacing: 12) {
                        // Reset Button
                        Button {
                            tempColor = originalColor
                            hexInput = originalColor.toHex()
                            extractHSB(from: originalColor)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(.localized("Reset"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Cancel Button
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                expandedElement = nil
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text(.localized("Cancel"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Apply Button - Primary action, stands out
                        Button {
                            themeManager.setColor(tempColor, for: element)
                            themeManager.applyTheme()
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedElement = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text(.localized("Apply"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [tempColor, tempColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: tempColor.opacity(0.4), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
    
    private func updateColor() {
        tempColor = Color(hue: hue, saturation: saturation, brightness: brightness)
        hexInput = tempColor.toHex()
    }
    
    private func extractHSB(from color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        hue = Double(h)
        saturation = Double(s)
        brightness = Double(b)
    }
}

// MARK: - Color Wheel View
struct ColorWheelView: View {
    @Binding var selectedColor: Color
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var wheelSize: CGFloat = 180
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular Color Wheel
            ZStack {
                // Color wheel gradient
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0, saturation: 1, brightness: brightness),
                                Color(hue: 0.1, saturation: 1, brightness: brightness),
                                Color(hue: 0.2, saturation: 1, brightness: brightness),
                                Color(hue: 0.3, saturation: 1, brightness: brightness),
                                Color(hue: 0.4, saturation: 1, brightness: brightness),
                                Color(hue: 0.5, saturation: 1, brightness: brightness),
                                Color(hue: 0.6, saturation: 1, brightness: brightness),
                                Color(hue: 0.7, saturation: 1, brightness: brightness),
                                Color(hue: 0.8, saturation: 1, brightness: brightness),
                                Color(hue: 0.9, saturation: 1, brightness: brightness),
                                Color(hue: 1, saturation: 1, brightness: brightness)
                            ]),
                            center: .center
                        )
                    )
                    .frame(width: wheelSize, height: wheelSize)
                    .mask(
                        RadialGradient(
                            gradient: Gradient(colors: [.black, .black, .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: wheelSize / 2
                        )
                    )
                    .overlay(
                        // White center for saturation
                        RadialGradient(
                            gradient: Gradient(colors: [.white.opacity(1 - saturation), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: wheelSize / 2
                        )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
                                let vector = CGPoint(
                                    x: value.location.x - center.x,
                                    y: value.location.y - center.y
                                )
                                
                                // Calculate hue from angle
                                let angle = atan2(vector.y, vector.x)
                                hue = (Double(angle) / (2 * .pi) + 0.5).truncatingRemainder(dividingBy: 1.0)
                                if hue < 0 { hue += 1 }
                                
                                // Calculate saturation from distance
                                let distance = sqrt(vector.x * vector.x + vector.y * vector.y)
                                saturation = min(Double(distance / (wheelSize / 2)), 1.0)
                                
                                updateColor()
                            }
                    )
                
                // Selection indicator
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .position(selectorPosition)
            }
            .frame(width: wheelSize, height: wheelSize)
            
            // Brightness Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(.localized("Brightness"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(brightness * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                
                Slider(value: $brightness, in: 0...1)
                    .onChange(of: brightness) { _ in
                        updateColor()
                    }
                    .tint(selectedColor)
            }
            .padding(.horizontal)
            
            // Selected Color Preview
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                
                Text(selectedColor.toHex())
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            extractHSB(from: selectedColor)
        }
        .onChange(of: selectedColor) { newColor in
            extractHSB(from: newColor)
        }
    }
    
    private var selectorPosition: CGPoint {
        let center = wheelSize / 2
        let radius = CGFloat(saturation) * center
        let angle = CGFloat(hue * 2 * .pi - .pi)
        
        return CGPoint(
            x: center + radius * cos(angle),
            y: center + radius * sin(angle)
        )
    }
    
    private func updateColor() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func extractHSB(from color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        hue = Double(h)
        saturation = Double(s)
        brightness = Double(b)
    }
}

// MARK: - Quick Colors
enum QuickColors {
    static let all: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan,
        .blue, .indigo, .purple, .pink, .brown, .gray,
        .white, .black,
        Color(hex: "FF6B6B"), Color(hex: "4ECDC4"), Color(hex: "45B7D1"),
        Color(hex: "96CEB4"), Color(hex: "FFEAA7"), Color(hex: "DDA0DD"),
        Color(hex: "00FF41"), Color(hex: "FF2A6D"), Color(hex: "0ABDC6")
    ]
}

// MARK: - Preset Themes Sheet with User Presets
struct PresetThemesSheet: View {
    @ObservedObject var themeManager: ThemeManager
    @StateObject private var presetManager = UserPresetManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSavePresetSheet = false
    @State private var showImportPicker = false
    @State private var showExportSheet = false
    @State private var selectedPresetToExport: PresetTheme?
    @State private var showDeleteAlert = false
    @State private var presetToDelete: PresetTheme?
    
    var body: some View {
        NavigationView {
            List {
                // Save Current as Preset
                Section {
                    Button {
                        showSavePresetSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text(.localized("Save Current as Preset"))
                        }
                    }
                    
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.accentColor)
                            Text(.localized("Import Preset"))
                        }
                    }
                    
                    if !presetManager.userPresets.isEmpty {
                        Button {
                            showExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.orange)
                                Text(.localized("Export All Presets"))
                            }
                        }
                    }
                } header: {
                    Text(.localized("Actions"))
                }
                
                // User Presets
                if !presetManager.userPresets.isEmpty {
                    Section {
                        ForEach(presetManager.userPresets) { preset in
                            PresetRowView(
                                preset: preset,
                                isUserPreset: true,
                                onApply: {
                                    applyPreset(preset)
                                    dismiss()
                                },
                                onExport: {
                                    selectedPresetToExport = preset
                                },
                                onDelete: {
                                    presetToDelete = preset
                                    showDeleteAlert = true
                                }
                            )
                        }
                    } header: {
                        Text(.localized("Your Presets"))
                    }
                }
                
                // Built-in Presets
                Section {
                    ForEach(PresetTheme.presets) { preset in
                        PresetRowView(
                            preset: preset,
                            isUserPreset: false,
                            onApply: {
                                applyPreset(preset)
                                dismiss()
                            },
                            onExport: nil,
                            onDelete: nil
                        )
                    }
                } header: {
                    Text(.localized("Built-in Themes"))
                }
            }
            .navigationTitle(.localized("Preset Themes"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSavePresetSheet) {
                SavePresetSheet(presetManager: presetManager)
            }
            .sheet(isPresented: $showImportPicker) {
                DocumentPicker(contentTypes: [.json, .data]) { url in
                    _ = presetManager.importPreset(from: url)
                }
            }
            .sheet(item: $selectedPresetToExport) { preset in
                if let url = presetManager.exportPreset(preset) {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = presetManager.exportAllPresets() {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(.localized("Delete Preset"), isPresented: $showDeleteAlert) {
                Button(.localized("Cancel"), role: .cancel) { }
                Button(.localized("Delete"), role: .destructive) {
                    if let preset = presetToDelete {
                        presetManager.deletePreset(preset)
                    }
                }
            } message: {
                Text(.localized("Are you sure you want to delete this preset? This action cannot be undone."))
            }
        }
    }
    
    private func applyPreset(_ preset: PresetTheme) {
        let colors = preset.getColors()
        for (element, color) in colors {
            themeManager.setColor(color, for: element)
        }
        // Apply the theme immediately
        themeManager.applyTheme()
    }
}

// MARK: - Preset Row View
struct PresetRowView: View {
    let preset: PresetTheme
    let isUserPreset: Bool
    let onApply: () -> Void
    let onExport: (() -> Void)?
    let onDelete: (() -> Void)?
    
    var body: some View {
        Button {
            onApply()
        } label: {
            HStack(spacing: 16) {
                // Theme Icon - Now properly applying the preset icon
                ZStack {
                    Circle()
                        .fill(Color(hex: preset.colors[ThemeElement.backgroundColor.rawValue] ?? "000000"))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: preset.colors[ThemeElement.accentColor.rawValue] ?? "0077B6"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(preset.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isUserPreset {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Color Preview Strip
                    HStack(spacing: 2) {
                        ForEach([ThemeElement.accentColor.rawValue, ThemeElement.backgroundColor.rawValue, ThemeElement.primaryTextColor.rawValue, ThemeElement.buttonColor.rawValue], id: \.self) { elementKey in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: preset.colors[elementKey] ?? "808080"))
                                .frame(width: 20, height: 8)
                        }
                    }
                }
                
                Spacer()
                
                if isUserPreset {
                    Menu {
                        Button {
                            onApply()
                        } label: {
                            Label(.localized("Apply"), systemImage: "checkmark.circle")
                        }
                        
                        if let onExport = onExport {
                            Button {
                                onExport()
                            } label: {
                                Label(.localized("Export"), systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                Label(.localized("Delete"), systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Save Preset Sheet
struct SavePresetSheet: View {
    @ObservedObject var presetManager: UserPresetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName: String = ""
    @State private var selectedIcon: String = "paintpalette.fill"
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(.localized("Preset Name"), text: $presetName)
                } header: {
                    Text(.localized("Name"))
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(ThemeIcons.all, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .accentColor : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(.localized("Icon"))
                }
                
                // Preview
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ThemeManager.shared.color(for: .backgroundColor))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(ThemeManager.shared.color(for: .accentColor))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(presetName.isEmpty ? .localized("My Preset") : presetName)
                                .font(.headline)
                            
                            HStack(spacing: 2) {
                                ForEach([ThemeElement.accentColor, .backgroundColor, .primaryTextColor, .buttonColor], id: \.self) { element in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(ThemeManager.shared.color(for: element))
                                        .frame(width: 20, height: 8)
                                }
                            }
                        }
                    }
                } header: {
                    Text(.localized("Preview"))
                }
            }
            .navigationTitle(.localized("Save Preset"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(.localized("Save")) {
                        presetManager.saveCurrentAsPreset(name: presetName.isEmpty ? "My Preset" : presetName, icon: selectedIcon)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            onPick(url)
        }
    }
}
