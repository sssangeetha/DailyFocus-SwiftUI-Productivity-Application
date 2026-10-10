# Daily Focus

A small, complete SwiftUI app for iPhone and iPad. Choose three priorities, complete a timed focus session, and watch your weekly progress grow.

## Run the app

1. Install full Xcode from the Mac App Store and launch it once to finish setup and install an iOS simulator runtime.
2. Open `DailyFocus.xcodeproj` in Xcode.
3. Select the **DailyFocus** scheme and an available iPhone simulator.
4. Press **Command-R**.

For a physical iPhone, select your Apple development team in the target's **Signing & Capabilities** settings, change `com.example.DailyFocus` to a unique bundle identifier, and choose your connected device.

Requires iOS 17 or later. No third-party packages, account, server, or API key is needed.

## Features

- Today: create up to three priorities per calendar day, mark them complete, or delete them.
- Focus: choose 15, 25, or 45 minutes; start, pause, resume, or reset.
- Progress: seven-day focus chart, all-time totals, and the twenty latest completed sessions.
- Persistence: priorities, session history, and the active timer survive app relaunch through local JSON storage in UserDefaults.
- Adaptive layout, native navigation and sheets, system materials, Dynamic Type, and VoiceOver labels.

A running timer tracks a wall-clock deadline, including time spent outside the app. A completed session is recorded once when the app next checks the deadline. It is attributed to the date the deadline elapsed. Completion appears in an in-app alert; this version does not schedule background notifications. Pausing or resetting does not count an unfinished session. New days start with an empty priority list; historical completion totals remain.

Data stays on the device and is removed when the app is deleted. There is no cloud synchronization. A custom App Store icon is not included; add one before publishing.

## Learn from the code

This is an original project inspired by the learning progression in [Apple's Develop in Swift](https://developer.apple.com/tutorials/develop-in-swift), rather than a copy of a specific tutorial app.

- `DailyFocusApp.swift`: the app entry point and shared observable state.
- `FocusData.swift`: Codable models and the deadline-based timer.
- `FocusStore.swift`: ObservableObject, published state, actions, and local persistence.
- `ContentView.swift`: NavigationStack, TabView, reusable views, forms, bindings, sheets, and accessibility.

Useful Apple references: [Welcome to app development](https://developer.apple.com/tutorials/develop-in-swift/welcome-to-app-development) and [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack).

## Verification

The Swift sources passed type checking against the installed macOS SDK. The Xcode project file passed `plutil -lint`. Foundation-only checks cover daily priority limits, date separation, JSON round trips, timer pause/resume, elapsed background time, one-time completion, reset, and persisted deadlines.

To rerun the model checks from this folder:

```sh
swiftc DailyFocus/FocusData.swift Checks/main.swift -o /tmp/daily-focus-checks
/tmp/daily-focus-checks
```

Full Xcode and the iOS simulator were unavailable on the creation machine, so the iOS build and screen layout still need verification in Xcode. Suggested simulator checks: add three priorities, complete one, switch tabs, pause/resume the timer, background and reopen the app, relaunch while a timer runs, and test dark mode and large text.
