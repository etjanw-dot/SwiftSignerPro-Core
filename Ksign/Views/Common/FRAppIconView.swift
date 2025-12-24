//
//  FRAppIconView.swift
//  Feather
//
//  Created by samara on 18.04.2025.
//

import SwiftUI

struct FRAppIconView: View {
	private var _app: AppInfoPresentable
	private var _size: CGFloat
	
	init(app: AppInfoPresentable, size: CGFloat = 87) {
		self._app = app
		self._size = size
	}
	
	var body: some View {
		if
			let iconFilePath = Storage.shared.getAppDirectory(for: _app)?.appendingPathComponent(_app.icon ?? ""),
			let uiImage = UIImage(contentsOfFile: iconFilePath.path)
		{
			Image(uiImage: uiImage)
				.appIconStyle(size: _size)
		} else {
			// Generic app placeholder when icon is not found
			ZStack {
				RoundedRectangle(cornerRadius: _size * 0.225)
					.fill(
						LinearGradient(
							colors: [Color(.systemGray4), Color(.systemGray5)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: _size, height: _size)
				
				Image(systemName: "app.dashed")
					.font(.system(size: _size * 0.45))
					.foregroundColor(.secondary)
			}
		}
	}
}
