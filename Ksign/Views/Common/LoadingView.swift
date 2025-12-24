//
//  LoadingView.swift
//  SwiftSigner Pro
//
//  Modern loading components with shimmer effects and skeleton placeholders
//

import SwiftUI

// MARK: - Shimmer Effect Modifier
/// A stable shimmer effect using opacity animation
/// Works consistently on every app launch
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    let duration: Double
    let minOpacity: Double
    let maxOpacity: Double
    
    init(
        duration: Double = 1.2,
        minOpacity: Double = 0.4,
        maxOpacity: Double = 1.0
    ) {
        self.duration = duration
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? maxOpacity : minOpacity)
            .animation(
                isAnimating ? Animation.easeInOut(duration: duration).repeatForever(autoreverses: true) : nil,
                value: isAnimating
            )
            .onAppear {
                // Small delay ensures view is fully laid out before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

extension View {
    /// Adds a shimmer loading effect to any view (pulsing opacity)
    func shimmer(
        duration: Double = 1.2,
        minOpacity: Double = 0.4,
        maxOpacity: Double = 1.0
    ) -> some View {
        modifier(ShimmerModifier(duration: duration, minOpacity: minOpacity, maxOpacity: maxOpacity))
    }
    
    /// Makes the view a skeleton placeholder with shimmer
    func skeleton() -> some View {
        self
            .redacted(reason: .placeholder)
            .shimmer()
    }
}

// MARK: - Loading State Enum
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
    
    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
    
    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

/// A beautiful loading view with glass morphism styling
struct LoadingView: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String = "Loading...", subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            
            VStack(spacing: 6) {
                Text(LocalizedStringKey(title))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

/// A simple inline loading indicator for list items
struct InlineLoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.accentColor)
            
            Text(LocalizedStringKey(message))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

/// Full screen loading overlay
struct LoadingOverlay: View {
    let isLoading: Bool
    let title: String
    let subtitle: String?
    
    init(
        isLoading: Bool,
        title: String = "Loading...",
        subtitle: String? = nil
    ) {
        self.isLoading = isLoading
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                LoadingView(title, subtitle: subtitle)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Skeleton Card View
struct SkeletonCardView: View {
    var height: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 30)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(height: 10)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 200, height: 10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shimmer()
    }
}

// MARK: - Skeleton App Cell View
struct SkeletonAppCellView: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 70, height: 32)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shimmer()
    }
}

// MARK: - Skeleton List View
struct SkeletonListView: View {
    var itemCount: Int = 5
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonAppCellView()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Skeleton Source Card View
struct SkeletonSourceCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 150, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 200, height: 12)
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shimmer()
    }
}

// MARK: - Skeleton Certificate Row
struct SkeletonCertificateRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 180, height: 12)
                
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 10)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 10)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shimmer()
    }
}

// MARK: - Async Content View
/// A view that handles loading, error, and success states for async content
struct AsyncContentView<T, LoadingContent: View, Content: View>: View {
    let loadingState: LoadingState<T>
    let loadingView: () -> LoadingContent
    let content: (T) -> Content
    let onRetry: (() -> Void)?
    
    init(
        state: LoadingState<T>,
        @ViewBuilder loading: @escaping () -> LoadingContent,
        @ViewBuilder content: @escaping (T) -> Content,
        onRetry: (() -> Void)? = nil
    ) {
        self.loadingState = state
        self.loadingView = loading
        self.content = content
        self.onRetry = onRetry
    }
    
    var body: some View {
        switch loadingState {
        case .idle, .loading:
            loadingView()
        case .loaded(let data):
            content(data)
        case .failed(let error):
            _errorView(error)
        }
    }
    
    @ViewBuilder
    private func _errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retry = onRetry {
                Button {
                    retry()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Skeleton Bulk Download Row (app with checkbox)
struct SkeletonBulkDownloadRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox placeholder
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 24, height: 24)
            
            // App icon
            RoundedRectangle(cornerRadius: 11)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
            
            // App info
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 90, height: 10)
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 8)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .shimmer()
    }
}

// MARK: - Skeleton Bulk Download View
struct SkeletonBulkDownloadView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Source filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(width: 70, height: 32)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            
            // App list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonBulkDownloadRow()
                        Divider().padding(.leading, 86)
                    }
                }
            }
        }
        .shimmer()
    }
}

// MARK: - Skeleton Download Queue Row
struct SkeletonDownloadQueueRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Icon background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 10)
            }
            
            Spacer()
            
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 16, height: 16)
        }
        .padding(.vertical, 8)
        .shimmer()
    }
}

// MARK: - Skeleton Download Queue View
struct SkeletonDownloadQueueView: View {
    var body: some View {
        List {
            // Repositories section
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonDownloadQueueRow()
                }
            } header: {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 12)
                }
            }
            
            // App Tabs section
            Section {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonDownloadQueueRow()
                }
            } header: {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                }
            }
        }
        .shimmer()
    }
}

// MARK: - Skeleton Form Toggle Row
struct SkeletonFormToggleRow: View {
    var hasSubtitle: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 14)
                
                if hasSubtitle {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 200, height: 10)
                }
            }
            
            Spacer()
            
            // Toggle
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 30)
        }
        .padding(.vertical, hasSubtitle ? 8 : 4)
        .shimmer()
    }
}

// MARK: - Skeleton Auto Sign View
struct SkeletonAutoSignView: View {
    var body: some View {
        Form {
            // Enable section
            Section {
                SkeletonFormToggleRow(hasSubtitle: true)
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 10)
            }
            
            // Icon section
            Section {
                SkeletonFormToggleRow()
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 10)
            }
            
            // Name section
            Section {
                SkeletonFormToggleRow()
                SkeletonFormToggleRow()
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 10)
            }
            
            // Tweaks section
            Section {
                SkeletonFormToggleRow(hasSubtitle: true)
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 90, height: 10)
            }
        }
        .shimmer()
    }
}

// MARK: - Skeleton Bulk Modify View
struct SkeletonBulkModifyView: View {
    var body: some View {
        VStack(spacing: 0) {
            // App selector tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 50, height: 50)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 40, height: 8)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(index == 0 ? Color(.systemGray5).opacity(0.3) : Color.clear)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Form content
            Form {
                // App Icon section
                Section {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 80)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(width: 80, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 10)
                }
                
                // Basic Info section
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 12)
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 100, height: 12)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 70, height: 10)
                }
            }
        }
        .shimmer()
    }
}

// MARK: - Skeleton Settings Row
struct SkeletonSettingsRow: View {
    var hasGradientIcon: Bool = false
    var hasSubtitle: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon background
            RoundedRectangle(cornerRadius: 8)
                .fill(hasGradientIcon ? 
                      LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                      LinearGradient(colors: [Color(.systemGray5), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: hasSubtitle ? 160 : 120, height: 14)
                
                if hasSubtitle {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 180, height: 10)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, hasSubtitle ? 6 : 2)
        .shimmer()
    }
}

// MARK: - Skeleton Settings View
struct SkeletonSettingsView: View {
    var body: some View {
        Form {
            // Header section
            Section {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 140, height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 180, height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            // General section
            Section {
                ForEach(0..<4, id: \.self) { index in
                    SkeletonSettingsRow(hasGradientIcon: index < 2)
                }
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 10)
            }
            
            // Features section
            Section {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonSettingsRow()
                }
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 10)
            }
        }
        .shimmer()
    }
}

// MARK: - Loading Content Wrapper
/// Wraps content to only show when not loading
struct LoadedContentView<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content
    
    init(isLoading: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.isLoading = isLoading
        self.content = content
    }
    
    var body: some View {
        if isLoading {
            SkeletonListView()
        } else {
            content()
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView("Loading Apps...", subtitle: "Please wait while we fetch your content")
        
        InlineLoadingView("Fetching repositories...")
        
        SkeletonAppCellView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}

