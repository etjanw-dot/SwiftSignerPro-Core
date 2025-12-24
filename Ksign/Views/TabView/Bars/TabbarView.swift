//
//  TabbarView.swift
//  feather
//
//  Created by samara on 23.03.2025.
//

import SwiftUI

struct TabbarView: View {
    @StateObject private var tabSettings = TabSettingsManager.shared
    @State private var selectedTab: TabEnum = TabSettingsManager.shared.defaultTab

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(tabSettings.enabledTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
        .onChange(of: selectedTab) { oldValue, newValue in
            tabSettings.triggerHaptic()
        }
        .onAppear {
            selectedTab = tabSettings.defaultTab
        }
	}
}
