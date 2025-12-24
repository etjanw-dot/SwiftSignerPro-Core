//
//  SourcesCellView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//

import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
	var source: AltSource
	@Binding var isEditMode: Bool
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var showEditSheet: Bool = false
	
	private var appCount: Int {
		viewModel.getApps(for: source).count
	}
	
	private var hasError: Bool {
		// Source has error if it was fetched but not in the viewModel's sources dictionary
		viewModel.sources[source] == nil && !viewModel.isFinished
	}
	
	// MARK: Body
	var body: some View {
		HStack(spacing: 14) {
			// Edit Button - Only visible when in editing mode
			if isEditMode {
				Button {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
						isEditMode.toggle()
					}
				} label: {
					ZStack {
						Circle()
							.fill(Color.orange.opacity(0.15))
							.frame(width: 32, height: 32)
						
						Image(systemName: "lock.fill")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(.orange)
					}
				}
				.buttonStyle(.plain)
			}
			
			// Repo Icon
			if let iconURL = source.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.appIconStyle(size: 50)
					} else {
						_placeholderIcon
					}
				}
			} else {
				_placeholderIcon
			}
			
			// Repo Info
			VStack(alignment: .leading, spacing: 4) {
				Text(source.name ?? .localized("Unknown"))
					.font(.headline)
					.fontWeight(.semibold)
					.foregroundColor(hasError ? .red : .primary)
				
				if hasError {
					Text(.localized("Failed to load repository"))
						.font(.subheadline)
						.foregroundColor(.red)
				} else {
					Text("\(appCount) " + .localized("Apps"))
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
			
			Spacer()
			
			// Edit Actions (shown when editing)
			if isEditMode {
				HStack(spacing: 8) {
					// Modify Button
					Button {
						showEditSheet = true
					} label: {
						Image(systemName: "slider.horizontal.3")
							.font(.system(size: 16))
							.foregroundColor(.accentColor)
							.padding(8)
							.background(Circle().fill(Color.accentColor.opacity(0.15)))
					}
					.buttonStyle(.plain)
					
					// Delete Button
					Button {
						Storage.shared.deleteSource(for: source)
					} label: {
						Image(systemName: "trash.fill")
							.font(.system(size: 16))
							.foregroundColor(.red)
							.padding(8)
							.background(Circle().fill(Color.red.opacity(0.15)))
					}
					.buttonStyle(.plain)
				}
				.transition(.scale.combined(with: .opacity))
			} else if hasError {
				// Status indicator for errors
				ZStack {
					Circle()
						.fill(Color.red.opacity(0.15))
						.frame(width: 32, height: 32)
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundColor(.red)
						.font(.system(size: 14))
				}
			} else {
				// Chevron for navigation
				Image(systemName: "chevron.right")
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(isEditMode ? Color.orange.opacity(0.05) : (hasError ? Color.red.opacity(0.08) : Color(.secondarySystemBackground)))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 14)
				.stroke(isEditMode ? Color.orange.opacity(0.3) : (hasError ? Color.red.opacity(0.3) : Color.clear), lineWidth: 1)
		)
		.animation(.easeInOut(duration: 0.2), value: isEditMode)
		.swipeActions {
			_actions(for: source)
			_contextActions(for: source)
		}
		.contextMenu {
			_contextActions(for: source)
			Divider()
			_actions(for: source)
		}
		.sheet(isPresented: $showEditSheet) {
			SourceEditView(source: source)
				.presentationDetents([.medium])
		}
	}
	
	private var _placeholderIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(.tertiarySystemFill))
				.frame(width: 50, height: 50)
			Image(systemName: "questionmark.app.fill")
				.font(.title2)
				.foregroundColor(.secondary)
		}
	}
}

// MARK: - Extension: View
extension SourcesCellView {
	@ViewBuilder
	private func _actions(for source: AltSource) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteSource(for: source)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for source: AltSource) -> some View {
		Button(.localized("Copy URL"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = source.sourceURL?.absoluteString
		}
		
		Button(.localized("Edit"), systemImage: "pencil") {
			showEditSheet = true
		}
	}
}

// MARK: - Source Edit View
struct SourceEditView: View {
	let source: AltSource
	@Environment(\.dismiss) private var dismiss
	@State private var newName: String = ""
	
	var body: some View {
		NavigationStack {
			List {
				Section(.localized("Repository Info")) {
					HStack {
						Text(.localized("Name"))
						Spacer()
						TextField(.localized("Repository Name"), text: $newName)
							.textFieldStyle(.plain)
							.multilineTextAlignment(.trailing)
					}
					
					if let url = source.sourceURL?.absoluteString {
						HStack {
							Text(.localized("URL"))
							Spacer()
							Text(url)
								.font(.caption)
								.foregroundColor(.secondary)
								.lineLimit(1)
						}
					}
				}
				
				Section {
					Button(role: .destructive) {
						Storage.shared.deleteSource(for: source)
						dismiss()
					} label: {
						HStack {
							Spacer()
							Text(.localized("Delete Repository"))
							Spacer()
						}
					}
				}
			}
			.navigationTitle(.localized("Edit Repository"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(.localized("Cancel")) {
						dismiss()
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(.localized("Done")) {
						// Save changes if needed
						dismiss()
					}
					.fontWeight(.semibold)
				}
			}
			.onAppear {
				newName = source.name ?? ""
			}
		}
	}
}

