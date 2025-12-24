//
//  AIChatView.swift
//  Ksign
//
//  AI Chat interface with bubble-style messages
//

import SwiftUI
import NimbleViews

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AI Chat View
struct AIChatView: View {
    @State private var textInput: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showAPIKeySheet: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // OpenRouter API Key - stored in UserDefaults with default value
    @AppStorage("SwiftSignerPro.openRouterAPIKey") private var openRouterApiKey: String = "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"
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Welcome message
                        if messages.isEmpty {
                            WelcomeCardView()
                                .padding(.top, 40)
                        }
                        
                        // Chat messages
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isTyping {
                            TypingIndicatorView()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isTyping) { typing in
                    if typing {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
            
            // Input Bar
            InputBarView(
                text: $textInput,
                isFocused: $isInputFocused,
                isTyping: isTyping,
                onSend: sendMessage
            )
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendMessage() {
        let trimmedText = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: trimmedText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        textInput = ""
        
        // Call OpenRouter API
        isTyping = true
        
        Task {
            do {
                let response = try await callOpenRouterAPI(prompt: trimmedText)
                await MainActor.run {
                    isTyping = false
                    let aiMessage = ChatMessage(content: response, isUser: false, timestamp: Date())
                    messages.append(aiMessage)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    errorMessage = error.localizedDescription
                    showError = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func callOpenRouterAPI(prompt: String) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openRouterApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("SwiftSigner Pro", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("SwiftSigner Pro iOS App", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 120  // Think model may take longer
        
        // Build conversation history
        var chatMessages: [[String: String]] = []
        
        // System prompt
        let systemPrompt = """
        You are a helpful AI assistant integrated into SwiftSigner Pro, an iOS app signing application. 
        You can help users with:
        - iOS app signing questions
        - Certificate and provisioning profile management
        - IPA file handling and modifications
        - Troubleshooting signing errors
        - General iOS development questions
        
        Be concise, friendly, and helpful. If you don't know something specific about SwiftSigner Pro, 
        provide general iOS signing guidance instead.
        
        When thinking through problems, use clear reasoning but keep responses focused and practical.
        """
        
        chatMessages.append(["role": "system", "content": systemPrompt])
        
        // Add recent conversation history (last 10 messages for context)
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            chatMessages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        // Add the current prompt
        chatMessages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": "allenai/olmo-3.1-32b-think:free",
            "messages": chatMessages,
            "temperature": 0.7,
            "max_tokens": 2048,
            "top_p": 0.95
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NSError(domain: "OpenRouter", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: message])
            }
            if let errorStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "OpenRouter", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "API error: \(errorStr.prefix(200))"])
            }
            throw NSError(domain: "OpenRouter", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
        }
        
        // Parse OpenAI-compatible response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "OpenRouter", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // Clean up the response - remove thinking tags if present
        var cleanedContent = content
        if let thinkEnd = cleanedContent.range(of: "</think>") {
            cleanedContent = String(cleanedContent[thinkEnd.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleanedContent
    }
}

// MARK: - Welcome Card View
private struct WelcomeCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            Text("AI Assistant")
                .font(.title2.bold())
            
            Text("Ask me anything about app signing, certificates, or how to use SwiftSigner Pro.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Suggestion chips
            VStack(spacing: 8) {
                SuggestionChip(text: "How do I sign an app?")
                SuggestionChip(text: "What certificates do I need?")
                SuggestionChip(text: "How to install signed apps?")
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

// MARK: - Suggestion Chip
private struct SuggestionChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
    }
}

// MARK: - Chat Bubble View
private struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser ?
                        AnyShapeStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Typing Indicator View
private struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(18)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animateTyping()
        }
    }
    
    private func animateTyping() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Input Bar View
private struct InputBarView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isTyping: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text Field
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(24)
                .focused(isFocused)
                .lineLimit(1...5)
            
            // Send Button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping ?
                        AnyShapeStyle(Color.gray) :
                        AnyShapeStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    AIChatView()
}
