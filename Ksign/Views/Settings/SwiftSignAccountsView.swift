//
//  SwiftSignAccountsView.swift
//  Ksign
//
//  SwiftSign Accounts - Shows registered UDIDs with 365 day expiry
//

import SwiftUI

struct SwiftSignAccountsView: View {
    @StateObject private var accountService = SwiftSignAccountService.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            // Account Info Section
            Section {
                if accountService.isLoggedIn {
                    _loggedInAccountView()
                } else {
                    _loggedOutAccountView()
                }
            } header: {
                Label("Account", systemImage: "person.circle")
            }
            
            // Registered UDIDs Section
            if accountService.isLoggedIn {
                Section {
                    if accountService.registeredDevices.isEmpty {
                        _emptyDevicesView()
                    } else {
                        ForEach(accountService.registeredDevices) { device in
                            _deviceRow(device)
                        }
                    }
                } header: {
                    HStack {
                        Label("Registered Devices", systemImage: "iphone")
                        Spacer()
                        Text("\(accountService.registeredDevices.count) device(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Each device registration lasts 365 days from the date of registration.")
                }
                
                // Add Current Device Section
                Section {
                    Button {
                        _registerCurrentDevice()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Register This Device")
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isLoading || _isCurrentDeviceRegistered())
                } footer: {
                    if _isCurrentDeviceRegistered() {
                        Text("✓ This device is already registered.")
                            .foregroundColor(.green)
                    } else {
                        Text("Register this device to your SwiftSign account.")
                    }
                }
            }
        }
        .navigationTitle("SwiftSign Accounts")
        .onAppear {
            accountService.loadRegisteredDevices()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Logged In View
    @ViewBuilder
    private func _loggedInAccountView() -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(accountService.userEmail?.prefix(1).uppercased() ?? "S")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(accountService.userName ?? "SwiftSign User")
                    .font(.headline)
                Text(accountService.userEmail ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        
        // Sign Out Button
        Button(role: .destructive) {
            accountService.signOut()
        } label: {
            HStack {
                Spacer()
                Text("Sign Out")
                Spacer()
            }
        }
    }
    
    // MARK: - Logged Out View
    @ViewBuilder
    private func _loggedOutAccountView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Not Signed In")
                .font(.headline)
            
            Text("Sign in to your SwiftSign account to view your registered devices.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                // Open purchase website
                if let url = URL(string: "https://swiftsigner-pro.vercel.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Create Account / Sign In")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Empty Devices View
    @ViewBuilder
    private func _emptyDevicesView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Devices Registered")
                .font(.headline)
            
            Text("Register your devices to use SwiftSigner Pro features.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: - Device Row
    @ViewBuilder
    private func _deviceRow(_ device: RegisteredDevice) -> some View {
        HStack(spacing: 14) {
            // Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(device.isExpired ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: device.deviceType == "iPad" ? "ipad" : "iphone")
                    .font(.title2)
                    .foregroundColor(device.isExpired ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.deviceName ?? "Unknown Device")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if device.isCurrentDevice {
                        Text("This Device")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                // UDID (truncated)
                Text(device.udid.prefix(8) + "..." + device.udid.suffix(4))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
                
                // Expiry info
                HStack(spacing: 4) {
                    if device.isExpired {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("Expired \(device.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(device.daysRemaining) days remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            if device.isExpired {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    private func _isCurrentDeviceRegistered() -> Bool {
        let currentUDID = UDIDService.shared.getUDID()
        return accountService.registeredDevices.contains { $0.udid == currentUDID }
    }
    
    private func _registerCurrentDevice() {
        isLoading = true
        
        Task {
            do {
                try await accountService.registerCurrentDevice()
                await MainActor.run {
                    isLoading = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Registered Device Model
struct RegisteredDevice: Identifiable {
    let id: String
    let udid: String
    let deviceName: String?
    let deviceType: String
    let registrationDate: Date
    let expiryDate: Date
    
    var isExpired: Bool {
        Date() > expiryDate
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return max(0, components.day ?? 0)
    }
    
    var isCurrentDevice: Bool {
        udid == UDIDService.shared.getUDID()
    }
}

// MARK: - SwiftSign Account Service
class SwiftSignAccountService: ObservableObject {
    static let shared = SwiftSignAccountService()
    
    @Published var isLoggedIn: Bool = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var registeredDevices: [RegisteredDevice] = []
    
    private let supabaseURL = "https://eyufnmqchlgiqnesgsdi.supabase.co"
    private let supabaseKey = "sb_publishable_o8Svinw36oSV1eXXpyyEJQ_VTAEoxnR"
    
    private init() {
        loadUserSession()
    }
    
    func loadUserSession() {
        // Check if user is logged in from UserDefaults
        isLoggedIn = UserDefaults.standard.bool(forKey: "SwiftSign.isLoggedIn")
        userEmail = UserDefaults.standard.string(forKey: "SwiftSign.userEmail")
        userName = UserDefaults.standard.string(forKey: "SwiftSign.userName")
    }
    
    func signOut() {
        UserDefaults.standard.set(false, forKey: "SwiftSign.isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "SwiftSign.userEmail")
        UserDefaults.standard.removeObject(forKey: "SwiftSign.userName")
        
        isLoggedIn = false
        userEmail = nil
        userName = nil
        registeredDevices = []
    }
    
    func loadRegisteredDevices() {
        guard isLoggedIn, let email = userEmail else { return }
        
        // Fetch devices from Supabase for this account
        Task {
            do {
                let devices = try await fetchDevicesFromSupabase(email: email)
                await MainActor.run {
                    self.registeredDevices = devices
                }
            } catch {
                print("Failed to load devices: \(error)")
            }
        }
    }
    
    private func fetchDevicesFromSupabase(email: String) async throws -> [RegisteredDevice] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/registered_udids?email=eq.\(email)&select=*") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return json.compactMap { item -> RegisteredDevice? in
            guard let udid = item["udid"] as? String,
                  let registeredAtString = item["registered_at"] as? String else {
                return nil
            }
            
            let formatter = ISO8601DateFormatter()
            let registrationDate = formatter.date(from: registeredAtString) ?? Date()
            let expiryDate = Calendar.current.date(byAdding: .day, value: 365, to: registrationDate) ?? Date()
            
            return RegisteredDevice(
                id: udid,
                udid: udid,
                deviceName: item["device_name"] as? String,
                deviceType: item["device_type"] as? String ?? "iPhone",
                registrationDate: registrationDate,
                expiryDate: expiryDate
            )
        }
    }
    
    func registerCurrentDevice() async throws {
        guard let email = userEmail else {
            throw NSError(domain: "SwiftSign", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }
        
        let udid = UDIDService.shared.getUDID()
        let deviceName = UIDevice.current.name
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/registered_udids") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "udid": udid,
            "email": email,
            "device_name": deviceName,
            "device_type": deviceType,
            "registered_at": ISO8601DateFormatter().string(from: Date()),
            "is_free_preorder": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 409 else {
            throw NSError(domain: "SwiftSign", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to register device"])
        }
        
        // Reload devices
        loadRegisteredDevices()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SwiftSignAccountsView()
    }
}
