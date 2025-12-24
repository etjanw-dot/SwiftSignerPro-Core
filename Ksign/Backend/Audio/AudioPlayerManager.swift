//
//  AudioPlayerManager.swift
//  Ksign
//
//  Audio playback manager for MP3 and other audio formats
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var isLoading: Bool = false
    @Published var currentFileURL: URL?
    @Published var error: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var playbackFinishedHandler: (() -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Play from Data
    func play(data: Data, fileExtension: String = "mp3", completion: (() -> Void)? = nil) {
        isLoading = true
        error = nil
        playbackFinishedHandler = completion
        
        // Write to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("audio_\(UUID().uuidString).\(fileExtension)")
        
        do {
            try data.write(to: tempFile)
            play(url: tempFile)
        } catch {
            self.error = "Failed to save audio: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Play from URL
    func play(url: URL) {
        stop()
        isLoading = true
        error = nil
        currentFileURL = url
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            progress = 0
            
            audioPlayer?.play()
            isPlaying = true
            isLoading = false
            
            startProgressTimer()
        } catch {
            self.error = "Playback error: \(error.localizedDescription)"
            isPlaying = false
            isLoading = false
        }
    }
    
    // MARK: - Playback Controls
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        progress = 0
        stopProgressTimer()
        
        // Clean up temp file
        if let url = currentFileURL, url.path.contains("audio_") {
            try? FileManager.default.removeItem(at: url)
        }
        currentFileURL = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateProgress()
    }
    
    func seek(toProgress: Double) {
        let time = duration * toProgress
        seek(to: time)
    }
    
    // MARK: - Progress Timer
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        if duration > 0 {
            progress = currentTime / duration
        }
    }
    
    // MARK: - Utility
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopProgressTimer()
            self.playbackFinishedHandler?()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.error = "Decode error: \(error?.localizedDescription ?? "Unknown")"
            self.isPlaying = false
            self.stopProgressTimer()
        }
    }
}

// MARK: - Audio Player View Component
import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var player: AudioPlayerManager
    let title: String
    let showWaveform: Bool
    
    @State private var waveformValues: [CGFloat] = []
    
    init(player: AudioPlayerManager = .shared, title: String = "Audio", showWaveform: Bool = true) {
        self.player = player
        self.title = title
        self.showWaveform = showWaveform
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: player.isPlaying ? "waveform" : "music.note")
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
                if player.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Waveform Visualization
            if showWaveform && player.isPlaying {
                WaveformView(isAnimating: player.isPlaying)
                    .frame(height: 40)
            }
            
            // Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color(.systemGray5))
                        
                        // Progress
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(player.progress))
                    }
                }
                .frame(height: 6)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                            player.seek(toProgress: progress)
                        }
                )
                
                // Time Labels
                HStack {
                    Text(player.formatTime(player.currentTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(player.formatTime(player.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Controls
            HStack(spacing: 32) {
                // Rewind 10s
                Button {
                    player.seek(to: max(0, player.currentTime - 10))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                .disabled(!player.isPlaying && player.progress == 0)
                
                // Play/Pause
                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .offset(x: player.isPlaying ? 0 : 2)
                    }
                }
                
                // Forward 10s
                Button {
                    player.seek(to: min(player.duration, player.currentTime + 10))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
                .disabled(!player.isPlaying && player.progress == 0)
            }
            .foregroundColor(.primary)
            
            // Error
            if let error = player.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let isAnimating: Bool
    let barCount: Int = 20
    
    @State private var animationAmount: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .scaleY(animationAmount.count > index ? animationAmount[index] : 0.3)
            }
        }
        .onAppear {
            animationAmount = Array(repeating: 0.3, count: barCount)
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        for i in 0..<barCount {
            withAnimation(
                Animation
                    .easeInOut(duration: Double.random(in: 0.3...0.6))
                    .repeatForever()
                    .delay(Double(i) * 0.05)
            ) {
                if animationAmount.count > i {
                    animationAmount[i] = CGFloat.random(in: 0.3...1.0)
                }
            }
        }
    }
}

extension View {
    func scaleY(_ scale: CGFloat) -> some View {
        self.scaleEffect(CGSize(width: 1, height: scale), anchor: .bottom)
    }
}

// MARK: - Compact Audio Player
struct CompactAudioPlayerView: View {
    @ObservedObject var player: AudioPlayerManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause Button
            Button {
                player.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .font(.body)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(player.progress))
                    }
                }
                .frame(height: 4)
                
                // Time
                HStack {
                    Text(player.formatTime(player.currentTime))
                    Spacer()
                    Text(player.formatTime(player.duration))
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            // Stop Button
            Button {
                player.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AudioPlayerView(player: AudioPlayerManager.shared, title: "Test Audio")
        CompactAudioPlayerView(player: AudioPlayerManager.shared)
    }
    .padding()
}
