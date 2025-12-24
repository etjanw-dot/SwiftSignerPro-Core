//
//  UIImage+resize.swift
//  feather
//
//  Created by samara on 8/13/24.
//

import UIKit.UIImage
import AVFoundation

extension UIImage {
	/// Resize image to a square 180x180 for iOS app icons
	public func resizeToSquare() -> UIImage? {
		// Target size for iOS app icons (@3x = 180x180)
		let targetSize: CGFloat = 180
		
		// First crop to square
		let size = min(self.size.width, self.size.height)
		let rect = CGRect(
			x: (self.size.width - size) / 2,
			y: (self.size.height - size) / 2,
			width: size,
			height: size
		)
		
		// Crop to square
		guard let cgImage = self.cgImage,
			  let croppedCGImage = cgImage.cropping(to: rect) else {
			return nil
		}
		let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: self.imageOrientation)
		
		// Then resize to 180x180
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSize, height: targetSize), format: format)
		
		let resized = renderer.image { _ in
			croppedImage.draw(in: CGRect(origin: .zero, size: CGSize(width: targetSize, height: targetSize)))
		}
		
		return resized
	}
	
	public func resize(_ width: Int, _ height: Int) -> UIImage {
		let maxSize = CGSize(width: width, height: height)
		
		let availableRect = AVFoundation.AVMakeRect(
			aspectRatio: self.size,
			insideRect: .init(origin: .zero, size: maxSize)
		)
		let targetSize = availableRect.size
		
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
		
		let resized = renderer.image { _ in
			self.draw(in: CGRect(origin: .zero, size: targetSize))
		}
		
		return resized
	}
}
