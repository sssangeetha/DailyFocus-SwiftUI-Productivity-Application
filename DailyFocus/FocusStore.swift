import SwiftUI

@MainActor
final class FocusStore: ObservableObject {
    @Published private(set) var data = FocusData()
    @Published private(set) var clock = FocusClock()
    @Published var storageError: String?
    @Published var showCompletion = false
    private let defaults: UserDefaults
    private let dataKey = "dailyFocus.data.v1"
    private let clockKey = "dailyFocus.clock.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            if let saved = defaults.data(forKey: dataKey) {
                data = try JSONDecoder().decode(FocusData.self, from: saved)
            }
            if let saved = defaults.data(forKey: clockKey) {
                clock = try JSONDecoder().decode(FocusClock.self, from: saved)
            }
        } catch { storageError = "Your saved data could not be read. \(error.localizedDescription)" }
        tick()
    }

    var today: [Priority] { data.priorities(on: Date()) }
    var minutesToday: Int { data.focusedMinutes(on: Date()) }

    func add(_ title: String) {
        if data.addPriority(title) { save() }
    }

    func toggle(_ priority: Priority) {
        guard let index = data.priorities.firstIndex(where: { $0.id == priority.id }) else { return }
        data.priorities[index].completed.toggle()
        save()
    }

    func delete(_ priority: Priority) {
        data.priorities.removeAll { $0.id == priority.id }
        save()
    }

    func setDuration(_ minutes: Int) { clock.reset(minutes: minutes); save() }
    func reset() { clock.reset(minutes: clock.duration / 60); save() }

    func toggleTimer() {
        if clock.isRunning {
            let end = clock.deadline ?? Date()
            if clock.pause() { completeSession(at: end) }
        } else {
            if clock.remaining == 0 { clock.reset(minutes: clock.duration / 60) }
            clock.start()
        }
        save()
    }

    func tick() {
        let end = clock.deadline ?? Date()
        if clock.refresh() { completeSession(at: end); save() }
    }

    private func completeSession(at date: Date) {
        data.sessions.append(FocusSession(completedAt: date, minutes: clock.duration / 60))
        showCompletion = true
    }

    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(data), forKey: dataKey)
            defaults.set(try JSONEncoder().encode(clock), forKey: clockKey)
        } catch { storageError = "Your changes could not be saved. \(error.localizedDescription)" }
    }
}
