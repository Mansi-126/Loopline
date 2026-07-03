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
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .opacity))
            case .map:
                LevelMapView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .game(let level):
                GameView(level: level)
                    .transition(.asymmetric(insertion: .move(edge: .bottom),
                                            removal: .opacity))
            case .result(let result):
                ResultView(result: result)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .task { await app.boot() }
    }
}

/// Animated logo mark: a path draws itself through a 3×3 grid.
struct LaunchView: View {
    @State private var drawn: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            LogoMark(progress: drawn)
                .frame(width: 96, height: 96)
            Text("Loopline")
                .font(Theme.font(.title))
                .foregroundStyle(Theme.ink)
                .opacity(drawn)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { drawn = 1 }
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
