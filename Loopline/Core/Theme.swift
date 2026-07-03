//
//  Theme.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

/// Design system. One place for every color, radius, and type ramp.
enum Theme {
    // Palette — warm paper background, ink text, one confident accent.
    static let background   = Color(hex: 0xFAF7F2)
    static let surface      = Color.white
    static let ink          = Color(hex: 0x1C1B1A)
    static let inkSecondary = Color(hex: 0x8A857E)
    static let accent       = Color(hex: 0xFF6B4A)   // coral
    static let accentSoft   = Color(hex: 0xFFE3DB)
    static let gold         = Color(hex: 0xF2B441)
    static let success      = Color(hex: 0x3BB273)
    static let boardLine    = Color(hex: 0xEDE8E1)
    static let locked       = Color(hex: 0xD9D4CC)

    static let cornerRadius: CGFloat = 20

    enum TextStyle { case display, title, headline, body, caption, mono }

    static func font(_ style: TextStyle) -> Font {
        switch style {
        case .display:  return .system(size: 40, weight: .heavy, design: .rounded)
        case .title:    return .system(size: 28, weight: .bold, design: .rounded)
        case .headline: return .system(size: 18, weight: .semibold, design: .rounded)
        case .body:     return .system(size: 16, weight: .medium, design: .rounded)
        case .caption:  return .system(size: 13, weight: .medium, design: .rounded)
        case .mono:     return .system(size: 22, weight: .bold, design: .monospaced)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
