//
//  WelcomeGuideView.swift
//  Ksign
//
//  Apple-style onboarding experience for first launch
//

import SwiftUI
import UniformTypeIdentifiers
import NimbleViews

// MARK: - Welcome Feature
struct WelcomeFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

// MARK: - Welcome Guide View
struct WelcomeGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var showCertImport: Bool = false
    
    let features: [WelcomeFeature] = [
        WelcomeFeature(
            icon: "signature",
            iconColor: .orange,
            title: "Sign Your Apps",
            description: "Sign IPA files with your certificates and install them directly on your device."
        ),
        WelcomeFeature(
            icon: "folder.fill",
            iconColor: .blue,
            title: "Manage Repositories",
            description: "Add app repositories to discover and download new apps with a single tap."
        ),
        WelcomeFeature(
            icon: "person.text.rectangle.fill",
            iconColor: .green,
            title: "Certificate Management",
            description: "Import and manage your signing certificates securely within the app."
        ),
        WelcomeFeature(
            icon: "sparkles",
            iconColor: .purple,
            title: "Customization",
            description: "Personalize your experience with themes, accent colors, and more."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // App Icon - Use actual app icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 110, height: 110)
                        .blur(radius: 20)
                    
                    if let iconFileName = Bundle.main.iconFileName,
                       let iconImage = UIImage(named: iconFileName) {
                        Image(uiImage: iconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                            .overlay(
                                Image(systemName: "signature")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.top, 60)
                
                Text(.localized("Welcome to SwiftSigner Pro"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(.localized("Thank you for choosing our app"))
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Features List
            VStack(spacing: 24) {
                ForEach(features) { feature in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(feature.iconColor.opacity(0.15))
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: feature.icon)
                                .font(.system(size: 24))
                                .foregroundColor(feature.iconColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized(feature.title))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(.localized(feature.description))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 28)
            
            Spacer()
            
            // Continue Button
            VStack(spacing: 16) {
                Button {
                    // Mark as completed and show cert import
                    UserDefaults.standard.set(true, forKey: "ksign.hasCompletedOnboarding")
                    showCertImport = true
                } label: {
                    Text(.localized("Get Started"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                }
                .padding(.horizontal, 28)
                
                // Skip link
                Button {
                    UserDefaults.standard.set(true, forKey: "ksign.hasCompletedOnboarding")
                    dismiss()
                } label: {
                    Text(.localized("Skip for now"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
        .fullScreenCover(isPresented: $showCertImport) {
            CertificateImportPromptView {
                dismiss()
            }
        }
    }
}

// MARK: - Certificate Import Prompt View
struct CertificateImportPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false
    @State private var importedP12URLs: [URL] = []
    @State private var importedProvisionURLs: [URL] = []
    @State private var p12Passwords: [String] = []
    @State private var certNames: [String] = []
    @State private var isImporting = false
    @State private var importSuccess = false
    @State private var importError: String? = nil
    @State private var currentPickerType: CertPickerType = .p12
    
    let onComplete: () -> Void
    
    enum CertPickerType {
        case p12
        case provision
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        
                        Text(.localized("Import Certificates"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(.localized("Import your signing certificates to start signing apps. You can import multiple certificates at once."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Certificate Slots
                    VStack(spacing: 16) {
                        ForEach(0..<max(1, importedP12URLs.count + 1), id: \.self) { index in
                            _certificateSlot(index: index)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Import Button
                    if !importedP12URLs.isEmpty {
                        Button {
                            _importCertificates()
                        } label: {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(.localized("Import \(importedP12URLs.count) Certificate\(importedP12URLs.count == 1 ? "" : "s")"))
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }
                        .disabled(isImporting)
                        .padding(.horizontal)
                    }
                    
                    // Skip Button
                    Button {
                        onComplete()
                    } label: {
                        Text(.localized("Skip for Later"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(.localized("Certificates"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.localized("Done")) {
                        onComplete()
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: currentPickerType == .p12 ? 
                        [UTType(filenameExtension: "p12")!, UTType(filenameExtension: "pfx")!] :
                        [UTType(filenameExtension: "mobileprovision")!],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        if currentPickerType == .p12 {
                            for url in urls {
                                importedP12URLs.append(url)
                                p12Passwords.append("")
                                certNames.append(url.deletingPathExtension().lastPathComponent)
                            }
                        } else {
                            for url in urls {
                                if importedProvisionURLs.count < importedP12URLs.count {
                                    importedProvisionURLs.append(url)
                                } else {
                                    importedProvisionURLs.append(url)
                                }
                            }
                        }
                    }
                )
            }
            .alert(.localized("Success!"), isPresented: $importSuccess) {
                Button(.localized("Continue")) {
                    onComplete()
                }
            } message: {
                Text(.localized("Your certificates have been imported successfully. You can now sign apps!"))
            }
            .alert(.localized("Import Error"), isPresented: .constant(importError != nil)) {
                Button(.localized("OK")) {
                    importError = nil
                }
            } message: {
                Text(importError ?? "")
            }
        }
    }
    
    @ViewBuilder
    private func _certificateSlot(index: Int) -> some View {
        VStack(spacing: 12) {
            if index < importedP12URLs.count {
                // Filled slot
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.doc.fill")
                            .foregroundColor(.green)
                        Text(importedP12URLs[index].lastPathComponent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            importedP12URLs.remove(at: index)
                            if index < p12Passwords.count { p12Passwords.remove(at: index) }
                            if index < certNames.count { certNames.remove(at: index) }
                            if index < importedProvisionURLs.count { importedProvisionURLs.remove(at: index) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Password field
                    SecureField(.localized("Password"), text: Binding(
                        get: { index < p12Passwords.count ? p12Passwords[index] : "" },
                        set: { if index < p12Passwords.count { p12Passwords[index] = $0 } }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    // Certificate name
                    TextField(.localized("Certificate Name"), text: Binding(
                        get: { index < certNames.count ? certNames[index] : "" },
                        set: { if index < certNames.count { certNames[index] = $0 } }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    // Provision file
                    if index < importedProvisionURLs.count {
                        HStack {
                            Image(systemName: "doc.badge.gearshape.fill")
                                .foregroundColor(.accentColor)
                            Text(importedProvisionURLs[index].lastPathComponent)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                    } else {
                        Button {
                            currentPickerType = .provision
                            showFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(.localized("Add Provisioning Profile"))
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                // Empty slot - add button
                Button {
                    currentPickerType = .p12
                    showFilePicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        Text(.localized("Add P12 Certificate"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(.localized("Tap to import .p12 or .pfx file"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
    }
    
    private func _importCertificates() {
        isImporting = true
        
        let dispatchGroup = DispatchGroup()
        var errors: [String] = []
        
        for i in 0..<importedP12URLs.count {
            guard i < importedProvisionURLs.count else { continue }
            
            dispatchGroup.enter()
            
            let p12URL = importedP12URLs[i]
            let provisionURL = importedProvisionURLs[i]
            let password = i < p12Passwords.count ? p12Passwords[i] : ""
            let name = i < certNames.count ? certNames[i] : "Certificate \(i + 1)"
            
            FR.handleCertificateFiles(
                p12URL: p12URL,
                provisionURL: provisionURL,
                p12Password: password,
                certificateName: name
            ) { error in
                if let error = error {
                    errors.append("\(name): \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            isImporting = false
            if errors.isEmpty && !importedP12URLs.isEmpty {
                importSuccess = true
            } else if !errors.isEmpty {
                importError = errors.joined(separator: "\n")
            }
        }
    }
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var shouldShowOnboarding: Bool = false
    
    private let onboardingKey = "ksign.hasCompletedOnboarding"
    
    init() {
        // Check if onboarding has been completed
        shouldShowOnboarding = !UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        shouldShowOnboarding = false
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: onboardingKey)
        shouldShowOnboarding = true
    }
}

// MARK: - Preview
#Preview {
    WelcomeGuideView()
}
