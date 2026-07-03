//
//  PressableButtonStyle.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

/// Every tappable surface squishes — the app's signature press feel.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}
