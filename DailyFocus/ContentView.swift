import SwiftUI

private let accent = Color(red: 0.27, green: 0.39, blue: 0.94)

struct ContentView: View {
    @EnvironmentObject private var store: FocusStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var addingPriority = false
    private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        greeting
                        summary
                        priorities
                        timerCard
                        Label("Small steps. Meaningful progress.", systemImage: "sparkles")
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.bottom)
                    }.padding(22).frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                }
                .background(accent.opacity(0.035))
                .navigationTitle("Daily Focus")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                            .accessibilityLabel("Make time for what matters")
                    }
                }
            }.tabItem { Label("Today", systemImage: "sun.max") }
            NavigationStack { ProgressViewScreen() }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
        }
        .tint(accent)
        .sheet(isPresented: $addingPriority) { AddPriorityView() }
        .onReceive(pulse) { _ in store.tick() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { store.tick() } }
        .alert("A little more focused", isPresented: $store.showCompletion) {
            Button("Keep going", role: .cancel) { }
        } message: { Text("Your focus session is complete and has been added to your progress.") }
        .alert("Storage issue", isPresented: Binding(
            get: { store.storageError != nil },
            set: { if !$0 { store.storageError = nil } }
        )) { Button("OK") { store.storageError = nil } }
        message: { Text(store.storageError ?? "") }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text("Make room for\nwhat matters.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Three priorities. One focused day.").foregroundStyle(.secondary)
        }.accessibilityElement(children: .combine)
    }

    private var summary: some View {
        HStack(spacing: 16) {
            stat("\(store.today.filter(\.completed).count)/3", label: "Priorities done", icon: "checkmark.circle.fill")
            Divider()
            stat("\(store.minutesToday)", label: "Minutes focused", icon: "bolt.fill")
        }
        .padding(20).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
    }

    private func stat(_ value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(accent)
            Text(value).font(.system(.title, design: .rounded, weight: .bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
    }

    private var priorities: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your priorities").font(.title3.bold())
                Spacer()
                Button { addingPriority = true } label: {
                    Label("Add", systemImage: "plus").font(.subheadline.bold())
                }.disabled(store.today.count >= 3)
            }
            if store.today.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "leaf").font(.largeTitle).foregroundStyle(accent)
                    Text("Start with one thing").font(.headline)
                    Text("What would make today feel worthwhile?")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Add your first priority") { addingPriority = true }
                        .buttonStyle(.borderedProminent).padding(.top, 4)
                }.frame(maxWidth: .infinity).padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            } else {
                ForEach(store.today) { priority in
                    HStack(spacing: 14) {
                        Button { store.toggle(priority) } label: {
                            Image(systemName: priority.completed ? "checkmark.circle.fill" : "circle")
                                .font(.title2).foregroundStyle(priority.completed ? accent : .secondary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(priority.completed ? "Mark \(priority.title) incomplete" : "Complete \(priority.title)")
                        Text(priority.title).strikethrough(priority.completed)
                            .foregroundStyle(priority.completed ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(role: .destructive) { store.delete(priority) } label: {
                            Image(systemName: "trash").font(.subheadline)
                                .frame(width: 44, height: 44)
                        }.buttonStyle(.plain).foregroundStyle(.secondary)
                            .accessibilityLabel("Delete \(priority.title)")
                    }.padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
                }
                Text("Choose up to three. Keep your day intentional.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var timerCard: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Focus time", systemImage: "headphones").font(.headline)
                Spacer()
                Text(store.clock.isRunning ? "IN THE ZONE" : "YOUR SPACE")
                    .font(.caption2.bold()).tracking(1.2)
            }
            ZStack {
                Circle().stroke(.white.opacity(0.16), lineWidth: 10)
                Circle().trim(from: 0, to: CGFloat(store.clock.remaining) / CGFloat(store.clock.duration))
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 6) {
                    Text(String(format: "%02d:%02d", store.clock.remaining / 60, store.clock.remaining % 60))
                        .font(.system(size: 46, weight: .semibold, design: .rounded)).monospacedDigit()
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Text(store.clock.isRunning ? "One thing at a time" : "Take a breath. Begin.")
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                }.padding(20)
            }.frame(width: 210, height: 210)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(store.clock.remaining / 60) minutes and \(store.clock.remaining % 60) seconds remaining")
            HStack(spacing: 12) {
                ForEach([15, 25, 45], id: \.self) { minutes in
                    Button { store.setDuration(minutes) } label: {
                        Text("\(minutes) min").font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.white.opacity(store.clock.duration == minutes * 60 ? 0.25 : 0.08), in: Capsule())
                    }.buttonStyle(.plain).disabled(store.clock.isRunning)
                        .accessibilityAddTraits(store.clock.duration == minutes * 60 ? .isSelected : [])
                }
            }
            HStack(spacing: 12) {
                Button { store.reset() } label: {
                    Image(systemName: "arrow.counterclockwise").frame(width: 48, height: 48)
                        .background(.white.opacity(0.15), in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Reset timer")
                Button { store.toggleTimer() } label: {
                    Label(store.clock.isRunning ? "Pause focus" : "Start focus", systemImage: store.clock.isRunning ? "pause.fill" : "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .foregroundStyle(accent).background(.white, in: Capsule())
                }.buttonStyle(.plain)
            }
            Text("The timer keeps counting when you leave the app.")
                .font(.caption2).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
        }.padding(24).foregroundStyle(.white)
            .background(LinearGradient(colors: [accent, Color(red: 0.30, green: 0.25, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
    }
}

struct AddPriorityView: View {
    @EnvironmentObject private var store: FocusStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @FocusState private var fieldFocused: Bool
    var body: some View {
        NavigationStack {
            Form {
                Section("One thing that matters") {
                    TextField("e.g. Finish a chapter", text: $title)
                        .focused($fieldFocused).submitLabel(.done).onSubmit(save)
                }
                Section { Text("A clear, small priority is easier to begin. You can choose up to three each day.").foregroundStyle(.secondary) }
            }
            .navigationTitle("New priority")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.today.count >= 3)
                }
            }.onAppear { fieldFocused = true }
        }.presentationDetents([.medium, .large])
    }
    private func save() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, store.today.count < 3 else { return }
        store.add(title); dismiss()
    }
}

struct ProgressViewScreen: View {
    @EnvironmentObject private var store: FocusStore
    private var days: [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Every session counts.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Build a rhythm, one day at a time.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 18) {
                    Text("The last seven days").font(.headline)
                    ForEach(days, id: \.self) { day in
                        let minutes = store.data.focusedMinutes(on: day)
                        HStack(spacing: 12) {
                            Text(day, format: .dateTime.weekday(.abbreviated)).font(.caption).frame(width: 34, alignment: .leading)
                            GeometryReader { geometry in
                                Capsule().fill(accent.opacity(0.08))
                                Capsule().fill(accent).frame(width: minutes == 0 ? 0 : max(8, geometry.size.width * CGFloat(minutes) / CGFloat(maximum)))
                            }.frame(height: 12)
                            Text("\(minutes)m").font(.caption.monospacedDigit()).frame(width: 42, alignment: .trailing)
                        }.accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)): \(minutes) focused minutes")
                    }
                }.padding(22).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                HStack {
                    metric("\(store.data.sessions.count)", "Sessions completed")
                    metric("\(store.data.priorities.filter(\.completed).count)", "Priorities completed")
                }
                Text("Recent sessions").font(.title3.bold())
                if store.data.sessions.isEmpty {
                    ContentUnavailableView("Your story starts today", systemImage: "sparkles", description: Text("Finish a focus session to see it here."))
                } else {
                    ForEach(Array(store.data.sessions.reversed().prefix(20))) { session in
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(accent).font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(session.minutes) minutes of focus").font(.headline)
                                Text(session.completedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(accent.opacity(0.035)).navigationTitle("Your progress")
    }
    private var maximum: Int { max(1, days.map { store.data.focusedMinutes(on: $0) }.max() ?? 1) }
    private func metric(_ value: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value).font(.system(.title, design: .rounded, weight: .bold)).foregroundStyle(accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}
