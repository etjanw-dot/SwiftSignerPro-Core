//
//  AppleIDSettingsView.swift
//  SwiftSigner Pro
//
//  Apple ID login with 2FA support like PancakeStore
//

import SwiftUI
import NimbleViews

struct AppleIDSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeClient = AppStoreClient.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var twoFACode = ""
    @State private var showPassword = false
    @State private var hasSent2FACode = false
    @State private var isLoading = false
    
    var body: some View {
        Form {
            // Header Section
            Section {
                VStack(spacing: 16) {
                    // Apple Logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray, .black],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "apple.logo")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Text("Apple ID")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Sign in to download apps from the App Store")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            
            // Credentials Section
            Section {
                TextField("Apple ID Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(hasSent2FACode)
                
                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye" : "eye.slash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .disabled(hasSent2FACode)
            } header: {
                Text("Credentials")
            }
            
            // 2FA Section - Only shown after sending code
            if hasSent2FACode {
                Section {
                    TextField("2FA Code", text: $twoFACode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.caption)
                        Text("Verification Code")
                    }
                } footer: {
                    Text("Enter the verification code sent to your trusted devices. If you didn't receive a notification, enter any 6 random digits.")
                }
            }
            
            // Error Message
            if let error = storeClient.authError {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Buttons
            Section {
                Button {
                    _authenticate()
                } label: {
                    HStack {
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: hasSent2FACode ? "arrow.right.circle.fill" : "key.fill")
                            Text(hasSent2FACode ? "Log In" : "Send 2FA Code")
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: isButtonDisabled ? [.gray, .gray] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .disabled(isButtonDisabled || isLoading)
                
                if hasSent2FACode {
                    Button {
                        // Reset to start over
                        hasSent2FACode = false
                        twoFACode = ""
                        storeClient.needs2FA = false
                    } label: {
                        HStack {
                            Spacer()
                            Text("Start Over")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Apple ID")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: storeClient.isAuthenticated) { _, isAuth in
            if isAuth {
                dismiss()
            }
        }
    }
    
    private var isButtonDisabled: Bool {
        if hasSent2FACode {
            return twoFACode.isEmpty
        } else {
            return email.isEmpty || password.isEmpty
        }
    }
    
    private func _authenticate() {
        isLoading = true
        
        Task {
            if hasSent2FACode {
                // Full login with 2FA code
                let finalPassword = password + twoFACode
                _ = await storeClient.authenticate(email: email, password: finalPassword)
            } else {
                // First step - request 2FA code
                _ = await storeClient.authenticate(email: email, password: password)
                await MainActor.run {
                    hasSent2FACode = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        AppleIDSettingsView()
    }
}
