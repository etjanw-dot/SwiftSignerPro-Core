//
//  AIView.swift
//  Ksign
//
//  AI Tools - ChatGPT-style interface with Chat and Speech modes
//

import SwiftUI
import NimbleViews

struct AIView: View {
    @State private var selectedMode: AIMode = .chat
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            aiContentView
        }
    }
    
    // MARK: - AI Content View
    private var aiContentView: some View {
        VStack(spacing: 0) {
            // Mode Selector (ChatGPT-style)
            HStack(spacing: 0) {
                ForEach(AIMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(mode.title)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(selectedMode == mode ? .white : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background {
                                if selectedMode == mode {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: mode.gradientColors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .matchedGeometryEffect(id: "selector", in: animation)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(.systemGray6))
            .cornerRadius(30)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Content based on selected mode
            switch selectedMode {
            case .chat:
                AIChatView()
            case .speech:
                AISpeechView()
            }
        }
        .navigationTitle("AI")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Upgrade Prompt View
    private var upgradePromptView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                // AI Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.purple.opacity(0.5), radius: 30, x: 0, y: 15)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("AI Features")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Powered by Gemini & Inworld")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", 
                               title: "AI Chat Assistant",
                               description: "Get help with app signing, certificates, and troubleshooting",
                               color: .blue)
                    
                    FeatureRow(icon: "waveform.circle.fill",
                               title: "AI Text-to-Speech",
                               description: "Convert text to natural-sounding speech with multiple voices",
                               color: .orange)
                    
                    FeatureRow(icon: "sparkles.rectangle.stack.fill",
                               title: "Powered by Gemini 2.5",
                               description: "Advanced AI for intelligent, context-aware responses",
                               color: .purple)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Plan Badge
                VStack(spacing: 12) {
                    Text("Available in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        PlanBadge(name: "Ultimate", color: .orange)
                        PlanBadge(name: "Unlimited", color: .purple)
                    }
                }
                
                // Upgrade Button
                Button {
                    if let url = URL(string: "https://swiftsigner-pro.vercel.app#pricing") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Upgrade to Ultimate")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle("AI")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Plan Badge
private struct PlanBadge: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
    }
}

// MARK: - AI Mode Enum
enum AIMode: String, CaseIterable, Identifiable {
    case chat
    case speech
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .chat: return "Chat"
        case .speech: return "Speech"
        }
    }
    
    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .speech: return "waveform.circle.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .chat: return [.blue, .purple]
        case .speech: return [.orange, .red]
        }
    }
}

// MARK: - Preview
#Preview {
    AIView()
}
