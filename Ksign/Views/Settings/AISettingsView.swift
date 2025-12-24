//
//  AISettingsView.swift
//  Ksign
//
//  AI Settings - Configure API keys for Chat and TTS
//

import SwiftUI

struct AISettingsView: View {
    @AppStorage("SwiftSignerPro.openRouterAPIKey") private var openRouterAPIKey: String = "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"
    @AppStorage("SwiftSignerPro.inworldAPIKey") private var inworldAPIKey: String = "dXdDRHhBSEtBMUY2emZnYzE2TVhVeVd1S0hrQW9wc086ME9hQno5UUdlNzJITTNxeUVZY3VuT1I2RVBFTlNqN1NIcmY2ckhiRUllUEtMU3E5ekxDYnEzR1F1TzZXUWxMTg=="
    
    @State private var showOpenRouterKey = false
    @State private var showInworldKey = false
    @State private var tempOpenRouterKey = ""
    @State private var tempInworldKey = ""
    
    var body: some View {
        List {
            // AI Chat Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading) {
                            Text("AI Chat")
                                .font(.headline)
                            Text("OpenRouter with Olmo 3.1 32B Think")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showOpenRouterKey {
                                TextField("OpenRouter API Key", text: $tempOpenRouterKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.caption, design: .monospaced))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                Text(maskedKey(openRouterAPIKey))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            Button {
                                if showOpenRouterKey {
                                    // Save
                                    if !tempOpenRouterKey.isEmpty {
                                        openRouterAPIKey = tempOpenRouterKey
                                    }
                                } else {
                                    tempOpenRouterKey = openRouterAPIKey
                                }
                                showOpenRouterKey.toggle()
                            } label: {
                                Text(showOpenRouterKey ? "Save" : "Edit")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Get OpenRouter API Key")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label("Chat Settings", systemImage: "message.fill")
            }
            
            // TTS Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Text-to-Speech")
                                .font(.headline)
                            Text("Inworld TTS API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key (Base64)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showInworldKey {
                                TextField("Inworld API Key", text: $tempInworldKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.caption, design: .monospaced))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                Text(maskedKey(inworldAPIKey))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            Button {
                                if showInworldKey {
                                    // Save
                                    if !tempInworldKey.isEmpty {
                                        inworldAPIKey = tempInworldKey
                                    }
                                } else {
                                    tempInworldKey = inworldAPIKey
                                }
                                showInworldKey.toggle()
                            } label: {
                                Text(showInworldKey ? "Save" : "Edit")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Link(destination: URL(string: "https://platform.inworld.ai/")!) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Get Inworld API Key")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label("Speech Settings", systemImage: "speaker.wave.3.fill")
            }
            
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("About AI Features")
                            .font(.headline)
                    }
                    
                    Text("AI Chat uses OpenRouter to access the AllenAI Olmo 3.1 32B Think model for intelligent conversations about iOS app signing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Text-to-Speech uses Inworld's TTS API to generate natural-sounding speech from text.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Reset Section
            Section {
                Button(role: .destructive) {
                    openRouterAPIKey = "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"
                    inworldAPIKey = "dXdDRHhBSEtBMUY2emZnYzE2TVhVeVd1S0hrQW9wc086ME9hQno5UUdlNzJITTNxeUVZY3VuT1I2RVBFTlNqN1NIcmY2ckhiRUllUEtMU3E5ekxDYnEzR1F1TzZXUWxMTg=="
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Default Keys")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("AI Settings")
    }
    
    private func maskedKey(_ key: String) -> String {
        guard key.count > 12 else { return "••••••••" }
        let prefix = String(key.prefix(8))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AISettingsView()
    }
}
