import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Model

struct ScheduleBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var day: Date
    var activity: String
    var startTime: Date
    var durationMinutes: Int
    var notes: String
    var isDone: Bool

    init(
        id: UUID = UUID(),
        day: Date,
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        notes: String = "",
        isDone: Bool = false
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isDone = isDone
    }

    enum CodingKeys: String, CodingKey {
        case id, day, activity, startTime, durationMinutes, notes, isDone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        day = try c.decode(Date.self, forKey: .day)
        activity = try c.decode(String.self, forKey: .activity)
        startTime = try c.decode(Date.self, forKey: .startTime)
        durationMinutes = try c.decode(Int.self, forKey: .durationMinutes)
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
        isDone = (try? c.decode(Bool.self, forKey: .isDone)) ?? false
        day = Calendar.current.startOfDay(for: day)
    }
}

@Model
final class ScheduleBlockEntity {
    var id: UUID = UUID()
    var day: Date = Date()
    var activity: String = ""
    var startTime: Date = Date()
    var durationMinutes: Int = 30
    var notes: String = ""
    var isDone: Bool = false
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        day: Date,
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        notes: String = "",
        isDone: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isDone = isDone
        self.updatedAt = updatedAt
    }

    convenience init(from block: ScheduleBlock) {
        self.init(
            id: block.id,
            day: block.day,
            activity: block.activity,
            startTime: block.startTime,
            durationMinutes: block.durationMinutes,
            notes: block.notes,
            isDone: block.isDone,
            updatedAt: Date()
        )
    }

    func asDraft() -> ScheduleBlock {
        ScheduleBlock(
            id: id,
            day: day,
            activity: activity,
            startTime: startTime,
            durationMinutes: durationMinutes,
            notes: notes,
            isDone: isDone
        )
    }

    func apply(from block: ScheduleBlock) {
        day = Calendar.current.startOfDay(for: block.day)
        activity = block.activity
        startTime = block.startTime
        durationMinutes = block.durationMinutes
        notes = block.notes
        isDone = block.isDone
        updatedAt = Date()
    }
}

// MARK: - Theme

enum DailyTheme {
    static let babyPink = Color(red: 1.00, green: 0.83, blue: 0.90)
    static let skyBlue  = Color(red: 0.74, green: 0.90, blue: 1.00)
    static let lavender = Color(red: 0.86, green: 0.82, blue: 1.00)
    static let cream    = Color(red: 0.99, green: 0.97, blue: 0.95)

    static let stroke = skyBlue.opacity(0.35)
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\ScheduleBlockEntity.day, order: .forward),
            SortDescriptor(\ScheduleBlockEntity.startTime, order: .forward)
        ]
    ) private var persistedBlocks: [ScheduleBlockEntity]

    @State private var didRunMigration = false
    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock?
    @State private var pendingDeleteBlock: ScheduleBlock?
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    @State private var swipeDirection = 0

    private var selectedDayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var todaysBlocks: [ScheduleBlock] {
        persistedBlocks
            .filter { $0.day == selectedDayStart }
            .sorted { $0.startTime < $1.startTime }
            .map { $0.asDraft() }
    }
    
    private func insertNewBlockChronologically(_ newBlock: ScheduleBlock) {
        var dayBlocks = persistedBlocks
            .filter { $0.day == selectedDayStart }
            .sorted { $0.startTime < $1.startTime }

        let newEntity = ScheduleBlockEntity(from: newBlock)
        modelContext.insert(newEntity)
        dayBlocks.append(newEntity)
        dayBlocks.sort { $0.startTime < $1.startTime }

        let anchor = dayBlocks.map(\.startTime).min() ?? newEntity.startTime
        recalculateTimesForSelectedDay(anchor: anchor, dayBlocks: dayBlocks)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                GreetingBoxView()
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                Text(shortDate(selectedDate))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .padding(.horizontal, 26)

                List {
                    Section {
                        if todaysBlocks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                emptyState
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .glassPanel()
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(todaysBlocks) { block in
                                blockRow(block)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingBlock = block }
                                    .swipeActions(edge: .trailing) {
                                        Button { editingBlock = block } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) { pendingDeleteBlock = block } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            // NOTE: List reordering only works in Edit mode.
                            // Keeping the handler here so you can re-enable later if you want.
                            .onMove(perform: moveTodayBlocks)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(
                LinearGradient(
                    colors: [
                        DailyTheme.skyBlue.opacity(0.35),
                        DailyTheme.babyPink.opacity(0.25),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .id(selectedDayStart)
            .transition(
                .asymmetric(
                    insertion: .move(edge: swipeDirection == -1 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: swipeDirection == -1 ? .leading : .trailing).combined(with: .opacity)
                )
            )
            .animation(.easeInOut(duration: 0.22), value: selectedDayStart)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            swipeDirection = -1
                            goToNextDay()
                        } else if value.translation.width > 50 {
                            swipeDirection = 1
                            goToPreviousDay()
                        }
                    }
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Date()
                        }
                    } label: {
                        Text(Calendar.current.isDateInToday(selectedDate) ? "Today" : shortDate(selectedDate))
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(DailyTheme.babyPink.opacity(0.22))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Jump to today")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCalendar = true } label: {
                        Image(systemName: "calendar")
                            .font(.system(.body, design: .rounded))
                            .padding(8)
                            .background(Circle().fill(DailyTheme.skyBlue.opacity(0.22)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open calendar")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(.body, design: .rounded))
                            .padding(8)
                            .background(Circle().fill(DailyTheme.babyPink.opacity(0.22)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add schedule block")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddBlockView(day: selectedDate) { newBlock in
                    insertNewBlockChronologically(newBlock)
                }
            }
            .sheet(item: $editingBlock) { block in
                EditBlockView(
                    day: selectedDate,
                    block: block,
                    onSave: { updated in
                        if let entity = entity(for: updated.id) {
                            entity.apply(from: updated)
                            normalizeDaySchedule(for: updated.day)
                        }
                        editingBlock = nil
                    },
                    onDelete: { toDelete in
                        delete(toDelete)
                        editingBlock = nil
                    }
                )
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(selectedDate: $selectedDate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Delete this block?",
                isPresented: Binding(
                    get: { pendingDeleteBlock != nil },
                    set: { if !$0 { pendingDeleteBlock = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let block = pendingDeleteBlock {
                        delete(block)
                    }
                    pendingDeleteBlock = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteBlock = nil
                }
            } message: {
                if let block = pendingDeleteBlock {
                    Text("\"\(block.activity)\" will be permanently removed.")
                }
            }
        }
        .onAppear {
            guard !didRunMigration else { return }
            ReminderCenter.requestAuthorizationIfNeeded()
            migrateLegacyBlocksIfNeeded()
            ReminderCenter.sync(for: persistedBlocks.map { $0.asDraft() })
            didRunMigration = true
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing planned yet 🌷")
                .font(.system(.headline, design: .rounded))
            Text("Tap + to add something cute to your day")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private func blockRow(_ block: ScheduleBlock) -> some View {
        HStack(spacing: 12) {
            Button { toggleDone(block) } label: {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(block.isDone ? DailyTheme.skyBlue : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(block.isDone ? "Mark block as not done" : "Mark block as done")

            Text(timeString(block.startTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.activity)
                    .font(.system(.headline, design: .rounded))
                    .strikethrough(block.isDone, color: .secondary)
                    .foregroundStyle(block.isDone ? .secondary : .primary)

                Text("\(block.durationMinutes) min")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundStyle(DailyTheme.skyBlue.opacity(0.9))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DailyTheme.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.activity), \(timeString(block.startTime)), \(block.durationMinutes) minutes")
        .accessibilityHint("Double tap to edit")
    }

    // MARK: - Actions

    private func delete(_ block: ScheduleBlock) {
        guard let entity = entity(for: block.id) else { return }
        modelContext.delete(entity)
        ReminderCenter.remove(for: [block.id])
    }

    private func toggleDone(_ block: ScheduleBlock) {
        if let entity = entity(for: block.id) {
            entity.isDone.toggle()
            entity.updatedAt = Date()
            ReminderCenter.sync(for: [entity.asDraft()])
        }
    }

    private func goToNextDay() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    private func goToPreviousDay() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func moveTodayBlocks(from source: IndexSet, to destination: Int) {
        var dayBlocks = persistedBlocks
            .filter { $0.day == selectedDayStart }
            .sorted { $0.startTime < $1.startTime }
        guard !dayBlocks.isEmpty else { return }

        let anchor = dayBlocks.map(\.startTime).min() ?? selectedDayStart
        dayBlocks.move(fromOffsets: source, toOffset: destination)
        recalculateTimesForSelectedDay(anchor: anchor, dayBlocks: dayBlocks)
    }

    private func recalculateTimesForSelectedDay(anchor: Date, dayBlocks: [ScheduleBlockEntity]) {
        let cal = Calendar.current
        var current = anchor

        for block in dayBlocks {
            block.startTime = current
            block.updatedAt = Date()
            current = cal.date(byAdding: .minute, value: block.durationMinutes, to: current) ?? current
        }

        ReminderCenter.sync(for: dayBlocks.map { $0.asDraft() })
    }

    private func normalizeDaySchedule(for day: Date) {
        let dayStart = Calendar.current.startOfDay(for: day)
        let dayBlocks = persistedBlocks
            .filter { $0.day == dayStart }
            .sorted { $0.startTime < $1.startTime }
        guard !dayBlocks.isEmpty else { return }
        let anchor = dayBlocks.map(\.startTime).min() ?? dayStart
        recalculateTimesForSelectedDay(anchor: anchor, dayBlocks: dayBlocks)
    }

    private func entity(for id: UUID) -> ScheduleBlockEntity? {
        persistedBlocks.first { $0.id == id }
    }

    private func migrateLegacyBlocksIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Storage.cloudMigrationCompleteKey) { return }

        if persistedBlocks.isEmpty, let legacyBlocks = loadLegacyBlocks() {
            for block in legacyBlocks {
                modelContext.insert(ScheduleBlockEntity(from: block))
            }
        }

        defaults.set(true, forKey: Storage.cloudMigrationCompleteKey)
        defaults.removeObject(forKey: Storage.legacyBlocksKey)
    }

}

// MARK: - GreetingBoxView

struct GreetingBoxView: View {
    var body: some View {
        HStack {
            Text(greetingText())
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(DailyTheme.babyPink.opacity(0.25))
                )
            Spacer()
        }
    }
}

// MARK: - Calendar View

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.bottom)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(DailyTheme.cream.opacity(0.9))
                )
                .overlay(
                    Capsule().stroke(DailyTheme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Block View

struct AddBlockView: View {
    @Environment(\.dismiss) private var dismiss
    let day: Date

    @State private var activity: String = ""
    @State private var startTimeOnly: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""

    let onSave: (ScheduleBlock) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        DailyTheme.skyBlue.opacity(0.35),
                        DailyTheme.babyPink.opacity(0.25),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Form {
                    Section("Activity") {
                        TextField("e.g., Study, Work out, Dance", text: $activity)
                    }

                    Section("Time") {
                        DatePicker("Start", selection: $startTimeOnly, displayedComponents: .hourAndMinute)
                    }

                    Section("Duration") {
                        HStack(spacing: 10) {
                            QuickAddButton(title: "+30") { durationMinutes = min(durationMinutes + 30, 600) }
                            QuickAddButton(title: "+45") { durationMinutes = min(durationMinutes + 45, 600) }
                            QuickAddButton(title: "+60") { durationMinutes = min(durationMinutes + 60, 600) }
                        }
                        .padding(.vertical, 4)

                        Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...600, step: 5)
                    }

                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 180)
                            .font(.system(.body, design: .rounded))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Block")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = activity.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

                        let fullStart = combine(day: day, time: startTimeOnly)
                        onSave(
                            ScheduleBlock(
                                day: day,
                                activity: trimmed,
                                startTime: fullStart,
                                durationMinutes: durationMinutes,
                                notes: normalizedNotes
                            )
                        )
                        dismiss()
                    }
                    .disabled(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Block View

struct EditBlockView: View {
    @Environment(\.dismiss) private var dismiss
    let day: Date

    @State private var activity: String
    @State private var startTimeOnly: Date
    @State private var durationMinutes: Int
    @State private var notes: String

    private let original: ScheduleBlock
    let onSave: (ScheduleBlock) -> Void
    let onDelete: (ScheduleBlock) -> Void

    init(
        day: Date,
        block: ScheduleBlock,
        onSave: @escaping (ScheduleBlock) -> Void,
        onDelete: @escaping (ScheduleBlock) -> Void
    ) {
        self.day = day
        self.original = block
        self.onSave = onSave
        self.onDelete = onDelete

        _activity = State(initialValue: block.activity)
        _startTimeOnly = State(initialValue: block.startTime)
        _durationMinutes = State(initialValue: block.durationMinutes)
        _notes = State(initialValue: block.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        DailyTheme.skyBlue.opacity(0.35),
                        DailyTheme.babyPink.opacity(0.25),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Form {
                    Section("Activity") {
                        TextField("Activity", text: $activity)
                    }

                    Section("Time") {
                        DatePicker("Start", selection: $startTimeOnly, displayedComponents: .hourAndMinute)
                    }

                    Section("Duration") {
                        HStack(spacing: 10) {
                            QuickAddButton(title: "+30") { durationMinutes = min(durationMinutes + 30, 600) }
                            QuickAddButton(title: "+45") { durationMinutes = min(durationMinutes + 45, 600) }
                            QuickAddButton(title: "+60") { durationMinutes = min(durationMinutes + 60, 600) }
                        }
                        .padding(.vertical, 4)

                        Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...600, step: 5)
                    }

                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 180)
                            .font(.system(.body, design: .rounded))
                    }

                    Section {
                        Button(role: .destructive) {
                            onDelete(original)
                            dismiss()
                        } label: {
                            Text("Delete Block")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Block")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = activity.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

                        let fullStart = combine(day: day, time: startTimeOnly)
                        onSave(
                            ScheduleBlock(
                                id: original.id,
                                day: day,
                                activity: trimmed,
                                startTime: fullStart,
                                durationMinutes: durationMinutes,
                                notes: normalizedNotes,
                                isDone: original.isDone
                            )
                        )
                        dismiss()
                    }
                    .disabled(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Glass Panel

struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 6)
                    .blur(radius: 6)
                    .mask(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(lineWidth: 8)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
            .shadow(color: .white.opacity(0.18), radius: 8, x: 0, y: -3)
    }
}

extension View {
    func glassPanel() -> some View { modifier(GlassPanel()) }
}

// MARK: - Helpers / Storage

private func greetingText() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 { return "Good Morning ☁️" }
    if hour < 18 { return "Good Afternoon ☁️" }
    return "Good Night ☁️"
}

private func timeString(_ date: Date) -> String {
    Formatters.time.string(from: date)
}

private func shortDate(_ date: Date) -> String {
    Formatters.shortDate.string(from: date)
}

private func combine(day: Date, time: Date) -> Date {
    let cal = Calendar.current
    let dayComps = cal.dateComponents([.year, .month, .day], from: day)
    let timeComps = cal.dateComponents([.hour, .minute], from: time)

    var comps = DateComponents()
    comps.year = dayComps.year
    comps.month = dayComps.month
    comps.day = dayComps.day
    comps.hour = timeComps.hour
    comps.minute = timeComps.minute

    return cal.date(from: comps) ?? day
}

private enum ReminderCenter {
    private static let center = UNUserNotificationCenter.current()

    private static func reminderID(for id: UUID) -> String {
        "dailyos.schedule.\(id.uuidString)"
    }

    static func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    static func remove(for ids: [UUID]) {
        let identifiers = ids.map(reminderID(for:))
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    static func sync(for blocks: [ScheduleBlock]) {
        let identifiers = blocks.map { reminderID(for: $0.id) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)

        let now = Date()
        let cal = Calendar.current

        for block in blocks where !block.isDone && block.startTime > now {
            let content = UNMutableNotificationContent()
            content.title = block.activity
            content.body = "Starts at \(timeString(block.startTime))"
            content.sound = .default

            let dateComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: block.startTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminderID(for: block.id),
                content: content,
                trigger: trigger
            )
            center.add(request) { _ in }
        }
    }
}

private enum Storage {
    static let legacyBlocksKey = "dailyos.blocks.v1"
    static let cloudMigrationCompleteKey = "dailyos.cloudMigrationComplete.v1"
}

private enum Formatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

private func loadLegacyBlocks() -> [ScheduleBlock]? {
    guard let data = UserDefaults.standard.data(forKey: Storage.legacyBlocksKey) else { return nil }
    return try? JSONDecoder().decode([ScheduleBlock].self, from: data)
}

#Preview {
    ContentView()
        .modelContainer(for: ScheduleBlockEntity.self, inMemory: true)
}
