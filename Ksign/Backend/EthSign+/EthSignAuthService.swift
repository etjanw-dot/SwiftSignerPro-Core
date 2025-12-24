//
//  EthSignAuthService.swift
//  Ksign
//
//  EthSign+ Authentication Service using Supabase
//

import Foundation
import SwiftUI
import AuthenticationServices

// MARK: - User Model
struct EthSignUser: Codable, Identifiable {
    let id: String
    let email: String
    var displayName: String?
    var avatarURL: String?
    let createdAt: Date
    var isPremium: Bool
    
    init(id: String, email: String, displayName: String? = nil, avatarURL: String? = nil, createdAt: Date = Date(), isPremium: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.isPremium = isPremium
    }
}

// MARK: - Auth Error
enum EthSignAuthError: LocalizedError {
    case invalidCredentials
    case emailNotVerified
    case networkError
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case serverError(String)
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotVerified:
            return "Please verify your email before signing in"
        case .networkError:
            return "Network error. Please check your connection"
        case .userNotFound:
            return "No account found with this email"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .serverError(let message):
            return message
        case .notConfigured:
            return "SwiftSigner Pro is not configured. Please add your Supabase credentials."
        }
    }
}

// MARK: - Auth Service
class EthSignAuthService: NSObject, ObservableObject {
    static let shared = EthSignAuthService()
    
    // MARK: - Published Properties
    @Published var currentUser: EthSignUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var hasSkippedLogin: Bool = false
    
    // MARK: - Supabase Configuration
    // Built-in Supabase credentials (can be overridden by user)
    private static let defaultSupabaseURL = "https://eyufnmqchlgiqnesgsdi.supabase.co"
    private static let defaultSupabaseAnonKey = "sb_publishable_o8Svinw36oSV1eXXpyyEJQ_VTAEoxnR"
    
    private var supabaseURL: String {
        UserDefaults.standard.string(forKey: "ethsign.supabase.url") ?? Self.defaultSupabaseURL
    }
    
    private var supabaseAnonKey: String {
        UserDefaults.standard.string(forKey: "ethsign.supabase.anonKey") ?? Self.defaultSupabaseAnonKey
    }
    
    var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
    
    // MARK: - Session Storage Keys
    private let accessTokenKey = "ethsign.auth.accessToken"
    private let refreshTokenKey = "ethsign.auth.refreshToken"
    private let userDataKey = "ethsign.auth.userData"
    private let skippedLoginKey = "ethsign.auth.skippedLogin"
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadSession()
    }
    
    // MARK: - Configuration
    func configure(supabaseURL: String, anonKey: String) {
        UserDefaults.standard.set(supabaseURL, forKey: "ethsign.supabase.url")
        UserDefaults.standard.set(anonKey, forKey: "ethsign.supabase.anonKey")
    }
    
    // MARK: - Session Management
    private func loadSession() {
        hasSkippedLogin = UserDefaults.standard.bool(forKey: skippedLoginKey)
        
        if let userData = UserDefaults.standard.data(forKey: userDataKey),
           let user = try? JSONDecoder().decode(EthSignUser.self, from: userData) {
            currentUser = user
            isAuthenticated = true
            
            // Refresh session in background
            Task {
                await refreshSession()
            }
        }
    }
    
    private func saveSession(user: EthSignUser, accessToken: String, refreshToken: String) {
        currentUser = user
        isAuthenticated = true
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userDataKey)
        }
        
        // Store tokens securely in Keychain (simplified for now, using UserDefaults)
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
    }
    
    private func clearSession() {
        currentUser = nil
        isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: userDataKey)
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
    
    // MARK: - API Helpers
    private func makeRequest(endpoint: String, method: String = "POST", body: [String: Any]? = nil, accessToken: String? = nil) async throws -> (Data, HTTPURLResponse) {
        guard isConfigured else {
            throw EthSignAuthError.notConfigured
        }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/\(endpoint)") else {
            throw EthSignAuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EthSignAuthError.networkError
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        guard isConfigured else {
            throw EthSignAuthError.notConfigured
        }
        
        // Validate inputs
        guard isValidEmail(email) else {
            throw EthSignAuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw EthSignAuthError.weakPassword
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["display_name": displayName ?? ""]
        ]
        
        let (data, response) = try await makeRequest(endpoint: "signup", body: body)
        
        if response.statusCode == 200 || response.statusCode == 201 {
            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userId = json["id"] as? String ?? (json["user"] as? [String: Any])?["id"] as? String,
               let accessToken = json["access_token"] as? String,
               let refreshToken = json["refresh_token"] as? String {
                
                let user = EthSignUser(
                    id: userId,
                    email: email,
                    displayName: displayName,
                    createdAt: Date(),
                    isPremium: false
                )
                
                await MainActor.run {
                    saveSession(user: user, accessToken: accessToken, refreshToken: refreshToken)
                }
            }
        } else {
            // Parse error
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error_description"] as? String ?? json["msg"] as? String {
                if message.lowercased().contains("already") {
                    throw EthSignAuthError.emailAlreadyExists
                }
                throw EthSignAuthError.serverError(message)
            }
            throw EthSignAuthError.serverError("Sign up failed")
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        guard isConfigured else {
            throw EthSignAuthError.notConfigured
        }
        
        guard isValidEmail(email) else {
            throw EthSignAuthError.invalidEmail
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let (data, response) = try await makeRequest(endpoint: "token?grant_type=password", body: body)
        
        if response.statusCode == 200 {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let refreshToken = json["refresh_token"] as? String,
               let userJson = json["user"] as? [String: Any],
               let userId = userJson["id"] as? String,
               let userEmail = userJson["email"] as? String {
                
                let metadata = userJson["user_metadata"] as? [String: Any]
                let displayName = metadata?["display_name"] as? String
                
                let user = EthSignUser(
                    id: userId,
                    email: userEmail,
                    displayName: displayName,
                    createdAt: Date(),
                    isPremium: false
                )
                
                await MainActor.run {
                    saveSession(user: user, accessToken: accessToken, refreshToken: refreshToken)
                }
            }
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error_description"] as? String ?? json["msg"] as? String {
                if message.lowercased().contains("invalid") || message.lowercased().contains("credentials") {
                    throw EthSignAuthError.invalidCredentials
                }
                throw EthSignAuthError.serverError(message)
            }
            throw EthSignAuthError.invalidCredentials
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        let accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        
        if let token = accessToken {
            _ = try? await makeRequest(endpoint: "logout", accessToken: token)
        }
        
        await MainActor.run {
            clearSession()
        }
    }
    
    // MARK: - Refresh Session
    func refreshSession() async {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            return
        }
        
        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]
        
        do {
            let (data, response) = try await makeRequest(endpoint: "token?grant_type=refresh_token", body: body)
            
            if response.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newAccessToken = json["access_token"] as? String,
               let newRefreshToken = json["refresh_token"] as? String {
                
                UserDefaults.standard.set(newAccessToken, forKey: accessTokenKey)
                UserDefaults.standard.set(newRefreshToken, forKey: refreshTokenKey)
            }
        } catch {
            // Session expired, clear it
            await MainActor.run {
                clearSession()
            }
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        guard isConfigured else {
            throw EthSignAuthError.notConfigured
        }
        
        guard isValidEmail(email) else {
            throw EthSignAuthError.invalidEmail
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        let body: [String: Any] = [
            "email": email
        ]
        
        let (_, response) = try await makeRequest(endpoint: "recover", body: body)
        
        if response.statusCode != 200 {
            throw EthSignAuthError.serverError("Failed to send password reset email")
        }
    }
    
    // MARK: - Skip Login
    func skipLogin() {
        hasSkippedLogin = true
        UserDefaults.standard.set(true, forKey: skippedLoginKey)
    }
    
    // MARK: - Get Access Token
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    // MARK: - Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Apple Sign In
extension EthSignAuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            return
        }
        
        Task {
            await signInWithAppleToken(tokenString, credential: appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error.localizedDescription)")
    }
    
    private func signInWithAppleToken(_ token: String, credential: ASAuthorizationAppleIDCredential) async {
        guard isConfigured else {
            return
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": token
        ]
        
        do {
            let (data, response) = try await makeRequest(endpoint: "token?grant_type=id_token", body: body)
            
            if response.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let refreshToken = json["refresh_token"] as? String,
               let userJson = json["user"] as? [String: Any],
               let userId = userJson["id"] as? String {
                
                let email = userJson["email"] as? String ?? credential.email ?? ""
                var displayName: String?
                
                if let fullName = credential.fullName {
                    displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }
                
                let user = EthSignUser(
                    id: userId,
                    email: email,
                    displayName: displayName,
                    createdAt: Date(),
                    isPremium: false
                )
                
                await MainActor.run {
                    saveSession(user: user, accessToken: accessToken, refreshToken: refreshToken)
                }
            }
        } catch {
            print("Apple Sign In API Error: \(error.localizedDescription)")
        }
    }
}
