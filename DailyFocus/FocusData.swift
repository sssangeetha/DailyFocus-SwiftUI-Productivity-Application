import Foundation

struct Priority: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var completed = false
    var day: Date = Date()
}

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    var completedAt: Date
    var minutes: Int
}

struct FocusData: Codable {
    var priorities: [Priority] = []
    var sessions: [FocusSession] = []

    func priorities(on date: Date) -> [Priority] {
        priorities.filter { Calendar.current.isDate($0.day, inSameDayAs: date) }
    }

    func focusedMinutes(on date: Date) -> Int {
        sessions.filter { Calendar.current.isDate($0.completedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.minutes }
    }

    mutating func addPriority(_ title: String, on date: Date = Date()) -> Bool {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, priorities(on: date).count < 3 else { return false }
        priorities.append(Priority(title: clean, day: date))
        return true
    }
}

/// A deadline keeps the timer accurate when the app is backgrounded.
struct FocusClock: Codable {
    var duration = 25 * 60
    var remaining = 25 * 60
    var deadline: Date?
    var isRunning: Bool { deadline != nil }

    mutating func start(at now: Date = Date()) {
        guard !isRunning, remaining > 0 else { return }
        deadline = now.addingTimeInterval(TimeInterval(remaining))
    }

    @discardableResult
    mutating func refresh(at now: Date = Date()) -> Bool {
        guard let end = deadline else { return false }
        remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
        if remaining == 0 { deadline = nil; return true }
        return false
    }

    mutating func pause(at now: Date = Date()) -> Bool {
        let finished = refresh(at: now)
        deadline = nil
        return finished
    }

    mutating func reset(minutes: Int) {
        duration = minutes * 60
        remaining = duration
        deadline = nil
    }
}
