//
//  LoginView.swift
//  Ksign
//
//  SwiftSigner Pro Login and Registration View
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject private var authService = EthSignAuthService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var showConfigSheet = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            _backgroundGradient()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Logo and Title
                    _headerSection()
                    
                    // Auth Form
                    _authForm()
                    
                    // Divider
                    _dividerSection()
                    
                    // Apple Sign In
                    _appleSignInButton()
                    
                    // Skip Button
                    _skipButton()
                    
                    // Config Button (for developers)
                    _configButton()
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            _forgotPasswordSheet()
        }
        .sheet(isPresented: $showConfigSheet) {
            _configurationSheet()
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private func _backgroundGradient() -> some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.15),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func _headerSection() -> some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "signature")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("SwiftSigner Pro")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Sign in to sync your certificates and repos across devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Auth Form
    @ViewBuilder
    private func _authForm() -> some View {
        VStack(spacing: 16) {
            // Toggle Sign In / Sign Up
            Picker("", selection: $isSignUp) {
                Text("Sign In").tag(false)
                Text("Sign Up").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)
            
            // Display Name (Sign Up only)
            if isSignUp {
                _textField(
                    icon: "person.fill",
                    placeholder: "Display Name",
                    text: $displayName,
                    isSecure: false,
                    keyboardType: .default
                )
            }
            
            // Email Field
            _textField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                isSecure: false,
                keyboardType: .emailAddress
            )
            
            // Password Field
            _textField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                isSecure: true
            )
            
            // Confirm Password (Sign Up only)
            if isSignUp {
                _textField(
                    icon: "lock.fill",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true
                )
            }
            
            // Forgot Password (Sign In only)
            if !isSignUp {
                HStack {
                    Spacer()
                    Button {
                        showForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Submit Button
            Button {
                _handleAuth()
            } label: {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .disabled(authService.isLoading || !_isFormValid())
            .opacity(_isFormValid() && !authService.isLoading ? 1.0 : 0.6)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Text Field
    @ViewBuilder
    private func _textField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Divider
    @ViewBuilder
    private func _dividerSection() -> some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            
            Text("or")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Apple Sign In
    @ViewBuilder
    private func _appleSignInButton() -> some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success:
                authService.signInWithApple()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 54)
        .cornerRadius(14)
    }
    
    // MARK: - Skip Button
    @ViewBuilder
    private func _skipButton() -> some View {
        Button {
            authService.skipLogin()
        } label: {
            Text("Continue without account")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
        }
    }
    
    // MARK: - Config Button
    @ViewBuilder
    private func _configButton() -> some View {
        if !authService.isConfigured {
            Button {
                showConfigSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.caption)
                    Text("Configure Supabase")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Forgot Password Sheet
    @ViewBuilder
    private func _forgotPasswordSheet() -> some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                _textField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false,
                    keyboardType: .emailAddress
                )
                
                Button {
                    Task {
                        await _handleForgotPassword()
                    }
                } label: {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                .disabled(email.isEmpty || authService.isLoading)
                
                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showForgotPassword = false
                    }
                }
            }
        }
    }
    
    // MARK: - Configuration Sheet
    @ViewBuilder
    private func _configurationSheet() -> some View {
        NavigationView {
            _SupabaseConfigView(isPresented: $showConfigSheet)
        }
    }
    
    // MARK: - Actions
    private func _handleAuth() {
        Task {
            do {
                if isSignUp {
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match"
                        showError = true
                        return
                    }
                    try await authService.signUp(email: email, password: password, displayName: displayName.isEmpty ? nil : displayName)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func _handleForgotPassword() async {
        do {
            try await authService.sendPasswordReset(email: email)
            await MainActor.run {
                successMessage = "Password reset link sent to your email"
                showSuccess = true
                showForgotPassword = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func _isFormValid() -> Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }
}

// MARK: - Supabase Config View
struct _SupabaseConfigView: View {
    @Binding var isPresented: Bool
    @State private var supabaseURL = ""
    @State private var anonKey = ""
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Configure Supabase")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Enter your Supabase project credentials to enable SwiftSigner Pro cloud features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)
            
            Section("Project URL") {
                TextField("https://xxxxx.supabase.co", text: $supabaseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Section("Anon Key") {
                TextField("eyJhbGc...", text: $anonKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Section {
                Button {
                    EthSignAuthService.shared.configure(supabaseURL: supabaseURL, anonKey: anonKey)
                    isPresented = false
                } label: {
                    Text("Save Configuration")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(supabaseURL.isEmpty || anonKey.isEmpty)
            }
            
            Section {
                Link(destination: URL(string: "https://supabase.com/dashboard")!) {
                    HStack {
                        Text("Create a Supabase Project")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            } footer: {
                Text("Don't have a Supabase project? Create one for free at supabase.com")
            }
        }
        .navigationTitle("Supabase Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
        .onAppear {
            supabaseURL = UserDefaults.standard.string(forKey: "ethsign.supabase.url") ?? ""
            anonKey = UserDefaults.standard.string(forKey: "ethsign.supabase.anonKey") ?? ""
        }
    }
}

#Preview {
    LoginView()
}
