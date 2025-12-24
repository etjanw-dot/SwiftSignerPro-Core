//
//  TabEnum.swift
//  feather
//
//  Created by samara on 22.03.2025.
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
	case repos
	case apps
	case home
	case library
	case tweaks
	case settings
	case certificates
	case files
	case ai
	
	var title: String {
		switch self {
		case .repos:		return .localized("Repos")
		case .apps:			return .localized("Apps")
		case .home:			return .localized("Home")
		case .library: 		return .localized("Library")
		case .tweaks:		return .localized("Tweaks")
		case .settings: 	return .localized("Settings")
		case .certificates:	return .localized("Certificates")
		case .files:		return .localized("Files")
		case .ai:			return .localized("AI")
		}
	}
	
	var icon: String {
		switch self {
		case .repos: 		return "folder.fill"
		case .apps:			return "square.grid.2x2.fill"
		case .home:			return "house.fill"
		case .library: 		return "books.vertical.fill"
		case .tweaks:		return "slider.horizontal.3"
		case .settings: 	return "gearshape.fill"
		case .certificates: return "person.text.rectangle"
		case .files:		return "doc.fill"
		case .ai:			return "brain.head.profile"
		}
	}
	
	@ViewBuilder
	static func view(for tab: TabEnum) -> some View {
		switch tab {
		case .repos: SourcesView()
		case .apps: AllAppsView()
		case .home: HomeView()
		case .library: LibraryView()
		case .settings: SettingsView()
		case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
		case .files: FilesView()
		case .ai: AIView()
		#if os(iOS)
		case .tweaks: TweaksView()
		#else
		case .tweaks: Text("Tweaks are only available on iOS")
		#endif
		}
	}
	
	static var defaultTabs: [TabEnum] {
		return [
			.repos,
			.apps,
			.home,
			.library,
			.tweaks,
			.settings,
		]
	}
	
	// Tabs that can be enabled in Tab & Haptic settings
	static var customizableTabs: [TabEnum] {
		return [
			.certificates,
			.files,
			.ai
		]
	}
}
