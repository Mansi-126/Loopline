//
//  Haptics.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import UIKit
import CoreHaptics

/// Central haptics engine. Path-drawing uses a custom "tick" that gets
/// subtly sharper as the path nears completion — a tiny detail that makes
/// the final cells feel electric.
final class Haptics {
    static let shared = Haptics()
    private var engine: CHHapticEngine?
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()

    private init() {
        engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
    }

    /// progress ∈ 0...1 → intensity/sharpness ramps up as board fills.
    func pathTick(progress: Double) {
        guard let engine else { impact.impactOccurred(intensity: 0.6); return }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            .init(parameterID: .hapticIntensity, value: Float(0.35 + 0.45 * progress)),
            .init(parameterID: .hapticSharpness, value: Float(0.3 + 0.6 * progress))
        ], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }

    func waypoint()  { rigid.impactOccurred(intensity: 1.0) }
    func backtrack() { impact.impactOccurred(intensity: 0.4) }
    func error()     { notify.notificationOccurred(.error) }

    /// Rising arpeggio of transients on win.
    func win() {
        guard let engine else { notify.notificationOccurred(.success); return }
        let events = (0..<5).map { i in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.5 + Float(i) * 0.12),
                .init(parameterID: .hapticSharpness, value: 0.4 + Float(i) * 0.15)
            ], relativeTime: Double(i) * 0.07)
        }
        if let pattern = try? CHHapticPattern(events: events, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}
