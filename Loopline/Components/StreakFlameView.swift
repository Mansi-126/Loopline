//
//  StreakFlameView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

/// Flame that flickers organically when active, greys out when not.
struct StreakFlameView: View {
    let active: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let flicker = active ? 1 + 0.06 * sin(t * 9) + 0.03 * sin(t * 23) : 1
            Image(systemName: "flame.fill")
                .resizable().scaledToFit()
                .foregroundStyle(active
                    ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.accent],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Theme.locked))
                .scaleEffect(flicker, anchor: .bottom)
        }
    }
}
