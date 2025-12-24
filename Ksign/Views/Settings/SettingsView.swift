//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SettingsView: View {
	private let _githubUrl = "https://github.com/ethantheDeveloper220"
    
    @State private var _showExportRepos = false
	@State private var _funnyTagline: String = FunnyTaglines.random()
    @State private var _showGitHubWebView = false
    
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				// Rainbow Header Section
				Section {
					_appHeaderView
				}
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets())
				
				// Donation section - disabled/shaded
				Section {
					HStack {
						Image(systemName: "heart.fill")
							.foregroundColor(.gray.opacity(0.5))
						Text(.localized("Support Development"))
							.foregroundColor(.gray.opacity(0.5))
						Spacer()
						Text(.localized("Coming Soon"))
							.font(.caption)
							.foregroundColor(.gray.opacity(0.5))
					}
				}
				
				// SwiftSigner Pro Account Section
				_ethSignPlusSection()
				
				// Apple ID Section for App Store
				_appleIdSection()
				
				_feedback()
				
				// General Section (like in reference)
				NBSection(.localized("General")) {
					// Appearance with rainbow gradient icon
					NavigationLink(destination: AppearanceView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.pink, .purple, .blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            Text(.localized("Appearance"))
                                .foregroundColor(.primary)
                        }
                    }
					
					// App Icon
					NavigationLink(destination: AppIconView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                Image(systemName: "app.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            Text(.localized("App Icon"))
                                .foregroundColor(.primary)
                        }
                    }
					
					NavigationLink(destination: DeviceInfoView()) {
                        Label {
                            Text(.localized("Device Info"))
                        } icon: {
                            Image(systemName: "iphone")
                                .foregroundColor(.green)
                        }
                    }
                    NavigationLink(destination: TabHapticSettingsView()) {
                        Label {
                            Text(.localized("Tab & Haptic Settings"))
                        } icon: {
                            Image(systemName: "hand.tap")
                                .foregroundColor(.purple)
                        }
                    }
				}
				
				NBSection(.localized("Features")) {
                    NavigationLink(destination: LogsView(manager: LogsManager.shared)) {
                        Label {
                            Text(.localized("Logs"))
                        } icon: {
                            Image(systemName: "apple.terminal")
                                .foregroundColor(.accentColor)
                        }
                    }
					NavigationLink(destination: SwiftSignAccountsView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(.localized("SwiftSign Accounts"))
                                    .foregroundColor(.primary)
                                    .font(.subheadline)
                                Text(.localized("Registered UDIDs & 365-day status"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
					NavigationLink(destination: AppFeaturesView()) {
                        Label {
                            Text(.localized("App Features"))
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundColor(.accentColor)
                        }
                    }
					NavigationLink(destination: AISettingsView()) {
                        Label {
                            Text("AI Settings")
                        } icon: {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
					NavigationLink(destination: LibrarySettingsView()) {
                        Label {
                            Text(.localized("Library Settings"))
                        } icon: {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(.orange)
                        }
                    }
					NavigationLink(destination: CategorySettingsView()) {
                        Label {
                            Text(.localized("Categories"))
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                    }
					NavigationLink(destination: CertificatesView()) {
                        Label {
                            Text(.localized("Certificates"))
                        } icon: {
                            Image(systemName: "signature")
                                .foregroundColor(.accentColor)
                        }
                    }
					NavigationLink(destination: SigningSettingsView()) {
                        Label {
                            Text(.localized("Signing Settings"))
                        } icon: {
                            Image(systemName: "signature")
                                .foregroundColor(.accentColor)
                        }
                    }
					NavigationLink(destination: AutoSignView()) {
                        Label {
                            Text(.localized("Auto-Sign Settings"))
                        } icon: {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                        }
                    }
					NavigationLink(destination: ConfigurationView()) {
                        Label {
                            Text(.localized("Advanced Options"))
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(.accentColor)
                        }
                    }
					NavigationLink(destination: ArchiveView()) {
                        Label {
                            Text(.localized("Archive & Extraction"))
                        } icon: {
                            Image(systemName: "archivebox")
                                .foregroundColor(.accentColor)
                        }
                    }
					#if SERVER
					NavigationLink(destination: ServerView()) {
                        Label {
                            Text(.localized("Server & SSL"))
                        } icon: {
                            Image(systemName: "server.rack")
                                .foregroundColor(.accentColor)
                        }
                    }
					#elseif IDEVICE
					NavigationLink(destination: TunnelView()) {
                        Label {
                            Text(.localized("Tunnel & Pairing"))
                        } icon: {
                            Image(systemName: "network")
                                .foregroundColor(.accentColor)
                        }
                    }
					#endif
				}
                
                NBSection(.localized("Data")) {
                    NavigationLink(destination: DataImportExportView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                Image(systemName: "externaldrive.fill.badge.icloud")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(.localized("SwiftSigner Pro Import & Export"))
                                    .foregroundColor(.primary)
                                    .font(.subheadline)
                                Text(.localized("Backup & restore your data"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        _showExportRepos = true
                    } label: {
                        Label {
                            Text(.localized("Export Repositories"))
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    NavigationLink(destination: GameTweaksView()) {
                        Label {
                            Text(.localized("Game Tweaks"))
                        } icon: {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
				
				_directories()
                
                _developer()
                
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label {
                            Text(.localized("Reset"))
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } footer: {
                    Text(.localized("Reset the applications sources, certificates, apps, and general contents."))
                }

            }
        }
        .sheet(isPresented: $_showExportRepos) {
            ExportRepositoriesView()
        }
        .sheet(isPresented: $_showGitHubWebView) {
            InAppWebView(url: URL(string: _githubUrl)!, title: .localized("GitHub"))
        }
		.onAppear {
			// Refresh tagline each time view appears
			_funnyTagline = FunnyTaglines.random()
		}
    }
}

// MARK: - View extension
extension SettingsView {
	// MARK: - SwiftSigner Pro Account Section
	@ViewBuilder
	private func _ethSignPlusSection() -> some View {
		let authService = EthSignAuthService.shared
		let syncService = EthSignCloudSyncService.shared
		
		Section {
			NavigationLink(destination: EthSignAccountView()) {
				HStack(spacing: 14) {
					// Account Icon
					ZStack {
						if authService.isAuthenticated {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
							
							Text(authService.currentUser?.displayName?.prefix(1).uppercased() ?? authService.currentUser?.email.prefix(1).uppercased() ?? "E")
								.font(.title3)
								.fontWeight(.bold)
								.foregroundColor(.white)
						} else {
							RoundedRectangle(cornerRadius: 10)
								.fill(
									LinearGradient(
										colors: [Color.accentColor, Color.purple],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
							
							Image(systemName: "person.crop.circle.badge.plus")
								.font(.title2)
								.foregroundColor(.white)
						}
					}
					
					VStack(alignment: .leading, spacing: 4) {
						if authService.isAuthenticated {
							Text(authService.currentUser?.displayName ?? "SwiftSigner Pro Account")
								.font(.subheadline)
								.fontWeight(.medium)
							
							HStack(spacing: 6) {
								if syncService.isSyncEnabled {
									Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
										.font(.caption2)
										.foregroundColor(.green)
									Text("Sync enabled")
										.font(.caption)
										.foregroundColor(.secondary)
								} else {
									Text(authService.currentUser?.email ?? "")
										.font(.caption)
										.foregroundColor(.secondary)
								}
							}
						} else {
							Text("SwiftSigner Pro")
								.font(.subheadline)
								.fontWeight(.medium)
							Text("Sign in to sync across devices")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
					
					Spacer()
					
					if syncService.syncStatus == .syncing {
						ProgressView()
							.scaleEffect(0.8)
					}
				}
			}
		} header: {
			HStack(spacing: 6) {
				Image(systemName: "cloud.fill")
					.font(.caption)
				Text("SwiftSigner Pro Account")
			}
		}
	}
	
	// MARK: - Apple ID Section for App Store
	@ViewBuilder
	private func _appleIdSection() -> some View {
		let storeClient = AppStoreClient.shared
		
		Section {
			if storeClient.isAuthenticated {
				// Logged in state
				HStack(spacing: 14) {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [.gray, .gray.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 44, height: 44)
						
						Image(systemName: "apple.logo")
							.font(.title2)
							.foregroundColor(.white)
					}
					
					VStack(alignment: .leading, spacing: 4) {
						Text("Apple ID")
							.font(.subheadline)
							.fontWeight(.medium)
						Text(storeClient.accountName ?? "Logged In")
							.font(.caption)
							.foregroundColor(.secondary)
					}
					
					Spacer()
					
					Image(systemName: "checkmark.seal.fill")
						.foregroundColor(.green)
				}
				
				Button(role: .destructive) {
					storeClient.logout()
				} label: {
					HStack {
						Spacer()
						Text("Sign Out")
						Spacer()
					}
				}
			} else {
				// Login form
				NavigationLink(destination: AppleIDSettingsView()) {
					HStack(spacing: 14) {
						ZStack {
							RoundedRectangle(cornerRadius: 10)
								.fill(
									LinearGradient(
										colors: [.gray, .black],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
							
							Image(systemName: "apple.logo")
								.font(.title2)
								.foregroundColor(.white)
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text("Apple ID")
								.font(.subheadline)
								.fontWeight(.medium)
							Text("Sign in for App Store downloads")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
			}
		} header: {
			HStack(spacing: 6) {
				Image(systemName: "apple.logo")
					.font(.caption)
				Text("App Store Account")
			}
		} footer: {
			Text("Sign in with your Apple ID to download apps from the App Store. Your credentials are stored securely on your device.")
		}
	}
	
	// MARK: - App Header with Rainbow Icon (Bigger like reference)
	private var _appHeaderView: some View {
		VStack(spacing: 16) {
			// App Icon - Much bigger like reference
			ZStack {
				// Subtle glow behind icon
				RoundedRectangle(cornerRadius: 24)
					.fill(Color.accentColor.opacity(0.2))
					.frame(width: 110, height: 110)
					.blur(radius: 20)
				
				// Check for custom icon first
				if CustomAppIconManager.shared.isCustomIconActive(),
				   let customIcon = CustomAppIconManager.shared.loadCustomIcon() {
					Image(uiImage: customIcon)
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 100, height: 100)
						.clipShape(RoundedRectangle(cornerRadius: 22))
						.shadow(color: Color.primary.opacity(0.15), radius: 12, x: 0, y: 6)
				} else if let iconFileName = Bundle.main.iconFileName,
				   let iconImage = UIImage(named: iconFileName) {
					// App Icon - displays the actual/alternate app icon
					Image(uiImage: iconImage)
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 100, height: 100)
						.clipShape(RoundedRectangle(cornerRadius: 22))
						.shadow(color: Color.primary.opacity(0.15), radius: 12, x: 0, y: 6)
				} else {
					// Fallback gradient icon if app icon not found
					RoundedRectangle(cornerRadius: 22)
						.fill(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 100, height: 100)
						.overlay(
							Image(systemName: "signature")
								.font(.system(size: 44, weight: .medium))
								.foregroundColor(.white)
						)
						.shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
				}
			}
			
			// App Name - Bigger and bolder
			Text("SwiftSigner Pro")
				.font(.title)
				.fontWeight(.bold)
				.foregroundColor(.primary)
			
			// Version Info - Clean style like reference
			Text("\(Bundle.main.version ?? "1.0") (\(Bundle.main.build ?? "1"))")
				.font(.subheadline)
				.foregroundColor(.secondary)
			
			// Funny Random Tagline with accent color
			Text(_funnyTagline)
				.font(.subheadline)
				.fontWeight(.medium)
				.foregroundColor(.accentColor)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 24)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 24)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(.secondarySystemGroupedBackground))
		)
		.padding(.horizontal)
	}
	
	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: AboutNyaView()) {
                Label(.localized("About"), systemImage: "info.circle")
            }
			
			// GitHub - active with in-app web view
			Button {
				_showGitHubWebView = true
			} label: {
				Label {
					Text(.localized("GitHub Repository"))
				} icon: {
					Image(systemName: "chevron.left.forwardslash.chevron.right")
						.foregroundColor(.accentColor)
				}
			}
			
			// Telegram - disabled/shaded
			HStack {
				Label {
					Text(.localized("Telegram Channel"))
				} icon: {
					Image(systemName: "paperplane.circle")
						.foregroundColor(.gray.opacity(0.5))
				}
				.foregroundColor(.gray.opacity(0.5))
				Spacer()
				Text(.localized("Unavailable"))
					.font(.caption)
					.foregroundColor(.gray.opacity(0.5))
			}
			
			// Discord - disabled/shaded
			HStack {
				Label {
					Text(.localized("Discord Server"))
				} icon: {
					Image(systemName: "bubble.left.and.bubble.right")
						.foregroundColor(.gray.opacity(0.5))
				}
				.foregroundColor(.gray.opacity(0.5))
				Spacer()
				Text(.localized("Unavailable"))
					.font(.caption)
					.foregroundColor(.gray.opacity(0.5))
			}
		}
	}
	
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
			Button {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			} label: {
				Label {
					Text(.localized("Open Documents"))
				} icon: {
					Image(systemName: "folder")
						.foregroundColor(.accentColor)
				}
			}
			Button {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			} label: {
				Label {
					Text(.localized("Open Archives"))
				} icon: {
					Image(systemName: "folder")
						.foregroundColor(.accentColor)
				}
			}
		} footer: {
			Text(.localized("All SwiftSigner Pro files except certificates are contained in the documents directory, here are some quick links to these."))
		}
	}
    
    @ViewBuilder
    private func _developer() -> some View {
        NBSection(.localized("Developer")) {
            // GitHub Profile - active with in-app web view
            Button {
                _showGitHubWebView = true
            } label: {
                Label {
                    Text(.localized("GitHub Profile"))
                } icon: {
                    Image(systemName: "person.circle")
                        .foregroundColor(.accentColor)
                }
            }
            
            // Twitter - disabled/shaded
            HStack {
                Label {
                    Text(.localized("Twitter / X"))
                } icon: {
                    Image(systemName: "at.circle")
                        .foregroundColor(.gray.opacity(0.5))
                }
                .foregroundColor(.gray.opacity(0.5))
                Spacer()
                Text(.localized("Unavailable"))
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Support Developer - disabled/shaded
            HStack {
                Label {
                    Text(.localized("Support Developer"))
                } icon: {
                    Image(systemName: "heart.circle")
                        .foregroundColor(.gray.opacity(0.5))
                }
                .foregroundColor(.gray.opacity(0.5))
                Spacer()
                Text(.localized("Coming Soon"))
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            NavigationLink {
                DeveloperOptionsView()
            } label: {
                Label {
                    Text(.localized("Developer Options"))
                } icon: {
                    Image(systemName: "hammer.circle")
                        .foregroundColor(.accentColor)
                }
            }
        } footer: {
            Text(.localized("Connect with the developer and access advanced options."))
        }
    }
}
