//
//  PressableButtonStyle.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

/// Every tappable surface squishes with 3D depth — the app's signature press feel.
/// Rotates slightly forward on the X axis + pushes "into" the surface.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 2.5 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.03 : 0.08),
                radius: configuration.isPressed ? 2 : 10,
                y: configuration.isPressed ? 1 : 6
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65),
                       value: configuration.isPressed)
    }
}
