//
//  ActivityCellViews.swift
//  SwiftSigner Pro
//
//  Shows apps being signed or modified with progress bars
//

import SwiftUI
import NukeUI

// MARK: - App Activity Model
struct AppActivity: Identifiable, Equatable {
    let id: UUID
    let name: String
    let bundleId: String
    let iconURL: URL?
    var progress: Double // 0.0 to 1.0
    var status: ActivityStatus
    let activityType: ActivityType
    
    enum ActivityType: Equatable {
        case signing
        case modifying
        case installing
    }
    
    enum ActivityStatus: Equatable {
        case waiting
        case inProgress
        case completed
        case failed(String)
        
        var displayText: String {
            switch self {
            case .waiting: return .localized("Waiting...")
            case .inProgress: return .localized("In Progress...")
            case .completed: return .localized("Completed")
            case .failed(let error): return .localized("Failed: ") + error
            }
        }
        
        var isActive: Bool {
            switch self {
            case .waiting, .inProgress:
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Signing Apps Manager
class SigningAppsManager: ObservableObject {
    static let shared = SigningAppsManager()
    
    @Published var activities: [AppActivity] = []
    
    func addActivity(id: UUID, name: String, bundleId: String, iconURL: URL?) {
        DispatchQueue.main.async {
            if !self.activities.contains(where: { $0.id == id }) {
                let activity = AppActivity(
                    id: id,
                    name: name,
                    bundleId: bundleId,
                    iconURL: iconURL,
                    progress: 0,
                    status: .waiting,
                    activityType: .signing
                )
                self.activities.append(activity)
            }
        }
    }
    
    func updateProgress(id: UUID, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].progress = progress
            }
        }
    }
    
    func updateStatus(id: UUID, status: AppActivity.ActivityStatus) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].status = status
                
                // Remove completed/failed after delay
                if case .completed = status {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.removeActivity(id: id)
                    }
                }
            }
        }
    }
    
    func removeActivity(id: UUID) {
        DispatchQueue.main.async {
            self.activities.removeAll { $0.id == id }
        }
    }
}

// MARK: - Modifying Apps Manager
class ModifyingAppsManager: ObservableObject {
    static let shared = ModifyingAppsManager()
    
    @Published var activities: [AppActivity] = []
    
    func addActivity(id: UUID, name: String, bundleId: String, iconURL: URL?) {
        DispatchQueue.main.async {
            if !self.activities.contains(where: { $0.id == id }) {
                let activity = AppActivity(
                    id: id,
                    name: name,
                    bundleId: bundleId,
                    iconURL: iconURL,
                    progress: 0,
                    status: .waiting,
                    activityType: .modifying
                )
                self.activities.append(activity)
            }
        }
    }
    
    func updateProgress(id: UUID, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].progress = progress
            }
        }
    }
    
    func updateStatus(id: UUID, status: AppActivity.ActivityStatus) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].status = status
                
                // Remove completed/failed after delay
                if case .completed = status {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.removeActivity(id: id)
                    }
                }
            }
        }
    }
    
    func removeActivity(id: UUID) {
        DispatchQueue.main.async {
            self.activities.removeAll { $0.id == id }
        }
    }
}

// MARK: - Installing Apps Manager
class InstallingAppsManager: ObservableObject {
    static let shared = InstallingAppsManager()
    
    @Published var activities: [AppActivity] = []
    
    func addActivity(id: UUID, name: String, bundleId: String, iconURL: URL?) {
        DispatchQueue.main.async {
            if !self.activities.contains(where: { $0.id == id }) {
                let activity = AppActivity(
                    id: id,
                    name: name,
                    bundleId: bundleId,
                    iconURL: iconURL,
                    progress: 0,
                    status: .waiting,
                    activityType: .installing
                )
                self.activities.append(activity)
            }
        }
    }
    
    func updateProgress(id: UUID, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].progress = progress
            }
        }
    }
    
    func updateStatus(id: UUID, status: AppActivity.ActivityStatus) {
        DispatchQueue.main.async {
            if let index = self.activities.firstIndex(where: { $0.id == id }) {
                self.activities[index].status = status
                
                // Remove completed/failed after delay
                if case .completed = status {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.removeActivity(id: id)
                    }
                }
            }
        }
    }
    
    func removeActivity(id: UUID) {
        DispatchQueue.main.async {
            self.activities.removeAll { $0.id == id }
        }
    }
}

// MARK: - Activity Cell View
struct ActivityCellView: View {
    let activity: AppActivity
    
    @State private var _animationOffset: CGFloat = -200
    
    var body: some View {
        HStack(spacing: 9) {
            // App icon with activity indicator
            ZStack {
                if let iconURL = activity.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            _placeholderIcon
                        }
                    }
                    .frame(width: 57, height: 57)
                    .clipShape(RoundedRectangle(cornerRadius: 12.5))
                    .saturation(0.3)
                    .opacity(0.7)
                } else {
                    _placeholderIcon
                }
                
                // Activity indicator overlay
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 28, height: 28)
                    
                    if activity.status.isActive {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: _activityIcon)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                }
            }
            
            // Activity info
            VStack(alignment: .leading, spacing: 4) {
                // App name
                Text(activity.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Activity type and bundle ID
                Text("\(_activityTypeText) • \(activity.bundleId)")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(_activityGradient)
                            .frame(width: max(geometry.size.width * activity.progress, 0), height: 6)
                            .animation(.spring(response: 0.3), value: activity.progress)
                        
                        // Shimmer for active
                        if activity.status.isActive && activity.progress < 1.0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50, height: 6)
                                .offset(x: _animationOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: 3)
                                        .frame(width: max(geometry.size.width * activity.progress, 0), height: 6)
                                )
                        }
                    }
                }
                .frame(height: 6)
                
                // Status with icon
                HStack(spacing: 4) {
                    Image(systemName: _statusIcon)
                        .font(.system(size: 10))
                        .foregroundColor(_statusColor)
                    
                    Text(activity.status.displayText)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Cancel button for active
            if activity.status.isActive {
                Button {
                    switch activity.activityType {
                    case .signing:
                        SigningAppsManager.shared.removeActivity(id: activity.id)
                    case .modifying:
                        ModifyingAppsManager.shared.removeActivity(id: activity.id)
                    case .installing:
                        InstallingAppsManager.shared.removeActivity(id: activity.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.85)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                _animationOffset = 300
            }
        }
    }
    
    private var _activityIcon: String {
        switch activity.activityType {
        case .signing: return "signature"
        case .modifying: return "pencil"
        case .installing: return "square.and.arrow.down"
        }
    }
    
    private var _activityTypeText: String {
        switch activity.activityType {
        case .signing: return .localized("Signing")
        case .modifying: return .localized("Modifying")
        case .installing: return .localized("Installing")
        }
    }
    
    private var _activityGradient: LinearGradient {
        switch activity.activityType {
        case .signing:
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        case .modifying:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case .installing:
            return LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var _statusIcon: String {
        switch activity.status {
        case .waiting: return "clock.fill"
        case .inProgress: return "gearshape.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private var _statusColor: Color {
        switch activity.status {
        case .waiting: return .orange
        case .inProgress: return .accentColor
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    private var _placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 12.5)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 57, height: 57)
            .overlay(
                Image(systemName: "app.dashed")
                    .font(.title2)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Preview
#Preview {
    List {
        ActivityCellView(activity: AppActivity(
            id: UUID(),
            name: "Instagram",
            bundleId: "com.burbn.instagram",
            iconURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/a9/ab/c4/a9abc4e4-5943-4927-d2e3-5e6e3c0b9e8a/Prod-0-0-1x_U007emarketing-0-7-0-85-220.png/100x100bb.jpg"),
            progress: 0.45,
            status: .inProgress,
            activityType: .signing
        ))
        
        ActivityCellView(activity: AppActivity(
            id: UUID(),
            name: "Spotify",
            bundleId: "com.spotify.client",
            iconURL: nil,
            progress: 0.7,
            status: .inProgress,
            activityType: .modifying
        ))
    }
}
