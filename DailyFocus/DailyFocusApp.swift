import SwiftUI

@main
struct DailyFocusApp: App {
    @StateObject private var store = FocusStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }
}
