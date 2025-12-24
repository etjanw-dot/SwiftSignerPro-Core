//
//  TweakStatusBarView.swift
//  Ksign
//
//  Status Bar customization tweaks.
//

#if os(iOS)
import SwiftUI

struct TweakStatusBarView: View {
    // Carrier Settings
    @State private var customCarrier: Bool = false
    @State private var carrierText: String = ""
    
    // Time Settings
    @State private var customTime: Bool = false
    @State private var timeText: String = ""
    
    // Battery Settings
    @State private var customBattery: Bool = false
    @State private var batteryCapacity: Double = 100
    @State private var showBatteryDetail: Bool = false
    
    // Signal Settings
    @State private var customSignal: Bool = false
    @State private var signalBars: Int = 4
    
    // WiFi Settings
    @State private var customWiFi: Bool = false
    @State private var wifiBars: Int = 3
    
    // Visibility Settings
    @State private var hideDND: Bool = false
    @State private var hideAirplane: Bool = false
    @State private var hideWiFi: Bool = false
    @State private var hideBattery: Bool = false
    @State private var hideBluetooth: Bool = false
    @State private var hideAlarm: Bool = false
    @State private var hideLocation: Bool = false
    @State private var hideRotationLock: Bool = false
    @State private var hideVPN: Bool = false
    
    var body: some View {
        List {
            // Carrier Section
            carrierSection
            
            // Time Section
            timeSection
            
            // Battery Section
            batterySection
            
            // Signal Section
            signalSection
            
            // WiFi Section
            wifiSection
            
            // Hide Elements Section
            hideElementsSection
            
            // Info Section
            infoSection
        }
        .navigationTitle(.localized("Status Bar"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Carrier Section
    
    private var carrierSection: some View {
        Section {
            Toggle(.localized("Custom Carrier Text"), isOn: $customCarrier)
            
            if customCarrier {
                TextField(.localized("Carrier Name"), text: $carrierText)
                    .textFieldStyle(.roundedBorder)
            }
        } header: {
            Label(.localized("Carrier"), systemImage: "antenna.radiowaves.left.and.right")
        }
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        Section {
            Toggle(.localized("Custom Time Text"), isOn: $customTime)
            
            if customTime {
                TextField(.localized("Time Text"), text: $timeText)
                    .textFieldStyle(.roundedBorder)
            }
        } header: {
            Label(.localized("Time"), systemImage: "clock.fill")
        }
    }
    
    // MARK: - Battery Section
    
    private var batterySection: some View {
        Section {
            Toggle(.localized("Custom Battery Level"), isOn: $customBattery)
            
            if customBattery {
                VStack(alignment: .leading) {
                    HStack {
                        Text(.localized("Battery"))
                        Spacer()
                        Text("\(Int(batteryCapacity))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $batteryCapacity, in: 0...100, step: 1)
                        .accentColor(.green)
                }
                
                Toggle(.localized("Show Battery Detail"), isOn: $showBatteryDetail)
            }
        } header: {
            Label(.localized("Battery"), systemImage: "battery.100")
        }
    }
    
    // MARK: - Signal Section
    
    private var signalSection: some View {
        Section {
            Toggle(.localized("Custom Signal Bars"), isOn: $customSignal)
            
            if customSignal {
                Stepper(value: $signalBars, in: 0...4) {
                    HStack {
                        Text(.localized("Signal Bars"))
                        Spacer()
                        Text("\(signalBars)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label(.localized("Cellular"), systemImage: "cellularbars")
        }
    }
    
    // MARK: - WiFi Section
    
    private var wifiSection: some View {
        Section {
            Toggle(.localized("Custom WiFi Bars"), isOn: $customWiFi)
            
            if customWiFi {
                Stepper(value: $wifiBars, in: 0...3) {
                    HStack {
                        Text(.localized("WiFi Bars"))
                        Spacer()
                        Text("\(wifiBars)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label(.localized("WiFi"), systemImage: "wifi")
        }
    }
    
    // MARK: - Hide Elements Section
    
    private var hideElementsSection: some View {
        Section {
            Toggle(.localized("Hide Do Not Disturb"), isOn: $hideDND)
            Toggle(.localized("Hide Airplane Mode"), isOn: $hideAirplane)
            Toggle(.localized("Hide WiFi Icon"), isOn: $hideWiFi)
            Toggle(.localized("Hide Battery Icon"), isOn: $hideBattery)
            Toggle(.localized("Hide Bluetooth"), isOn: $hideBluetooth)
            Toggle(.localized("Hide Alarm"), isOn: $hideAlarm)
            Toggle(.localized("Hide Location"), isOn: $hideLocation)
            Toggle(.localized("Hide Rotation Lock"), isOn: $hideRotationLock)
            Toggle(.localized("Hide VPN"), isOn: $hideVPN)
        } header: {
            Label(.localized("Hide Elements"), systemImage: "eye.slash.fill")
        } footer: {
            Text(.localized("Toggle which status bar icons to hide."))
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Requires Nugget"))
                        .font(.subheadline.weight(.medium))
                    Text(.localized("Status bar tweaks require Nugget to apply. Configure your preferences, then use Nugget to apply changes."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        TweakStatusBarView()
    }
}
#endif
