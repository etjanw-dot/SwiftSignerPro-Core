//
//  AutoSignQuickView.swift
//  SwiftSigner Pro
//
//  Quick modal to enable/disable and configure auto-sign settings
//

import SwiftUI
import NimbleViews

struct AutoSignQuickView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var _autoSignEnabled: Bool = UserDefaults.standard.bool(forKey: "ksign.autoSignEnabled")
	@State private var _autoInjectTweaks: Bool = UserDefaults.standard.bool(forKey: "ksign.autoInjectTweaks")
	@State private var _autoChangeName: Bool = UserDefaults.standard.bool(forKey: "ksign.autoChangeName")
	@State private var _autoChangeBundleId: Bool = UserDefaults.standard.bool(forKey: "ksign.autoChangeBundleId")
	@State private var _autoPPQProtection: Bool = UserDefaults.standard.bool(forKey: "ksign.autoPPQProtection")
	@State private var _customNameSuffix: String = UserDefaults.standard.string(forKey: "ksign.customNameSuffix") ?? ""
	@State private var _customBundleIdSuffix: String = UserDefaults.standard.string(forKey: "ksign.customBundleIdSuffix") ?? ""
	
	var body: some View {
		NBNavigationView(.localized("Quick Auto-Sign"), displayMode: .inline) {
			Form {
				// Master Toggle Section
				Section {
					Toggle(isOn: $_autoSignEnabled) {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Enable Auto-Sign"))
									.fontWeight(.semibold)
								Text(.localized("Automatically sign apps when imported"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
						} icon: {
							Image(systemName: "wand.and.stars")
								.foregroundColor(.purple)
						}
					}
					.onChange(of: _autoSignEnabled) { newValue in
						UserDefaults.standard.set(newValue, forKey: "ksign.autoSignEnabled")
					}
				} header: {
					HStack {
						Image(systemName: "bolt.fill")
							.foregroundColor(.orange)
						Text(.localized("Auto-Sign"))
					}
				}
				
				if _autoSignEnabled {
					// Quick Settings Section
					Section {
						Toggle(.localized("Modify App Name"), isOn: $_autoChangeName)
							.onChange(of: _autoChangeName) { newValue in
								UserDefaults.standard.set(newValue, forKey: "ksign.autoChangeName")
							}
						
						if _autoChangeName {
							HStack {
								Text(.localized("Suffix"))
								Spacer()
								TextField("(Signed)", text: $_customNameSuffix)
									.textFieldStyle(.roundedBorder)
									.frame(maxWidth: 120)
									.multilineTextAlignment(.trailing)
									.onChange(of: _customNameSuffix) { newValue in
										UserDefaults.standard.set(newValue, forKey: "ksign.customNameSuffix")
									}
							}
						}
						
						Toggle(.localized("Modify Bundle ID"), isOn: $_autoChangeBundleId)
							.onChange(of: _autoChangeBundleId) { newValue in
								UserDefaults.standard.set(newValue, forKey: "ksign.autoChangeBundleId")
							}
						
						if _autoChangeBundleId {
							HStack {
								Text(.localized("Suffix"))
								Spacer()
								TextField(".signed", text: $_customBundleIdSuffix)
									.textFieldStyle(.roundedBorder)
									.frame(maxWidth: 120)
									.multilineTextAlignment(.trailing)
									.onChange(of: _customBundleIdSuffix) { newValue in
										UserDefaults.standard.set(newValue, forKey: "ksign.customBundleIdSuffix")
									}
							}
						}
					} header: {
						Text(.localized("App Info"))
					}
					
					Section {
						Toggle(isOn: $_autoInjectTweaks) {
							Label {
								Text(.localized("Inject Saved Tweaks"))
							} icon: {
								Image(systemName: "puzzlepiece.extension.fill")
									.foregroundColor(.purple)
							}
						}
						.onChange(of: _autoInjectTweaks) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoInjectTweaks")
						}
						
						Toggle(isOn: $_autoPPQProtection) {
							Label {
								Text(.localized("Enable PPQ Protection"))
							} icon: {
								Image(systemName: "shield.fill")
									.foregroundColor(.green)
							}
						}
						.onChange(of: _autoPPQProtection) { newValue in
							UserDefaults.standard.set(newValue, forKey: "ksign.autoPPQProtection")
						}
					} header: {
						Text(.localized("Features"))
					}
				}
				
				// Current Status Section
				Section {
					HStack {
						Text(.localized("Status"))
						Spacer()
						HStack(spacing: 4) {
							Image(systemName: _autoSignEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
								.font(.caption)
							Text(_autoSignEnabled ? .localized("Active") : .localized("Disabled"))
								.font(.caption)
								.fontWeight(.medium)
						}
						.foregroundColor(_autoSignEnabled ? .green : .secondary)
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(
							Capsule()
								.fill(_autoSignEnabled ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
						)
					}
					
					// Link to full settings
					NavigationLink {
						AutoSignView()
					} label: {
						Label {
							Text(.localized("All Auto-Sign Settings"))
						} icon: {
							Image(systemName: "slider.horizontal.3")
								.foregroundColor(.accentColor)
						}
					}
				} header: {
					Text(.localized("More"))
				}
			}
			.toolbar {
				NBToolbarButton(role: .dismiss)
				
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						_resetAll()
					} label: {
						Text(.localized("Reset"))
							.foregroundColor(.orange)
					}
				}
			}
		}
	}
	
	private func _resetAll() {
		_autoSignEnabled = false
		_autoInjectTweaks = false
		_autoChangeName = false
		_autoChangeBundleId = false
		_autoPPQProtection = false
		_customNameSuffix = ""
		_customBundleIdSuffix = ""
		
		UserDefaults.standard.set(false, forKey: "ksign.autoSignEnabled")
		UserDefaults.standard.set(false, forKey: "ksign.autoInjectTweaks")
		UserDefaults.standard.set(false, forKey: "ksign.autoChangeName")
		UserDefaults.standard.set(false, forKey: "ksign.autoChangeBundleId")
		UserDefaults.standard.set(false, forKey: "ksign.autoPPQProtection")
		UserDefaults.standard.set("", forKey: "ksign.customNameSuffix")
		UserDefaults.standard.set("", forKey: "ksign.customBundleIdSuffix")
	}
}

#Preview {
	AutoSignQuickView()
}
