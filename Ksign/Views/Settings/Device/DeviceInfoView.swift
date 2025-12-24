//
//  DeviceInfoView.swift
//  Ksign
//
//  Device information and UDID configuration settings
//

import SwiftUI
import NimbleViews

struct DeviceInfoView: View {
    @StateObject private var udidManager = UDIDManager.shared
    @State private var showUDIDEditor = false
    @State private var editableUDID = ""
    @State private var showResetConfirmation = false
    @State private var copiedItem: String? = nil
    
    var body: some View {
        Form {
            // Device Info Section with green accent
            Section {
                _deviceInfoRow(
                    icon: "iphone",
                    iconColor: .green,
                    title: .localized("Device Name"),
                    value: UIDevice.current.name
                )
                
                _deviceInfoRow(
                    icon: "cpu",
                    iconColor: .green,
                    title: .localized("Model"),
                    value: _deviceModel
                )
                
                _deviceInfoRow(
                    icon: "apple.logo",
                    iconColor: .green,
                    title: .localized("iOS Version"),
                    value: UIDevice.current.systemVersion
                )
                
                _deviceInfoRow(
                    icon: "memorychip",
                    iconColor: .green,
                    title: .localized("System Name"),
                    value: UIDevice.current.systemName
                )
                
                _deviceInfoRow(
                    icon: "rectangle.portrait",
                    iconColor: .green,
                    title: .localized("Device Type"),
                    value: UIDevice.current.userInterfaceIdiom == .phone ? "iPhone" : "iPad"
                )
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3")
                        .foregroundColor(.green)
                    Text(.localized("Device Information"))
                }
            }
            
            // UDID Section
            Section {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "number.square")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("UDID"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(_currentUDID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Copy button
                    Button {
                        UIPasteboard.general.string = _currentUDID
                        withAnimation(.spring(response: 0.3)) {
                            copiedItem = "udid"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { copiedItem = nil }
                        }
                    } label: {
                        Image(systemName: copiedItem == "udid" ? "checkmark.circle.fill" : "doc.on.clipboard")
                            .font(.title3)
                            .foregroundColor(copiedItem == "udid" ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Edit UDID Button
                Button {
                    editableUDID = _currentUDID
                    showUDIDEditor = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.green)
                        Text(.localized("Configure UDID"))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Get UDID from Web Button
                Button {
                    openUDIDWebsite()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.accentColor)
                        Text(.localized("Get UDID from Web"))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.green)
                    Text(.localized("Device Identifier"))
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("The UDID is used for certificate verification and device whitelisting."))
                    Text(.localized("Tap 'Get UDID from Web' to automatically retrieve your true device UDID."))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Verification Status Section
            Section {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(udidManager.isVerified ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: udidManager.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.body)
                            .foregroundColor(udidManager.isVerified ? .green : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Verification Status"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(udidManager.isVerified ? .localized("Verified") : .localized("Not Verified"))
                            .font(.caption)
                            .foregroundColor(udidManager.isVerified ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    if !udidManager.isVerified {
                        Button {
                            udidManager.showVerificationSheet = true
                        } label: {
                            Text(.localized("Verify"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.green)
                    Text(.localized("Status"))
                }
            }
            
            // Actions Section
            Section {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                        Text(.localized("Reset UDID Verification"))
                            .foregroundColor(.primary)
                    }
                }
                
                Button(role: .destructive) {
                    clearAllDeviceData()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text(.localized("Clear Device Data"))
                            .foregroundColor(.red)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .foregroundColor(.green)
                    Text(.localized("Actions"))
                }
            } footer: {
                Text(.localized("Reset verification to re-enter your UDID. Clear data removes all stored device information."))
            }
            
            // Additional Device Details
            Section {
                _deviceInfoRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: .localized("Locale"),
                    value: Locale.current.identifier
                )
                
                _deviceInfoRow(
                    icon: "clock",
                    iconColor: .blue,
                    title: .localized("Timezone"),
                    value: TimeZone.current.identifier
                )
                
                _deviceInfoRow(
                    icon: "battery.100",
                    iconColor: .blue,
                    title: .localized("Battery State"),
                    value: _batteryState
                )
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.accentColor)
                    Text(.localized("Additional Info"))
                }
            }
        }
        .navigationTitle(.localized("Device Info"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(.localized("Configure UDID"), isPresented: $showUDIDEditor) {
            TextField(.localized("Enter UDID"), text: $editableUDID)
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Save")) {
                saveUDID()
            }
        } message: {
            Text(.localized("Enter your device UDID for verification."))
        }
        .alert(.localized("Reset Verification?"), isPresented: $showResetConfirmation) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                udidManager.resetVerification()
            }
        } message: {
            Text(.localized("This will clear your verified UDID. You'll need to verify again."))
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func _deviceInfoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Computed Properties
    private var _currentUDID: String {
        if let udid = UserDefaults.standard.string(forKey: "SwiftSignerPro.verifiedUDID") {
            return udid
        }
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    private var _deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return _mapToDeviceName(identifier)
    }
    
    private var _batteryState: String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100)
        let state: String
        switch UIDevice.current.batteryState {
        case .charging: state = "Charging"
        case .full: state = "Full"
        case .unplugged: state = "Unplugged"
        default: state = "Unknown"
        }
        return level >= 0 ? "\(level)% (\(state))" : state
    }
    
    // MARK: - Functions
    private func saveUDID() {
        let cleanUDID = editableUDID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUDID.isEmpty else { return }
        
        UserDefaults.standard.set(cleanUDID.uppercased(), forKey: "SwiftSignerPro.verifiedUDID")
        udidManager.checkVerification()
    }
    
    private func clearAllDeviceData() {
        UserDefaults.standard.removeObject(forKey: "SwiftSignerPro.verifiedUDID")
        udidManager.resetVerification()
    }
    
    /// Opens the UDID retrieval website in Safari
    /// The website uses a configuration profile to get the true device UDID
    /// and returns it to the app via the ksign:// URL scheme
    private func openUDIDWebsite() {
        UDIDService.shared.openUDIDWebsite()
    }
    
    private func _mapToDeviceName(_ identifier: String) -> String {
        switch identifier {
        // iPhone models
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        // iPad models
        case "iPad13,1", "iPad13,2": return "iPad Air (4th gen)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th gen)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th gen)"
        // Simulator
        case "x86_64", "arm64": return "Simulator"
        default: return identifier
        }
    }
}

#Preview {
    NavigationStack {
        DeviceInfoView()
    }
}
