//
//  SourceAppsCellView.swift
//  Feather
//
//  Created by samara on 3.05.2025.
//

import SwiftUI
import AltSourceKit
import NimbleViews
import Combine
import NukeUI

// MARK: - App Cell View
struct SourceAppsCellView: View {
    @AppStorage("Feather.storeCellAppearance") private var _storeCellAppearance: Int = 0
    
    var source: ASRepository
    var app: ASRepository.App
    
    var body: some View {
        HStack(spacing: 14) {
            // App Icon
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image.appIconStyle(size: 60)
                    } else {
                        _placeholderIcon
                    }
                }
            } else {
                _placeholderIcon
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.currentName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let version = app.currentVersion {
                        Text("Version: \(version)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let date = app.currentDate?.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Download indicator area - reserved for chevron in list
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var _placeholderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 60, height: 60)
            Image(systemName: "app.fill")
                .font(.title)
                .foregroundColor(.secondary)
        }
    }
    
    static func appDescription(app: ASRepository.App) -> String {
        let optionalComponents: [String?] = [
            app.currentVersion,
            app.currentDescription ?? .localized("An awesome application")
        ]
        
        let components: [String] = optionalComponents.compactMap { value in
            guard
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                !trimmed.isEmpty
            else {
                return nil
            }
            
            return trimmed
        }
        
        return components.joined(separator: " • ")
    }
}
