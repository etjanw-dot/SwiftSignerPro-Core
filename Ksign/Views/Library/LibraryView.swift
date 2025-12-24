//
//  ContentView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	@ObservedObject var downloadingAppsManager = DownloadingAppsManager.shared
	@ObservedObject var signingAppsManager = SigningAppsManager.shared
	@ObservedObject var modifyingAppsManager = ModifyingAppsManager.shared
	@ObservedObject var installingAppsManager = InstallingAppsManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _selectedAppDylibsPresenting: AnyApp?
	@State private var _selectedModifyAppPresenting: AnyApp?
	@State private var _isBulkSigningPresenting = false
	@State private var _isBulkModifyPresenting = false
	@State private var _isBulkDownloadPresenting = false
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _isImportFromRepoPresenting = false
	@State private var _isImportFromAppStorePresenting = false
	@State private var _showCategorySettings = false
	@State private var _showQueueView = false
	@State private var _selectedCategoryFolder: AppCategory?
	@State private var _editingCategory: AppCategory?

	@State private var _alertDownloadString: String = "" // for _isDownloadingPresenting
	@State private var _searchText = ""
	@State private var _selectedTab: Int = 0 // 0 for Downloaded, 1 for Signed, 2 for Categories
	
	// MARK: Edit Mode
	@State private var _isEditMode = false
	@State private var _selectedApps: Set<String> = []
	
	@Namespace private var _namespace
	
	// MARK: Loading State
	@State private var _isInitialLoad = true
	
	// horror
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
			(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
	@FetchRequest(
		entity: AppCategory.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)],
		animation: .snappy
	) private var _categories: FetchedResults<AppCategory>
	
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Library")) {
			VStack(spacing: 0) {
				// Tab Switcher - icon only for unselected, icon+text for selected
				_glassSegmentedControl()
					.padding(.horizontal)
					.padding(.vertical, 12)
				
				NBListAdaptable {
					// Quick Stats Hero Section (always visible)
					Section {
						_quickStatsHero()
							.padding(.horizontal, 16)
							.padding(.vertical, 8)
					}
					.listRowBackground(Color.clear)
					.listRowInsets(EdgeInsets())
					.listRowSeparator(.hidden)
					
					// Recently Signed Carousel
					if _searchText.isEmpty && !_filteredSignedApps.isEmpty {
						Section {
							_recentSignedCarousel()
								.padding(.vertical, 8)
						}
						.listRowBackground(Color.clear)
						.listRowInsets(EdgeInsets())
						.listRowSeparator(.hidden)
					}
					
					// Recently Downloaded Carousel
					if _searchText.isEmpty && !_filteredImportedApps.isEmpty {
						Section {
							_recentDownloadedCarousel()
								.padding(.vertical, 8)
						}
						.listRowBackground(Color.clear)
						.listRowInsets(EdgeInsets())
						.listRowSeparator(.hidden)
					}
					
					// Categories Section (iOS-style folders)
					if _searchText.isEmpty && (!_filteredImportedApps.isEmpty || !_filteredSignedApps.isEmpty) {
						_categoriesFolderSection()
					}
					
					if _selectedTab == 0 {
						// Show downloading apps at the top
						if !downloadingAppsManager.downloads.isEmpty {
							NBSection(
								.localized("Downloading"),
								secondary: downloadingAppsManager.downloads.count.description
								) {
									ForEach(downloadingAppsManager.downloads) { app in
										DownloadingAppCellView(app: app)
									}
								}
							}
							
							// Signing Apps Section
							if !signingAppsManager.activities.isEmpty {
								NBSection(
									.localized("Signing Apps"),
									secondary: signingAppsManager.activities.count.description
								) {
									ForEach(signingAppsManager.activities) { activity in
										ActivityCellView(activity: activity)
									}
								}
							}
							
							// Modifying Apps Section
							if !modifyingAppsManager.activities.isEmpty {
								NBSection(
									.localized("Modifying Apps"),
									secondary: modifyingAppsManager.activities.count.description
								) {
									ForEach(modifyingAppsManager.activities) { activity in
										ActivityCellView(activity: activity)
									}
								}
							}
							
							// Installing Apps Section
							if !installingAppsManager.activities.isEmpty {
								NBSection(
									.localized("Installing Apps"),
									secondary: installingAppsManager.activities.count.description
								) {
									ForEach(installingAppsManager.activities) { activity in
										ActivityCellView(activity: activity)
									}
								}
							}
							
						NBSection(
							.localized("Downloaded Apps"),
							secondary: _filteredImportedApps.count.description
						) {
							ForEach(_filteredImportedApps, id: \.uuid) { app in
								LibraryCellView(
									app: app,
									selectedInfoAppPresenting: $_selectedInfoAppPresenting,
									selectedSigningAppPresenting: $_selectedSigningAppPresenting,
									selectedInstallAppPresenting: $_selectedInstallAppPresenting,
									selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
									selectedModifyAppPresenting: $_selectedModifyAppPresenting,
									isEditMode: $_isEditMode,
									selectedApps: $_selectedApps
								)
								.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
							}
						}
					} else {
						// Installing Apps Section (also show on signed tab)
						if !installingAppsManager.activities.isEmpty {
							NBSection(
								.localized("Installing Apps"),
								secondary: installingAppsManager.activities.count.description
							) {
								ForEach(installingAppsManager.activities) { activity in
									ActivityCellView(activity: activity)
								}
							}
						}
						
						NBSection(
							.localized("Signed Apps"),
							secondary: _filteredSignedApps.count.description
						) {
							ForEach(_filteredSignedApps, id: \.uuid) { app in
								LibraryCellView(
									app: app,
									selectedInfoAppPresenting: $_selectedInfoAppPresenting,
									selectedSigningAppPresenting: $_selectedSigningAppPresenting,
									selectedInstallAppPresenting: $_selectedInstallAppPresenting,
									selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
									selectedModifyAppPresenting: $_selectedModifyAppPresenting,
									isEditMode: $_isEditMode,
									selectedApps: $_selectedApps
								)
								.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
							}
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
            .overlay {
                if
                    _filteredSignedApps.isEmpty,
                    _filteredImportedApps.isEmpty
                {
                    if _isInitialLoad {
                        // Show skeleton loading that matches the library list layout
                        SkeletonListView()
                    } else if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label(.localized("No Apps"), systemImage: "questionmark.app.fill")
                        } description: {
                            Text(.localized("Get started by importing your first IPA file."))
                        } actions: {
                            Menu {
                                _importActions()
                            } label: {
                                Text("Import").bg()
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Mark initial load as complete after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        _isInitialLoad = false
                    }
                }
            }
			.toolbar {
				if _isEditMode {
					ToolbarItem(placement: .topBarLeading) {
						Button {
							_toggleEditMode()
						} label: {
							NBButton(.localized("Done"), systemImage: "", style: .text)
						}
					}
					
					ToolbarItemGroup(placement: .topBarTrailing) {
						Button {
							_isBulkSigningPresenting = true
						} label: {
							NBButton(.localized("Sign"), systemImage: "signature", style: .icon)
						}
                        .disabled(_selectedApps.isEmpty)
						
						Button {
							_bulkDeleteSelectedApps()
						} label: {
							NBButton(.localized("Delete"), systemImage: "trash", style: .icon)
						}
						.disabled(_selectedApps.isEmpty)
					}
				} else {
					ToolbarItem(placement: .topBarLeading) {
						Button {
							_toggleEditMode()
						} label: {
							NBButton(.localized("Edit"), systemImage: "", style: .text)
						}
					}
					
					// Plus Menu - Import & Bulk Operations
					ToolbarItem(placement: .topBarTrailing) {
						Menu {
							// Import Section
							Section(.localized("Import")) {
								Button {
									_isImportingPresenting = true
								} label: {
									Label(.localized("Import from Files"), systemImage: "folder.fill")
								}
								
								Button {
									_isDownloadingPresenting = true
								} label: {
									Label(.localized("Import from URL"), systemImage: "link")
								}
								
								Button {
									_isImportFromRepoPresenting = true
								} label: {
									Label(.localized("Import from Repo"), systemImage: "square.stack.3d.down.right.fill")
								}
							}
							
							// App Store Section
							Section(.localized("App Store")) {
								Button {
									_isImportFromAppStorePresenting = true
								} label: {
									Label(.localized("Import from App Store"), systemImage: "apple.logo")
								}
							}
							
							// Bulk Operations Section
							Section(.localized("Bulk Operations")) {
								Button {
									// Select all and open bulk signer
									_isEditMode = true
									_selectedApps = Set(_filteredImportedApps.compactMap { $0.uuid })
									_isBulkSigningPresenting = true
								} label: {
									Label(.localized("Bulk Signer"), systemImage: "signature")
								}
								.disabled(_filteredImportedApps.isEmpty)
								
								Button {
									// Select all and open bulk modify
									_isEditMode = true
									_selectedApps = Set(_filteredImportedApps.compactMap { $0.uuid })
									_isBulkModifyPresenting = true
								} label: {
									Label(.localized("Bulk Modify"), systemImage: "pencil.and.outline")
								}
								.disabled(_filteredImportedApps.isEmpty)
								
								Button {
									_isBulkDownloadPresenting = true
								} label: {
									Label(.localized("Bulk Download"), systemImage: "arrow.down.circle.fill")
								}
							}
						} label: {
							Image(systemName: "plus.circle.fill")
								.font(.title3)
						}
					}
					
					// Queue View button
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							_showQueueView = true
						} label: {
							ZStack(alignment: .topTrailing) {
								Image(systemName: "tray.full.fill")
									.font(.title3)
								
								// Badge for active downloads
								if !downloadManager.downloads.isEmpty {
									Text("\(downloadManager.downloads.count)")
										.font(.system(size: 10, weight: .bold))
										.foregroundColor(.white)
										.padding(3)
										.background(Circle().fill(Color.red))
										.offset(x: 8, y: -8)
								}
							}
						}
					}
					
					// Folder/Category button
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							_showCategorySettings = true
						} label: {
							Image(systemName: "folder.badge.gearshape")
								.font(.title3)
						}
					}
				}
			}
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.large])
					.presentationDragIndicator(.visible)
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base, signAndInstall: app.signAndInstall)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.fullScreenCover(item: $_selectedAppDylibsPresenting) { app in
                DylibsView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.fullScreenCover(item: $_selectedModifyAppPresenting) { app in
				ModifyView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.fullScreenCover(isPresented: $_isBulkSigningPresenting) {
				BulkSigningView(apps: _selectedApps.compactMap { id in
					(_importedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
					?? (_signedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
				})
				.compatNavigationTransition(id: _selectedApps.joined(separator: ","), ns: _namespace)
				.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ksign.bulkSigningFinished"))) { notification in
					_toggleEditMode()
					_selectedTab = 1
				}
			}
			.fullScreenCover(isPresented: $_isBulkModifyPresenting) {
				BulkModifyView(apps: _selectedApps.compactMap { id in
					(_importedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
					?? (_signedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
				})
				.compatNavigationTransition(id: _selectedApps.joined(separator: ","), ns: _namespace)
				.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ksign.bulkModifyFinished"))) { notification in
					_toggleEditMode()
				}
			}
			.sheet(isPresented: $_isBulkDownloadPresenting) {
				BulkDownloadView()
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for ipas in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let downloadId = UUID()
							
							// Add to DownloadingAppsManager
							let appName = ipas.deletingPathExtension().lastPathComponent
							let downloadingApp = DownloadingApp(
								id: downloadId,
								name: appName,
								bundleId: "importing.file",
								iconURL: nil,
								status: .downloading,
								progress: 0
							)
							DownloadingAppsManager.shared.addDownload(downloadingApp)
							
							let dl = downloadManager.startArchive(from: ipas, id: id)
							downloadManager.handlePachageFile(url: ipas, dl: dl) { err in
								if let error = err {
									DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .failed(error.localizedDescription))
									UIAlertController.showAlertWithOk(title: "Error", message: .localized("Whoops!, something went wrong when extracting the file. \nMaybe try switching the extraction library in the settings?"))
								} else {
									DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 1.0)
									DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .completed)
								}
								
								// Remove after delay
								Task {
									try? await Task.sleep(nanoseconds: 3_000_000_000)
									await MainActor.run {
										DownloadingAppsManager.shared.removeDownload(id: downloadId)
									}
								}
							}
						}
					}
				)
			}
			.alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
				TextField(.localized("URL"), text: $_alertDownloadString)
				Button(.localized("Cancel"), role: .cancel) {
					_alertDownloadString = ""
				}
				Button(.localized("OK")) {
					if let url = URL(string: _alertDownloadString) {
						let downloadId = UUID()
						let appName = url.deletingPathExtension().lastPathComponent
						
						// Add to DownloadingAppsManager
						let downloadingApp = DownloadingApp(
							id: downloadId,
							name: appName.isEmpty ? "IPA Download" : appName,
							bundleId: "importing.url",
							iconURL: nil,
							status: .downloading,
							progress: 0
						)
						DownloadingAppsManager.shared.addDownload(downloadingApp)
						
						let uniqueId = "FeatherManualDownload_\(UUID().uuidString)"
						_ = downloadManager.startDownload(from: url, id: uniqueId)
						
						// Monitor progress
						Task {
							var lastProgress: Double = 0
							while downloadManager.getDownload(by: uniqueId) != nil {
								if let dl = downloadManager.getDownload(by: uniqueId) {
									let progress = dl.overallProgress
									if abs(progress - lastProgress) > 0.01 {
										lastProgress = progress
										await MainActor.run {
											DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: progress)
											if progress >= 0.75 {
												DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .extracting)
											}
										}
									}
								}
								try? await Task.sleep(nanoseconds: 100_000_000)
							}
							
							// Complete
							await MainActor.run {
								DownloadingAppsManager.shared.updateProgress(id: downloadId, progress: 1.0)
								DownloadingAppsManager.shared.updateStatus(id: downloadId, status: .completed)
							}
							
							try? await Task.sleep(nanoseconds: 3_000_000_000)
							await MainActor.run {
								DownloadingAppsManager.shared.removeDownload(id: downloadId)
							}
						}
					}
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("feather.installApp"))) { notification in
                if let app = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: app)
				}
			}
			.sheet(isPresented: $_isImportFromRepoPresenting) {
				ImportFromRepoView()
			}
			.sheet(isPresented: $_isImportFromAppStorePresenting) {
				ImportFromAppStoreView()
			}
			.sheet(isPresented: $_showCategorySettings) {
				NavigationView {
					CategorySettingsView()
				}
			}
			.sheet(item: $_selectedCategoryFolder) { category in
				CategoryFolderView(
					category: category,
					selectedInfoAppPresenting: $_selectedInfoAppPresenting,
					selectedSigningAppPresenting: $_selectedSigningAppPresenting,
					selectedInstallAppPresenting: $_selectedInstallAppPresenting,
					selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
					selectedModifyAppPresenting: $_selectedModifyAppPresenting
				)
			}
			.sheet(item: $_editingCategory) { category in
				CategoryEditView(category: category)
			}
			.sheet(isPresented: $_showQueueView) {
				DownloadQueueView()
			}
        }
    }
}

extension LibraryView {
    @ViewBuilder
    private func _importActions() -> some View {
        // Import from Files
        Button {
            _isImportingPresenting = true
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Import from Files"))
                        .font(.body)
                    Text(.localized("Select IPA files from device"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
            }
        }
        
        // Import from URL
        Button {
            _isDownloadingPresenting = true
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Import from URL"))
                        .font(.body)
                    Text(.localized("Download IPA from web link"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "globe")
                    .foregroundColor(.green)
            }
        }
        
        Divider()
        
        // Import from Repo - Featured
        Button {
            _isImportFromRepoPresenting = true
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Import from Repo"))
                        .font(.body)
                        .fontWeight(.medium)
                    Text(.localized("Browse apps from your repositories"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.purple)
            }
        }
        
        // Import from App Store
        Button {
            _isImportFromAppStorePresenting = true
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Import from App Store"))
                        .font(.body)
                        .fontWeight(.medium)
                    Text(.localized("Download apps with Apple ID"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "apple.logo")
                    .foregroundColor(.primary)
            }
        }
    }
}


// MARK: - Extension: View (Edit Mode Functions)
extension LibraryView {
	private func _toggleEditMode() {
		withAnimation(.easeInOut(duration: 0.3)) {
			_isEditMode.toggle()
			if !_isEditMode {
				_selectedApps.removeAll()
			}
		}
	}
	
	private func _bulkDeleteSelectedApps() {
		let appsToDelete = _selectedApps
		
		withAnimation(.easeInOut(duration: 0.5)) {
			for appUUID in appsToDelete {
				if let signedApp = _signedApps.first(where: { $0.uuid == appUUID }) {
					Storage.shared.deleteApp(for: signedApp)
				} else if let importedApp = _importedApps.first(where: { $0.uuid == appUUID }) {
					Storage.shared.deleteApp(for: importedApp)
				}
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			_selectedApps.removeAll()
			 _toggleEditMode()
		}
	}
}

// MARK: - Extension: View (Import Button Section Header)
extension LibraryView {
	private func sectionHeader(title: String, count: Int) -> some View {
		HStack {
			VStack(alignment: .leading) {
				Text(title)
					.font(.headline)
				Text("\(count)")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Button(action: {
				_isImportingPresenting = true
			}) {
				Text(.localized("Import"))
					.font(.subheadline)
					.foregroundColor(.accentColor)
			}
		}
		.padding(.horizontal)
	}
}

// MARK: - Extension: View (Categories Folder Section)
extension LibraryView {
	@ViewBuilder
	private func _categoriesFolderSection() -> some View {
		Section {
			VStack(alignment: .leading, spacing: 8) {
				// Section header with edit button
				HStack {
					Text(.localized("Categories"))
						.font(.subheadline)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)
					
					Spacer()
					
					if !_categories.isEmpty {
						Button {
							withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
								_isEditMode.toggle()
								if !_isEditMode {
									_selectedApps.removeAll()
								}
							}
						} label: {
							Text(_isEditMode ? .localized("Done") : .localized("Edit"))
								.font(.caption)
								.fontWeight(.medium)
								.foregroundColor(.accentColor)
						}
					}
				}
				.padding(.horizontal)
				
				if _categories.isEmpty {
					// Empty state for categories
					Button {
						_showCategorySettings = true
					} label: {
						HStack(spacing: 16) {
							ZStack {
								RoundedRectangle(cornerRadius: 16)
									.fill(Color.accentColor.opacity(0.1))
									.frame(width: 60, height: 60)
								
								Image(systemName: "folder.badge.plus")
									.font(.system(size: 24))
									.foregroundColor(.accentColor)
							}
							
							VStack(alignment: .leading, spacing: 4) {
								Text(.localized("No Categories Yet"))
									.font(.subheadline)
									.fontWeight(.semibold)
									.foregroundColor(.primary)
								
								Text(.localized("Organize your apps into folders"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "plus.circle.fill")
								.font(.title2)
								.foregroundColor(.accentColor)
						}
						.padding(.horizontal)
						.padding(.vertical, 12)
						.background(
							RoundedRectangle(cornerRadius: 16)
								.fill(Color(.secondarySystemGroupedBackground))
						)
						.padding(.horizontal)
					}
					.buttonStyle(.plain)
				} else {
					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 16) {
							ForEach(_categories, id: \.uuid) { category in
								_categoryFolderButton(category)
							}
							
							// Add new category button (hide in edit mode)
							if !_isEditMode {
								Button {
									_showCategorySettings = true
								} label: {
									VStack(spacing: 8) {
										ZStack {
											RoundedRectangle(cornerRadius: 16)
												.fill(Color(uiColor: .quaternarySystemFill))
												.frame(width: 70, height: 70)
											
											Image(systemName: "folder.badge.plus")
												.font(.system(size: 24))
												.foregroundColor(.secondary)
										}
										
										Text(.localized("New"))
											.font(.caption)
											.foregroundColor(.secondary)
									}
								}
								.buttonStyle(.plain)
							}
						}
						.padding(.horizontal)
						.padding(.vertical, 8)
					}
				}
			}
		}
		.listRowBackground(Color.clear)
		.listRowInsets(EdgeInsets())
	}
	
	@ViewBuilder
	private func _categoryFolderButton(_ category: AppCategory) -> some View {
		let categoryColor = Color(category.color ?? "blue")
		let appCount = Storage.shared.getCategoryAppCount(category)
		
		ZStack(alignment: .topLeading) {
			Button {
				if _isEditMode {
					// In edit mode, show edit sheet for this category
					_editingCategory = category
				} else {
					_selectedCategoryFolder = category
				}
			} label: {
				VStack(spacing: 8) {
					// iOS-style folder icon
					ZStack {
						RoundedRectangle(cornerRadius: 16)
							.fill(
								LinearGradient(
									colors: [categoryColor.opacity(0.25), categoryColor.opacity(0.1)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 70, height: 70)
							.overlay(
								RoundedRectangle(cornerRadius: 16)
									.stroke(_isEditMode ? categoryColor : Color.clear, lineWidth: 2)
							)
						
						Image(systemName: category.icon ?? "folder.fill")
							.font(.system(size: 28))
							.foregroundColor(categoryColor)
						
						// App count badge (hide in edit mode)
						if appCount > 0 && !_isEditMode {
							Text("\(appCount)")
								.font(.system(size: 10, weight: .bold))
								.foregroundColor(.white)
								.padding(.horizontal, 5)
								.padding(.vertical, 2)
								.background(categoryColor)
								.clipShape(Capsule())
								.offset(x: 22, y: -22)
						}
					}
					
					Text(category.name ?? "Folder")
						.font(.caption)
						.fontWeight(.medium)
						.foregroundColor(.primary)
						.lineLimit(1)
				}
			}
			.buttonStyle(.plain)
			.scaleEffect(_isEditMode ? 0.95 : 1.0)
			.animation(_isEditMode ? .easeInOut(duration: 0.15).repeatForever(autoreverses: true) : .default, value: _isEditMode)
			
			// Delete button in edit mode
			if _isEditMode {
				Button {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
						Storage.shared.deleteCategory(category)
					}
				} label: {
					ZStack {
						Circle()
							.fill(Color.red)
							.frame(width: 22, height: 22)
						
						Image(systemName: "minus")
							.font(.system(size: 12, weight: .bold))
							.foregroundColor(.white)
					}
				}
				.offset(x: -5, y: -5)
			}
		}
		.contextMenu {
			Button(.localized("Open"), systemImage: "folder") {
				_selectedCategoryFolder = category
			}
			
			Divider()
			
			Button(.localized("Edit"), systemImage: "pencil") {
				_editingCategory = category
			}
			
			Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
				Storage.shared.deleteCategory(category)
			}
		}
	}
}

// MARK: - Extension: View (Glass Segmented Control)
extension LibraryView {
	@ViewBuilder
	private func _glassSegmentedControl() -> some View {
		let tabs = [
			(0, "Downloaded", "arrow.down.circle.fill"),
			(1, "Signed", "checkmark.seal.fill")
		]
		
		HStack(spacing: 8) {
			ForEach(tabs, id: \.0) { tab in
				Button {
					withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
						_selectedTab = tab.0
					}
					UIImpactFeedbackGenerator(style: .light).impactOccurred()
				} label: {
					HStack(spacing: 6) {
						Image(systemName: tab.2)
							.font(.system(size: 16, weight: .semibold))
						
						// Only show text if selected
						if _selectedTab == tab.0 {
							Text(.localized(tab.1))
								.font(.system(size: 14, weight: .semibold))
								.lineLimit(1)
								.transition(.asymmetric(
									insertion: .opacity.combined(with: .scale(scale: 0.8)),
									removal: .opacity.combined(with: .scale(scale: 0.8))
								))
						}
					}
					.foregroundColor(_selectedTab == tab.0 ? .white : .secondary)
					.padding(.horizontal, _selectedTab == tab.0 ? 16 : 12)
					.padding(.vertical, 10)
					.background(
						Group {
							if _selectedTab == tab.0 {
								RoundedRectangle(cornerRadius: 12)
									.fill(
										LinearGradient(
											colors: [
												Color.accentColor.opacity(0.95),
												Color.accentColor.opacity(0.75)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
							} else {
								RoundedRectangle(cornerRadius: 12)
									.fill(Color(.tertiarySystemFill))
							}
						}
					)
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(
								_selectedTab == tab.0 ? Color.white.opacity(0.3) : Color.clear,
								lineWidth: 1
							)
					)
				}
				.buttonStyle(.plain)
			}
			
			Spacer()
		}
		.animation(.spring(response: 0.35, dampingFraction: 0.8), value: _selectedTab)
	}
}

// MARK: - Extension: View (Quick Stats Hero)
extension LibraryView {
	@ViewBuilder
	private func _quickStatsHero() -> some View {
		HStack(spacing: 10) {
			_statCard(
				title: .localized("Downloaded"),
				count: _filteredImportedApps.count,
				icon: "arrow.down.app.fill",
				color: .blue,
				isSelected: _selectedTab == 0
			) {
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					_selectedTab = 0
				}
			}
			
			_statCard(
				title: .localized("Signed"),
				count: _filteredSignedApps.count,
				icon: "checkmark.seal.fill",
				color: .green,
				isSelected: _selectedTab == 1
			) {
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					_selectedTab = 1
				}
			}
			
			_statCard(
				title: .localized("Categories"),
				count: _categories.count,
				icon: "folder.fill",
				color: .orange,
				isSelected: false
			) {
				_showCategorySettings = true
			}
		}
	}
	
	@ViewBuilder
	private func _statCard(title: String, count: Int, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			VStack(spacing: 8) {
				HStack {
					Image(systemName: icon)
						.font(.title3)
						.foregroundColor(color)
					Spacer()
				}
				HStack {
					Text("\(count)")
						.font(.title)
						.fontWeight(.bold)
					Spacer()
				}
				HStack {
					Text(title)
						.font(.caption)
						.foregroundColor(.secondary)
					Spacer()
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(Color(.secondarySystemGroupedBackground))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(isSelected ? color.opacity(0.5) : color.opacity(0.2), lineWidth: isSelected ? 2 : 1)
			)
			.scaleEffect(isSelected ? 1.02 : 1.0)
		}
		.buttonStyle(.plain)
		.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
	}
}

// MARK: - Extension: View (Recent Apps Carousels)
extension LibraryView {
	@ViewBuilder
	private func _recentSignedCarousel() -> some View {
		if !_filteredSignedApps.isEmpty {
			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Text(.localized("Recently Signed"))
						.font(.headline)
						.fontWeight(.bold)
					Spacer()
					Button {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
							_selectedTab = 1
						}
					} label: {
						Text(.localized("See All"))
							.font(.caption)
							.foregroundColor(.accentColor)
					}
				}
				.padding(.horizontal, 16)
				
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 14) {
						ForEach(_filteredSignedApps.prefix(8), id: \.uuid) { app in
							_recentSignedAppCard(app: app)
						}
					}
					.padding(.horizontal, 16)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _recentDownloadedCarousel() -> some View {
		if !_filteredImportedApps.isEmpty {
			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Text(.localized("Recently Downloaded"))
						.font(.headline)
						.fontWeight(.bold)
					Spacer()
					Button {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
							_selectedTab = 0
						}
					} label: {
						Text(.localized("See All"))
							.font(.caption)
							.foregroundColor(.accentColor)
					}
				}
				.padding(.horizontal, 16)
				
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 14) {
						ForEach(_filteredImportedApps.prefix(8), id: \.uuid) { app in
							_recentDownloadedAppCard(app: app)
						}
					}
					.padding(.horizontal, 16)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _recentSignedAppCard(app: Signed) -> some View {
		Button {
			_selectedInstallAppPresenting = AnyApp(base: app)
		} label: {
			VStack(spacing: 8) {
				if let iconURL = app.iconURL {
					AsyncImage(url: iconURL) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} placeholder: {
						RoundedRectangle(cornerRadius: 16)
							.fill(Color.green.opacity(0.2))
							.overlay(
								Image(systemName: "checkmark.seal.fill")
									.font(.title2)
									.foregroundColor(.green)
							)
					}
					.frame(width: 70, height: 70)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				} else {
					RoundedRectangle(cornerRadius: 16)
						.fill(Color.green.opacity(0.2))
						.frame(width: 70, height: 70)
						.overlay(
							Image(systemName: "checkmark.seal.fill")
								.font(.title2)
								.foregroundColor(.green)
						)
				}
				Text(app.name ?? "")
					.font(.caption)
					.fontWeight(.medium)
					.lineLimit(1)
					.foregroundColor(.primary)
			}
			.frame(width: 80)
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	private func _recentDownloadedAppCard(app: Imported) -> some View {
		Button {
			_selectedSigningAppPresenting = AnyApp(base: app)
		} label: {
			VStack(spacing: 8) {
				if let iconURL = app.iconURL {
					AsyncImage(url: iconURL) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} placeholder: {
						RoundedRectangle(cornerRadius: 16)
							.fill(Color.blue.opacity(0.2))
							.overlay(
								Image(systemName: "arrow.down.app.fill")
									.font(.title2)
									.foregroundColor(.blue)
							)
					}
					.frame(width: 70, height: 70)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				} else {
					RoundedRectangle(cornerRadius: 16)
						.fill(Color.blue.opacity(0.2))
						.frame(width: 70, height: 70)
						.overlay(
							Image(systemName: "arrow.down.app.fill")
								.font(.title2)
								.foregroundColor(.blue)
						)
				}
				Text(app.name ?? "")
					.font(.caption)
					.fontWeight(.medium)
					.lineLimit(1)
					.foregroundColor(.primary)
			}
			.frame(width: 80)
		}
		.buttonStyle(.plain)
	}
}
