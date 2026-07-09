//
//  GameEngine.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI
import Combine

/// Live game state machine. Owns the path, timer, validation, hints,
/// backtrack counting, and win detection.
@MainActor
final class GameEngine: ObservableObject {
    let level: Level
    let puzzle: Puzzle

    @Published private(set) var path: [GridPoint] = []
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var backtracks = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var isSolved = false
    @Published var hintFlash: GridPoint? = nil
    @Published var errorPulse = false

    private var pathSet: Set<GridPoint> = []
    private var timer: AnyCancellable?
    private var lastHapticCount = 0

    var nextWaypointNumber: Int {
        let hit = puzzle.waypoints.prefix { pathSet.contains($0) && waypointsHitInOrder(upTo: $0) }
        return min(hit.count + 1, puzzle.waypoints.count)
    }
    var fillProgress: Double { Double(path.count) / Double(puzzle.cellCount) }

    init(level: Level) {
        self.level = level
        self.puzzle = PuzzleGenerator.generate(level: level)
        reset()
    }

    func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.isSolved else { return }
                self.elapsed += 0.1
            }
    }

    func reset() {
        guard let startWaypoint = puzzle.waypoints.first else { return }
        path = [startWaypoint]
        pathSet = [startWaypoint]
        isSolved = false
    }

    // MARK: - Drag handling

    /// Called with each cell the finger crosses. Returns whether accepted.
    @discardableResult
    func visit(_ cell: GridPoint) -> Bool {
        guard !isSolved, let head = path.last, cell != head else { return false }

        // Backtrack: dragging onto the second-to-last cell rewinds.
        if path.count >= 2 && cell == path[path.count - 2] {
            pathSet.remove(path.removeLast())
            backtracks += 1
            Haptics.shared.backtrack()
            return true
        }
        guard cell.isAdjacent(to: head), !pathSet.contains(cell) else {
            if cell.isAdjacent(to: head) { rejectPulse() }
            return false
        }
        // Waypoint order rule: can't step on waypoint k+2 before k+1.
        if let n = puzzle.waypointNumber(at: cell), n != expectedNextWaypoint() {
            rejectPulse()
            return false
        }
        path.append(cell)
        pathSet.insert(cell)

        if puzzle.waypointNumber(at: cell) != nil {
            Haptics.shared.waypoint()
        } else {
            Haptics.shared.pathTick(progress: fillProgress)
        }
        checkWin()
        return true
    }

    /// Rewind the path back to (and excluding) a tapped earlier cell.
    func rewind(to cell: GridPoint) {
        guard let idx = path.firstIndex(of: cell), idx < path.count - 1 else { return }
        let removed = path.count - idx - 1
        path.removeLast(removed)
        pathSet = Set(path)
        backtracks += removed
        Haptics.shared.backtrack()
    }

    /// Tap a waypoint number to clear the path from that waypoint onward.
    /// If it's waypoint 1 (the start), reset entirely.
    func tapWaypoint(at cell: GridPoint) {
        guard !isSolved else { return }
        guard let wpNumber = puzzle.waypointNumber(at: cell) else { return }
        // Only act on waypoints already in the path
        guard pathSet.contains(cell) else { return }

        if wpNumber == 1 {
            // Tapping waypoint 1 restarts the puzzle
            let removed = path.count - 1
            reset()
            backtracks += removed
            Haptics.shared.backtrack()
        } else {
            // Clear path from this waypoint onward (keep everything before it)
            guard let idx = path.firstIndex(of: cell) else { return }
            let removed = path.count - idx
            path.removeLast(removed)
            pathSet = Set(path)
            backtracks += removed
            Haptics.shared.backtrack()
        }
    }

    // MARK: - Hints

    /// Flash the next correct cell the player should move to.
    /// If the player has diverged from the solution, rewind to the last
    /// correct position first, then show the next correct step.
    func useHint() {
        guard !isSolved else { return }
        hintsUsed += 1

        // Find the longest prefix of the player's path that matches the solution exactly.
        let matchLen = longestMatchingPrefix()

        if matchLen < path.count {
            // Player has diverged — rewind to the last correct cell
            let removed = path.count - matchLen
            path.removeLast(removed)
            pathSet = Set(path)
            backtracks += removed
        }

        // Now path[0..<matchLen] matches solution[0..<matchLen].
        // Show the next correct cell from the solution.
        if matchLen < puzzle.solution.count {
            hintFlash = puzzle.solution[matchLen]
        }

        Haptics.shared.waypoint()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.4)) { self.hintFlash = nil }
        }
    }

    /// Returns the length of the longest prefix where path matches solution exactly.
    private func longestMatchingPrefix() -> Int {
        let limit = min(path.count, puzzle.solution.count)
        for i in 0..<limit {
            if path[i] != puzzle.solution[i] {
                return i
            }
        }
        return limit
    }

    // MARK: - Private

    private func expectedNextWaypoint() -> Int {
        var count = 0
        for p in path where puzzle.waypointNumber(at: p) != nil { count += 1 }
        return count + 1
    }

    private func waypointsHitInOrder(upTo point: GridPoint) -> Bool { true }

    private func rejectPulse() {
        Haptics.shared.error()
        withAnimation(.spring(duration: 0.25)) { errorPulse = true }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation { self.errorPulse = false }
        }
    }

    private func checkWin() {
        guard path.count == puzzle.cellCount else { return }
        // All cells filled + last waypoint must be the final number.
        guard let lastCell = path.last,
              puzzle.waypointNumber(at: lastCell) == puzzle.waypoints.count else { return }
        isSolved = true
        timer?.cancel()
        Haptics.shared.win()
    }

    func makeResult() -> GameResult {
        GameResult(level: level, time: elapsed, backtracks: backtracks,
                   hintsUsed: hintsUsed, solvedAt: .now)
    }
}
