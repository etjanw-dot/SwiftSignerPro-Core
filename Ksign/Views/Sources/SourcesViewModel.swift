//
//  SourcesViewModel.swift
//  Feather
//
//  Created by samara on 30.04.2025.
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	
	@Published var isFinished = false  // Start as false to force initial load
	@Published var sources: [AltSource: ASRepository] = [:]
	@Published var lastUpdateTime: String?
	
	init() {
		// Clear any cached data on init to ensure fresh load every launch
		sources = [:]
		isFinished = false
	}
	
	/// Clear all cached data - call this to force a full reload
	func clearCache() {
		sources = [:]
		isFinished = false
	}
	
	func getApps(for source: AltSource) -> [ASRepository.App] {
		guard let repo = sources[source] else { return [] }
		return repo.apps ?? []
	}
	
	func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		// Prevent concurrent fetches - if already fetching, return
		// But allow if not finished (initial state) or if refresh requested
		if isFinished, !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
		
		// Mark as fetching in progress
		await MainActor.run {
			isFinished = false
		}
		defer { 
			Task { @MainActor in
				isFinished = true 
			}
		}
		
		await MainActor.run {
			self.sources = [:]
		}
		
		let sourcesArray = Array(sources)
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(of: (AltSource, ASRepository?).self, returning: [AltSource: ASRepository].self) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil)
						}
						
						return await withCheckedContinuation { continuation in
							self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
								switch result {
								case .success(let repo):
									continuation.resume(returning: (source, repo))
								case .failure(_):
									continuation.resume(returning: (source, nil))
								}
							}
						}
					}
				}
				
				var results = [AltSource: ASRepository]()
				for await (source, repo) in group {
					if let repo {
						results[source] = repo
					}
				}
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}
