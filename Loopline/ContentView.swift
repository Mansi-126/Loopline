//
//  ContentView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//
//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch app.route {
            case .launch:
                LaunchView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            case .map:
                LevelMapView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .game(let level):
                GameView(level: level)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            case .result(let result):
                ResultView(result: result)
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            }
        }
        .task { await app.boot() }
    }
}

/// Animated logo mark: a path draws itself through a 3×3 grid.
struct LaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var appeared = false
    @State private var breathing = false

    var body: some View {
        VStack(spacing: 24) {
            LogoMark(progress: drawn)
                .frame(width: 96, height: 96)
            Text("Loopline")
                .font(Theme.font(.title))
                .foregroundStyle(Theme.ink)
        }
        // Entrance: scale 0.85 -> 1.0 (spring) + fade in. Breathing pulse holds after.
        .scaleEffect(reduceMotion ? 1 : (appeared ? 1.0 : 0.85))
        .scaleEffect(reduceMotion ? 1 : (breathing ? 1.02 : 1.0))
        .opacity(appeared ? 1 : 0)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appeared = true
                    drawn = 1
                }
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
            // Vector path draw-on
            withAnimation(.easeOut(duration: 0.6)) {
                drawn = 1
            }
            // Subtle looping breathing pulse while the splash holds
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}

struct LogoMark: View {
    var progress: CGFloat
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 3
            let pts: [CGPoint] = [(0,0),(1,0),(2,0),(2,1),(1,1),(0,1),(0,2),(1,2),(2,2)]
                .map { CGPoint(x: CGFloat($0.0) * s + s/2, y: CGFloat($0.1) * s + s/2) }
            var path = Path()
            path.move(to: pts[0]); pts.dropFirst().forEach { path.addLine(to: $0) }
            ctx.stroke(path.trimmedPath(from: 0, to: progress),
                       with: .color(Theme.accent),
                       style: StrokeStyle(lineWidth: s * 0.55, lineCap: .round, lineJoin: .round))
        }
    }
}
