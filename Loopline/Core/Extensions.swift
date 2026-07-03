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
}
