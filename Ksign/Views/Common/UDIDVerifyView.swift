//
//  UDIDVerifyView.swift
//  Ksign
//
//  UDID verification screen - appears before welcome guide
//

import SwiftUI

struct UDIDVerifyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enteredUDID: String = ""
    @State private var isVerifying: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isVerified: Bool = false
    
    let onVerified: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Swift Icon
            VStack(spacing: 20) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Icon container
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.orange.opacity(0.5), radius: 30, x: 0, y: 15)
                        
                        // Swift bird icon
                        Image(systemName: "swift")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // Title
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("SwiftSigner Pro")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            // Verification Card
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Your Registered UDID")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Enter the UDID you registered during purchase to unlock full access to SwiftSigner Pro.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // UDID Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("00000000-0000000000000000", text: $enteredUDID)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showError ? Color.red : Color.clear, lineWidth: 2)
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Verify Button
                Button {
                    _verifyUDID()
                } label: {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Verify & Continue")
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(enteredUDID.isEmpty || isVerifying)
                .opacity(enteredUDID.isEmpty ? 0.6 : 1.0)
                
                // Get UDID Help Button
                Button {
                    // Directly open UDID retrieval website
                    UDIDService.shared.openUDIDWebsite()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                        Text("Don't know your UDID?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                // Purchase link
                Button {
                    // Open purchase URL
                    if let url = URL(string: "https://swiftsigner-pro.vercel.app") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Get SwiftSigner Pro →")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.orange.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .interactiveDismissDisabled()
    }
    
    private func _verifyUDID() {
        isVerifying = true
        showError = false
        
        // Trim whitespace
        let trimmedUDID = enteredUDID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUDID.isEmpty else {
            isVerifying = false
            showError = true
            errorMessage = "Please enter your UDID"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        // Check Supabase for registered UDID
        let supabaseURL = "https://eyufnmqchlgiqnesgsdi.supabase.co"
        let supabaseKey = "sb_publishable_o8Svinw36oSV1eXXpyyEJQ_VTAEoxnR"
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/registered_udids?udid=eq.\(trimmedUDID)&select=*") else {
            isVerifying = false
            showError = true
            errorMessage = "Invalid UDID format"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isVerifying = false
                
                if let error = error {
                    showError = true
                    errorMessage = "Network error: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    return
                }
                
                guard let data = data else {
                    showError = true
                    errorMessage = "No response from server"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    return
                }
                
                // Parse response - if array is not empty, UDID is registered
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        if !json.isEmpty {
                            // UDID found in database - verified!
                            UserDefaults.standard.set(trimmedUDID, forKey: "SwiftSignerPro.verifiedUDID")
                            UserDefaults.standard.set(true, forKey: "SwiftSignerPro.isUDIDVerified")
                            
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onVerified()
                        } else {
                            // UDID not found
                            showError = true
                            errorMessage = "This UDID is not registered. Please pre-order first."
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } else {
                        showError = true
                        errorMessage = "Invalid response from server"
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                } catch {
                    showError = true
                    errorMessage = "Failed to verify: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }.resume()
    }
}

// MARK: - UDID Verification Manager
class UDIDVerificationManager: ObservableObject {
    static let shared = UDIDVerificationManager()
    
    @Published var isVerified: Bool = false
    @Published var verifiedUDID: String? = nil
    
    private let verifiedKey = "SwiftSignerPro.isUDIDVerified"
    private let udidKey = "SwiftSignerPro.verifiedUDID"
    
    init() {
        isVerified = UserDefaults.standard.bool(forKey: verifiedKey)
        verifiedUDID = UserDefaults.standard.string(forKey: udidKey)
    }
    
    func markVerified(udid: String) {
        UserDefaults.standard.set(true, forKey: verifiedKey)
        UserDefaults.standard.set(udid, forKey: udidKey)
        isVerified = true
        verifiedUDID = udid
    }
    
    func resetVerification() {
        UserDefaults.standard.set(false, forKey: verifiedKey)
        UserDefaults.standard.removeObject(forKey: udidKey)
        isVerified = false
        verifiedUDID = nil
    }
}

// MARK: - Preview
#Preview {
    UDIDVerifyView {
        print("Verified!")
    }
}
