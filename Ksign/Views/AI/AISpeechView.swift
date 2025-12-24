//
//  AISpeechView.swift
//  Ksign
//
//  AI Text-to-Speech with chat-style interface
//

import SwiftUI
import AVFoundation

struct AISpeechView: View {
    @StateObject private var viewModel = AISpeechViewModel()
    @State private var textInput = ""
    @State private var selectedVoice = "Ashley"
    @State private var showVoiceSettings = false
    @FocusState private var isInputFocused: Bool
    
    // Inworld TTS voice presets
    private let voices = [
        ("Ashley", "Ashley (Female, Warm)"),
        ("Dennis", "Dennis (Male, Neutral)"),
        ("Alex", "Alex (Male, Energetic)"),
        ("Mark", "Mark (Male, Deep)"),
        ("Jessica", "Jessica (Female, Bright)"),
        ("Brian", "Brian (Male, Friendly)"),
        ("Sarah", "Sarah (Female, Natural)"),
        ("James", "James (Male, Professional)")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome Message
                        if viewModel.messages.isEmpty {
                            WelcomeSpeechView()
                                .padding(.top, 40)
                        }
                        
                        // Speech Messages
                        ForEach(viewModel.messages) { message in
                            SpeechBubble(message: message, onPlay: {
                                viewModel.playMessage(message)
                            }, onDownload: {
                                viewModel.downloadMessage(message)
                            })
                            .id(message.id)
                        }
                        
                        // Loading Indicator
                        if viewModel.isGenerating {
                            GeneratingBubble()
                                .id("generating")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isGenerating) { _, isGenerating in
                    if isGenerating {
                        withAnimation {
                            proxy.scrollTo("generating", anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            VStack(spacing: 12) {
                // Voice Selector
                HStack {
                    Button {
                        showVoiceSettings.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.wave.2.fill")
                                .font(.caption)
                            Text(selectedVoice)
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    Text("\(textInput.count)/2000")
                        .font(.caption2)
                        .foregroundColor(textInput.count > 1800 ? .red : .secondary)
                }
                
                // Text Input + Send
                HStack(spacing: 12) {
                    // Text Field
                    HStack {
                        TextField("Enter text to speak...", text: $textInput, axis: .vertical)
                            .lineLimit(1...5)
                            .focused($isInputFocused)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    
                    // Send Button
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating ?
                                AnyShapeStyle(Color.gray) :
                                AnyShapeStyle(LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            )
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("AI Speech")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showVoiceSettings) {
            VoiceSettingsSheet(selectedVoice: $selectedVoice, voices: voices, viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .alert("Saved!", isPresented: $viewModel.showSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Audio saved to Files app")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }
    
    private func sendMessage() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        textInput = ""
        isInputFocused = false
        viewModel.generateSpeech(text: text, voiceId: selectedVoice)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Welcome View
struct WelcomeSpeechView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "waveform")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("AI Text-to-Speech")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Type any text and I'll convert it to natural speech using AI voices.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "person.wave.2", text: "Tap voice button to change voices")
                TipRow(icon: "arrow.down.circle", text: "Download audio to save locally")
                TipRow(icon: "slider.horizontal.3", text: "Adjust speed & expressiveness")
            }
            .padding(.top, 12)
        }
        .padding()
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Speech Bubble
struct SpeechBubble: View {
    let message: SpeechMessage
    let onPlay: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Text (Right aligned)
            HStack {
                Spacer(minLength: 60)
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
            }
            
            // AI Audio Response (Left aligned)
            HStack(alignment: .top, spacing: 10) {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                // Audio Card
                VStack(alignment: .leading, spacing: 12) {
                    // Voice Info
                    HStack {
                        Image(systemName: "person.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(message.voiceId)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Waveform Visualization
                    HStack(spacing: 2) {
                        ForEach(0..<30, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(
                                    message.isPlaying ?
                                    LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top) :
                                    LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.5)], startPoint: .bottom, endPoint: .top)
                                )
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                                .animation(
                                    message.isPlaying ?
                                    Animation.easeInOut(duration: 0.3).repeatForever().delay(Double(i) * 0.03) :
                                    .default,
                                    value: message.isPlaying
                                )
                        }
                    }
                    .frame(height: 24)
                    
                    // Controls
                    HStack(spacing: 16) {
                        // Play Button
                        Button(action: onPlay) {
                            HStack(spacing: 6) {
                                Image(systemName: message.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.caption)
                                Text(message.isPlaying ? "Pause" : "Play")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        
                        // Download Button
                        Button(action: onDownload) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption)
                                Text("Download")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Generating Bubble (Loading)
struct GeneratingBubble: View {
    @State private var animating = false
    @State private var dotScale: [CGFloat] = [0.5, 0.5, 0.5]
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Loading Animation
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    // Sound wave animation
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.orange)
                                .frame(width: 4, height: animating ? CGFloat.random(in: 10...30) : 10)
                                .animation(
                                    Animation.easeInOut(duration: 0.4)
                                        .repeatForever()
                                        .delay(Double(i) * 0.1),
                                    value: animating
                                )
                        }
                    }
                    
                    Text("Generating speech...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotScale[index])
                    }
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animating = true
            animateDots()
        }
    }
    
    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever()
                    .delay(Double(i) * 0.2)
            ) {
                dotScale[i] = 1.0
            }
        }
    }
}

// MARK: - Voice Settings Sheet
struct VoiceSettingsSheet: View {
    @Binding var selectedVoice: String
    let voices: [(String, String)]
    @ObservedObject var viewModel: AISpeechViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Voice Selection
                Section {
                    ForEach(voices, id: \.0) { voice in
                        Button {
                            selectedVoice = voice.0
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.0)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(voice.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedVoice == voice.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Label("Voice", systemImage: "person.wave.2.fill")
                }
                
                // Speed
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speaking Rate")
                            Spacer()
                            Text(String(format: "%.1fx", viewModel.speakingRate))
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "tortoise.fill")
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.speakingRate, in: 0.5...2.0, step: 0.1)
                                .tint(.orange)
                            Image(systemName: "hare.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Speed", systemImage: "speedometer")
                }
                
                // Expressiveness
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Expressiveness")
                            Spacer()
                            Text(String(format: "%.1f", viewModel.temperature))
                                .foregroundColor(.purple)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "face.dashed")
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.temperature, in: 0.5...2.0, step: 0.1)
                                .tint(.purple)
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Expression", systemImage: "theatermasks")
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Speech Message Model
struct SpeechMessage: Identifiable {
    let id = UUID()
    let text: String
    let voiceId: String
    let timestamp: Date
    var audioData: Data?
    var isPlaying: Bool = false
}

// MARK: - ViewModel
class AISpeechViewModel: ObservableObject {
    @Published var messages: [SpeechMessage] = []
    @Published var isGenerating = false
    @Published var speakingRate: Double = 1.0
    @Published var temperature: Double = 1.1
    @Published var showSavedAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var currentPlayingId: UUID?
    
    // Inworld TTS API Key (Base64 encoded) - stored in UserDefaults with default value
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "SwiftSignerPro.inworldAPIKey") ?? "dXdDRHhBSEtBMUY2emZnYzE2TVhVeVd1S0hrQW9wc086ME9hQno5UUdlNzJITTNxeUVZY3VuT1I2RVBFTlNqN1NIcmY2ckhiRUllUEtMU3E5ekxDYnEzR1F1TzZXUWxMTg=="
    }
    
    func generateSpeech(text: String, voiceId: String) {
        guard !text.isEmpty else { return }
        
        isGenerating = true
        
        Task {
            do {
                let data = try await fetchSpeech(text: text, voiceId: voiceId)
                
                await MainActor.run {
                    let message = SpeechMessage(
                        text: text,
                        voiceId: voiceId,
                        timestamp: Date(),
                        audioData: data
                    )
                    self.messages.append(message)
                    self.isGenerating = false
                    
                    // Auto-play
                    self.playMessage(message)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isGenerating = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func fetchSpeech(text: String, voiceId: String) async throws -> Data {
        // Correct Inworld TTS API endpoint
        guard let url = URL(string: "https://api.inworld.ai/tts/v1/voice") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Correct Inworld TTS API format based on documentation
        let body: [String: Any] = [
            "text": String(text.prefix(2000)),
            "voiceId": voiceId,  // Voice name like "Ashley", "Dennis", etc.
            "modelId": "inworld-tts-1",  // or "inworld-tts-1-max" for higher quality
            "audioConfig": [
                "temperature": temperature
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for error response
        if !(200...299).contains(httpResponse.statusCode) {
            // Try to parse JSON error
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = errorJson["message"] as? String {
                    throw NSError(domain: "InworldTTS", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: message])
                }
                if let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw NSError(domain: "InworldTTS", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: message])
                }
            }
            // Try string response
            if let errorStr = String(data: data, encoding: .utf8), !errorStr.isEmpty {
                throw NSError(domain: "InworldTTS", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "API error: \(errorStr.prefix(200))"])
            }
            throw NSError(domain: "InworldTTS", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
        }
        
        // Validate we got audio data (not JSON error)
        guard data.count > 100 else {
            throw NSError(domain: "InworldTTS", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response: audio data too small"])
        }
        
        return data
    }
    
    func playMessage(_ message: SpeechMessage) {
        guard let data = message.audioData else { return }
        
        // Stop current playback
        if let playingId = currentPlayingId {
            if let index = messages.firstIndex(where: { $0.id == playingId }) {
                messages[index].isPlaying = false
            }
            AudioPlayerManager.shared.stop()
        }
        
        // If same message, toggle
        if currentPlayingId == message.id, AudioPlayerManager.shared.isPlaying {
            AudioPlayerManager.shared.stop()
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].isPlaying = false
            }
            currentPlayingId = nil
            return
        }
        
        // Update UI state
        currentPlayingId = message.id
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isPlaying = true
        }
        
        // Play using AudioPlayerManager
        AudioPlayerManager.shared.play(data: data, fileExtension: "mp3") { [weak self] in
            // Playback finished
            DispatchQueue.main.async {
                if let self = self,
                   let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index].isPlaying = false
                }
                self?.currentPlayingId = nil
            }
        }
    }
    
    func downloadMessage(_ message: SpeechMessage) {
        guard let data = message.audioData else { 
            errorMessage = "No audio data available to download."
            showError = true
            return
        }
        
        let fileName = "Speech_\(message.voiceId)_\(Int(Date().timeIntervalSince1970)).mp3"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            showSavedAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AISpeechView()
    }
}
