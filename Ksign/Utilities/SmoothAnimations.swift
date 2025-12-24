//
//  SmoothAnimations.swift
//  Ksign
//
//  Global smooth animation extensions for the app
//

import SwiftUI

// MARK: - Custom Animation Presets
extension Animation {
    /// Smooth spring animation for general UI transitions
    static var smoothSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1)
    }
    
    /// Quick spring for button presses
    static var quickSpring: Animation {
        .spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)
    }
    
    /// Bouncy spring for fun interactions
    static var bouncySpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)
    }
    
    /// Gentle ease for subtle transitions
    static var gentleEase: Animation {
        .easeInOut(duration: 0.3)
    }
    
    /// Fast snap for toggles and switches
    static var snap: Animation {
        .spring(response: 0.2, dampingFraction: 0.9, blendDuration: 0)
    }
}

// MARK: - View Extension for Smooth Transitions
extension View {
    /// Apply smooth appear animation
    func smoothAppear(_ isVisible: Bool, delay: Double = 0) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(.smoothSpring.delay(delay), value: isVisible)
    }
    
    /// Apply smooth slide animation from edge
    func smoothSlide(_ isVisible: Bool, edge: Edge = .bottom) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: edge == .leading ? (isVisible ? 0 : -20) : (edge == .trailing ? (isVisible ? 0 : 20) : 0),
                y: edge == .top ? (isVisible ? 0 : -20) : (edge == .bottom ? (isVisible ? 0 : 20) : 0)
            )
            .animation(.smoothSpring, value: isVisible)
    }
    
    /// Apply press animation for buttons
    func pressAnimation(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.quickSpring, value: isPressed)
    }
    
    /// Apply hover/selection highlight
    func selectionHighlight(_ isSelected: Bool) -> some View {
        self
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.smoothSpring, value: isSelected)
    }
    
    /// Apply shimmer loading effect
    func shimmer(_ isLoading: Bool) -> some View {
        self
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(
                isLoading ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isLoading
            )
    }
}

// MARK: - Animated Button Style
struct SmoothButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.quickSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SmoothButtonStyle {
    static var smooth: SmoothButtonStyle { SmoothButtonStyle() }
}

// MARK: - Animated Toggle Style
struct SmoothToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.accentColor : Color(.systemGray4))
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(.white)
                        .shadow(radius: 1)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .onTapGesture {
                    withAnimation(.smoothSpring) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

// MARK: - Staggered List Animation
struct StaggeredAnimation: ViewModifier {
    let index: Int
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                .smoothSpring.delay(Double(index) * 0.05),
                value: isVisible
            )
    }
}

extension View {
    func staggeredAppear(index: Int, isVisible: Bool) -> some View {
        modifier(StaggeredAnimation(index: index, isVisible: isVisible))
    }
}
