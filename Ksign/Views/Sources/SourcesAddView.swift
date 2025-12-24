//
//  SourcesAddView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//

import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import UniformTypeIdentifiers

// MARK: - View
struct SourcesAddView: View {
	@Environment(\.dismiss) var dismiss
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	
	@State private var _isImporting = false
	@State private var _sourceURL = ""
	@State private var _showFilePicker = false
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Add Source"), displayMode: .inline) {
			Form {
				Section {
					TextField(.localized("Source Repo URL"), text: $_sourceURL)
						.keyboardType(.URL)
				} footer: {
					Text(.localized("Enter a URL to start validation."))
				}
				
				Section {
					Button(.localized("Import"), systemImage: "square.and.arrow.down") {
						_isImporting = true
						_addCode(UIPasteboard.general.string) {
							UINotificationFeedbackGenerator().notificationOccurred(.success)
							dismiss()
						}
						
					}
					
					Button(.localized("Export"), systemImage: "doc.on.clipboard") {
						UIPasteboard.general.string = Storage.shared.getSources().map {
							$0.sourceURL!.absoluteString
						}.joined(separator: "\n")
						UINotificationFeedbackGenerator().notificationOccurred(.success)
						UIAlertController.showAlertWithOk(title: .localized("Success"), message: .localized("All sources copied to clipboard."))
					}
				} footer: {
					Text(.localized("Supports importing from KravaSign/MapleSign and ESign"))
				}
				
				// JSON File Import Section
				NBSection(.localized("File Import")) {
					Button {
						_showFilePicker = true
					} label: {
						HStack(spacing: 14) {
							ZStack {
								RoundedRectangle(cornerRadius: 10)
									.fill(
										LinearGradient(
											colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 44, height: 44)
								Image(systemName: "doc.badge.plus")
									.font(.title2)
									.foregroundColor(.accentColor)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Import JSON File"))
									.foregroundColor(.primary)
									.fontWeight(.medium)
								Text(.localized("Import repository from a JSON file"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.foregroundColor(.secondary)
						}
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				if !_isImporting {
					NBToolbarButton(
						.localized("Save"),
						style: .text,
						placement: .confirmationAction,
						isDisabled: _sourceURL.isEmpty
					) {
						FR.handleSource(_sourceURL) {
							dismiss()
						}
					}
				} else {
					ToolbarItem(placement: .confirmationAction) {
						ProgressView()
					}
				}
			}
		}
		.fileImporter(
			isPresented: $_showFilePicker,
			allowedContentTypes: [
				.json,
				UTType(filenameExtension: "json")!,
				.data,
				.text,
				.plainText,
				UTType(mimeType: "application/json") ?? .json
			],
			allowsMultipleSelection: false
		) { result in
			_handleJSONFileImport(result)
		}
	}
	
	// MARK: - JSON Repos Folder Helper
	private static var reposFolderURL: URL {
		let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let reposFolder = documentsPath.appendingPathComponent("JSON Repos", isDirectory: true)
		
		// Create folder if it doesn't exist
		if !FileManager.default.fileExists(atPath: reposFolder.path) {
			try? FileManager.default.createDirectory(at: reposFolder, withIntermediateDirectories: true)
		}
		
		return reposFolder
	}
	
	private func _handleJSONFileImport(_ result: Result<[URL], Error>) {
		switch result {
		case .success(let urls):
			guard let url = urls.first else { return }
			
			guard url.startAccessingSecurityScopedResource() else {
				UIAlertController.showAlertWithOk(
					title: .localized("Import Failed"),
					message: .localized("Could not access the selected file.")
				)
				return
			}
			defer { url.stopAccessingSecurityScopedResource() }
			
			do {
				let data = try Data(contentsOf: url)
				
				// Try to decode as ASRepository
				if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
				   let name = json["name"] as? String {
					
					// This is a valid repository JSON
					// Save it to a persistent location in JSON Repos folder
					let safeFileName = name.replacingOccurrences(of: " ", with: "_")
						.replacingOccurrences(of: "/", with: "-")
						.replacingOccurrences(of: "\\", with: "-")
					let fileName = "\(safeFileName)_\(UUID().uuidString.prefix(8)).json"
					let persistentURL = Self.reposFolderURL.appendingPathComponent(fileName)
					
					try data.write(to: persistentURL)
					
					// Now fetch and add the repository
					_dataService.fetch(from: persistentURL) { (result: RepositoryDataHandler) in
						switch result {
						case .success(let repo):
							Storage.shared.addSources(repos: [persistentURL: repo]) { _ in
								UINotificationFeedbackGenerator().notificationOccurred(.success)
								UIAlertController.showAlertWithOk(
									title: .localized("Success"),
									message: .localized("Repository '\(name)' imported successfully!")
								)
								dismiss()
							}
						case .failure(let error):
							// Clean up the file if fetch failed
							try? FileManager.default.removeItem(at: persistentURL)
							UIAlertController.showAlertWithOk(
								title: .localized("Import Failed"),
								message: error.localizedDescription
							)
						}
					}
				} else {
					throw NSError(domain: "SourcesAddView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid repository JSON format. Make sure the JSON file has a 'name' field."])
				}
			} catch {
				UIAlertController.showAlertWithOk(
					title: .localized("Import Failed"),
					message: error.localizedDescription
				)
			}
			
		case .failure(let error):
			UIAlertController.showAlertWithOk(
				title: .localized("Import Failed"),
				message: error.localizedDescription
			)
		}
	}
	
	private func _addCode(
		_ code: String?,
		competion: @escaping () -> Void
	) {
		guard let code else { return }
		
		let handler = ASDeobfuscator(with: code)
		let repoUrls = handler.decode().compactMap { URL(string: $0) }

		guard !repoUrls.isEmpty else { return }
		
		actor RepositoryCollector {
			private var repositories: [URL: ASRepository] = [:]
			
			func add(url: URL, repository: ASRepository) {
				repositories[url] = repository
			}
			
			func getAllRepositories() -> [URL: ASRepository] {
				return repositories
			}
		}
		
		let dataService = _dataService
		let collector = RepositoryCollector()
		
		Task {
			await withTaskGroup(of: Void.self) { group in
				for url in repoUrls {
					group.addTask {
						await withCheckedContinuation { continuation in
							Task { @MainActor in
								dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
									switch result {
									case .success(let data):
										Task {
											await collector.add(url: url, repository: data)
										}
									case .failure(let error):
										print("Failed to fetch \(url): \(error)")
									}
									continuation.resume()
								}
							}
						}
					}
				}
				
				await group.waitForAll()
			}
			
			let repositories = await collector.getAllRepositories()
			
			await MainActor.run {
				Storage.shared.addSources(repos: repositories) { _ in
					competion()
				}
			}
		}
	}
}



