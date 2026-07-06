//
//  Extensions.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

extension TimeInterval {
    var clockString: String {
        let s = Int(self)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

extension View {
    /// Soft, layered shadow used on all floating surfaces.
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    /// 3D lifted card — elevated surface with deep layered shadows and subtle tilt.
    func card3D(depth: CGFloat = 12, cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 3)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: depth)
                    .shadow(color: .black.opacity(0.04), radius: 24, y: depth * 1.5)
            )
    }

    /// Perspective tilt that responds to a drag offset — for interactive 3D cards.
    func tilt3D(x: CGFloat = 0, y: CGFloat = 0, perspective: CGFloat = 0.5) -> some View {
        self
            .rotation3DEffect(.degrees(Double(y) * 0.08), axis: (x: 1, y: 0, z: 0), perspective: perspective)
            .rotation3DEffect(.degrees(Double(-x) * 0.08), axis: (x: 0, y: 1, z: 0), perspective: perspective)
    }

    /// Subtle 3D float effect — card hovers above surface with ambient motion.
    func floatingCard() -> some View {
        modifier(FloatingCardModifier())
    }

    /// 3D pressed effect — pushes into the surface on press.
    func pressed3D(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .rotation3DEffect(
                .degrees(isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.4
            )
            .shadow(
                color: .black.opacity(isPressed ? 0.12 : 0.08),
                radius: isPressed ? 4 : 16,
                y: isPressed ? 2 : 8
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }

    /// Isometric perspective for map/game boards
    func isometricPerspective(angle: Double = 4) -> some View {
        self
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
    }
}

// MARK: - Floating Card Modifier

struct FloatingCardModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .shadow(color: .black.opacity(0.06), radius: 8 + abs(offset), y: 8 + offset * 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    offset = -4
                }
            }
    }
}

// MARK: - 3D Button Style

/// Premium 3D button that depresses into the surface on tap with rotation.
struct PressableButton3DStyle: ButtonStyle {
    var depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? depth * 0.6 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 1.5 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.04 : 0.1),
                radius: configuration.isPressed ? 2 : 8,
                y: configuration.isPressed ? 1 : depth
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Gyro Tilt Modifier (uses device motion for interactive 3D)

struct GyroTiltModifier: ViewModifier {
    @State private var pitch: Double = 0
    @State private var roll: Double = 0

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(pitch * 3), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(roll * 3), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}
