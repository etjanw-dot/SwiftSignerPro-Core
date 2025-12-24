//
//  AppearanceView.swift
//  Feather
//
//  Created by samara on 7.05.2025.
//

import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct AppearanceView: View {
    @AppStorage("Feather.userInterfaceStyle") private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    
	@AppStorage("Feather.libraryCellAppearance") private var _libraryCellAppearance: Int = 0
	
	private let _libraryCellAppearanceMethods: [String] = [
		.localized("Standard"),
		.localized("Pill")
	]
	
	@AppStorage("Feather.storeCellAppearance") private var _storeCellAppearance: Int = 1
	
	private let _storeCellAppearanceMethods: [String] = [
		.localized("Standard"),
		.localized("Big Description")
	]
	
	@AppStorage("Feather.accentColor") private var _selectedAccentColor: Int = 0
	@StateObject private var accentColorManager = AccentColorManager.shared
	
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
    private var _ignoreSolariumLinkedOnCheck: Bool = false
    
	private let _accentColors: [(name: String, color: Color)] = [
		(.localized("Default"), Color(red: 0x53/255, green: 0x94/255, blue: 0xF7/255)),
		(.localized("Cherry"), Color(red: 0xFF/255, green: 0x8B/255, blue: 0x92/255)),
		(.localized("Red"), .red),
		(.localized("Orange"), .orange),
		(.localized("Yellow"), .yellow),
		(.localized("Green"), .green),
		(.localized("Blue"), .blue),
		(.localized("Purple"), .purple),
		(.localized("Pink"), .pink),
		(.localized("Indigo"), .indigo),
		(.localized("Mint"), .mint),
		(.localized("Cyan"), .cyan),
		(.localized("Teal"), .teal)
	]
	
	private var currentAccentColor: Color {
		accentColorManager.currentAccentColor
	}
	
	// MARK: - Theme Customization
	@ObservedObject private var themeManager = ThemeManager.shared
	@State private var expandedElement: ThemeElement?
	@State private var showPresetSheet = false
	@State private var showResetAlert = false
	@State private var showSavePresetSheet = false
	@State private var showImportPicker = false
	@State private var showExportSheet = false
	@StateObject private var presetManager = UserPresetManager.shared

    var body: some View {
        NBList(.localized("Appearance")) {
            
            Section {
                Picker(.localized("Appearance"), selection: $_userIntefacerStyle) {
                    ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                        Text(style.label).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            NBSection(.localized("Experiments")) {
                Toggle(.localized("Enable Liquid Glass"), isOn: $_ignoreSolariumLinkedOnCheck)
            } footer: {
                Text(.localized("This enables liquid glass for this app, this requires a restart of the app to take effect."))
            }
			
			NBSection(.localized("Sources")) {
                _storePreview()
				Picker(.localized("Store Cell Appearance"), selection: $_storeCellAppearance) {
					ForEach(_storeCellAppearanceMethods.indices, id: \.description) { index in
						Text(_storeCellAppearanceMethods[index]).tag(index)
					}
				}
				.pickerStyle(.inline)
                .labelsHidden()
			}
			
			NBSection(.localized("Accent Color")) {
				_accentColorPreview()
				Picker(.localized("Accent Color"), selection: $_selectedAccentColor) {
					ForEach(_accentColors.indices, id: \.description) { index in
						HStack {
							Circle()
								.fill(_accentColors[index].color)
								.frame(width: 20, height: 20)
							Text(_accentColors[index].name)
						}
						.tag(index)
					}
				}
				.pickerStyle(.inline)
				.labelsHidden()
			}
			
			// MARK: - Theme Customization Section
			Section {
				Toggle(.localized("Enable Custom Theme"), isOn: $themeManager.useCustomTheme)
				
				// Big Apply Theme Button
				if themeManager.useCustomTheme {
					Button {
						themeManager.applyTheme()
						// Haptic feedback
						let generator = UIImpactFeedbackGenerator(style: .medium)
						generator.impactOccurred()
					} label: {
						HStack {
							Spacer()
							Image(systemName: "paintbrush.fill")
							Text(.localized("Apply Theme"))
								.fontWeight(.semibold)
							Spacer()
						}
						.foregroundColor(.white)
						.padding(.vertical, 12)
						.background(
							LinearGradient(
								colors: [currentAccentColor, currentAccentColor.opacity(0.7)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(10)
					}
					.buttonStyle(.plain)
				}
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
        .onChange(of: _userIntefacerStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
		.onChange(of: _selectedAccentColor) { _ in
			accentColorManager.updateGlobalTintColor()
		}
        .onChange(of: _ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
		.sheet(isPresented: $showPresetSheet) {
			PresetThemesSheet(themeManager: themeManager)
		}
		.sheet(isPresented: $showSavePresetSheet) {
			SavePresetSheet(presetManager: presetManager)
		}
		.sheet(isPresented: $showImportPicker) {
			DocumentPicker(contentTypes: [.json, .data]) { url in
				_ = presetManager.importPreset(from: url)
			}
		}
		.sheet(isPresented: $showExportSheet) {
			if let url = presetManager.exportAllPresets() {
				ShareSheet(activityItems: [url])
			}
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
	
	@ViewBuilder
	private func _libraryPreview() -> some View {
		HStack(spacing: 9) {
			// Check for custom icon first
			if CustomAppIconManager.shared.isCustomIconActive(),
			   let customIcon = CustomAppIconManager.shared.loadCustomIcon() {
				Image(uiImage: customIcon)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: 57, height: 57)
					.clipShape(RoundedRectangle(cornerRadius: 12))
			} else {
				Image(uiImage: (UIImage(named: Bundle.main.iconFileName ?? ""))! )
					.appIconStyle(size: 57)
			}
			
			NBTitleWithSubtitleView(
				title: Bundle.main.name,
				subtitle: "\(Bundle.main.version ?? "1.0") • \(Bundle.main.bundleIdentifier ?? "")",
				linelimit: 0
			)
			
			FRExpirationPillView(
				title: .localized("Install"),
				showOverlay: _libraryCellAppearance == 0,
				expiration: Date.now.expirationInfo()
			).animation(.spring, value: _libraryCellAppearance)
		}
	}
    
    @ViewBuilder
    private func _storePreview() -> some View {
        VStack {
            HStack(spacing: 9) {
                // Check for custom icon first
                if CustomAppIconManager.shared.isCustomIconActive(),
                   let customIcon = CustomAppIconManager.shared.loadCustomIcon() {
                    Image(uiImage: customIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 57, height: 57)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(uiImage: (UIImage(named: Bundle.main.iconFileName ?? ""))! )
                        .appIconStyle(size: 57)
                }
                
                NBTitleWithSubtitleView(
                    title: Bundle.main.name,
                    subtitle: "\(Bundle.main.version ?? "1.0") • " + .localized("An awesome application"),
                    linelimit: 0
                )
            }
            
            if _storeCellAppearance != 0 {
                Text(.localized("An awesome application"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(18)
                    .padding(.top, 2)
            }
        }
        .animation(.spring, value: _storeCellAppearance)
    }
	
	@ViewBuilder
	private func _accentColorPreview() -> some View {
		HStack(spacing: 9) {
			Circle()
				.fill(currentAccentColor)
				.frame(width: 57, height: 57)
			
			NBTitleWithSubtitleView(
				title: .localized("Accent Color"),
				subtitle: .localized("This is the current accent color"),
				linelimit: 0
			)
		}
	}
}
