import SwiftUI

// MARK: - Model

struct ScheduleBlock: Identifiable, Equatable,Codable {
    let id: UUID
    var day: Date
    var activity: String
    var startTime: Date
    var durationMinutes: Int
    var notes: String

    init(
        id: UUID = UUID(),
        day: Date,
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        notes: String = ""
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.notes = notes
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
    @State private var blocks: [ScheduleBlock] = loadBlocks()
    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock?
    @State private var selectedDate: Date = Date()
    @State private var showCalendar = false
    @State private var swipeDirection: Int = 0

    private var selectedDayStart: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var todaysBlocks: [ScheduleBlock] {
        blocks
            .filter { $0.day == selectedDayStart }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                GreetingBoxView()

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
                                    .onTapGesture {
                                        editingBlock = block
                                    }
                                    .swipeActions(edge: .trailing) {
                                        editAction(block)
                                        deleteAction(block)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
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
                titleToolbar
                calendarToolbar
                addToolbar
            }
            .sheet(isPresented: $showAdd) {
                AddBlockView(day: selectedDate) { newBlock in
                    blocks.append(newBlock)
                }
            }
            .sheet(item: $editingBlock) { block in
                EditBlockView(
                    day: selectedDate,
                    block: block,
                    onSave: { updated in
                        if let idx = blocks.firstIndex(where: { $0.id == updated.id }) {
                            blocks[idx] = updated
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
        }
        .onChange(of: blocks) { _, newValue in
                    saveBlocks(newValue)
                }
    }

    // MARK: - Toolbar

    private var titleToolbar: ToolbarItem<Void, some View> {
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
                        Capsule()
                            .fill(DailyTheme.babyPink.opacity(0.22))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarToolbar: ToolbarItem<Void, some View> {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(.body, design: .rounded))
                    .padding(8)
                    .background(Circle().fill(DailyTheme.skyBlue.opacity(0.22)))
            }
            .buttonStyle(.plain)
        }
    }

    private var addToolbar: ToolbarItem<Void, some View> {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(.body, design: .rounded))
                    .padding(8)
                    .background(Circle().fill(DailyTheme.babyPink.opacity(0.22)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - GreetingBox

    struct GreetingBoxView: View {
        var body: some View {
            HStack {
                Text(greetingText())
                    .font(.system(.headline, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(DailyTheme.babyPink.opacity(0.25))
                    )
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
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
            Text(timeString(block.startTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.activity)
                    .font(.system(.headline, design: .rounded))

                Text("\(block.durationMinutes) min")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundStyle(DailyTheme.skyBlue.opacity(0.9))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DailyTheme.cream.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DailyTheme.stroke, lineWidth: 1)
        )
    }

    // MARK: - Swipe Actions

    private func editAction(_ block: ScheduleBlock) -> some View {
        Button {
            editingBlock = block
        } label: {
            Label("Edit", systemImage: "pencil")
        }
    }

    private func deleteAction(_ block: ScheduleBlock) -> some View {
        Button(role: .destructive) {
            delete(block)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func delete(_ block: ScheduleBlock) {
        blocks.removeAll { $0.id == block.id }
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
                        DatePicker(
                            "Start",
                            selection: $startTimeOnly,
                            displayedComponents: .hourAndMinute
                        )
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

                        let fullStart = combine(day: day, time: startTimeOnly)
                        onSave(
                            ScheduleBlock(
                                day: day,
                                activity: trimmed,
                                startTime: fullStart,
                                durationMinutes: durationMinutes,
                                notes: notes
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
                        DatePicker(
                            "Start",
                            selection: $startTimeOnly,
                            displayedComponents: .hourAndMinute
                        )
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

                        let fullStart = combine(day: day, time: startTimeOnly)
                        onSave(
                            ScheduleBlock(
                                id: original.id,
                                day: day,
                                activity: trimmed,
                                startTime: fullStart,
                                durationMinutes: durationMinutes,
                                notes: notes
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

// MARK: - Helpers

private func greetingText() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 { return "Good Morning ☁️" }
    if hour < 18 { return "Good Afternoon ☁️" }
    return "Good Night ☁️"
}

private func timeString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

private func shortDate(_ date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated).day())
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

private enum Storage {
    static let blocksKey = "dailyos.blocks.v1"
}

private func loadBlocks() -> [ScheduleBlock] {
    guard let data = UserDefaults.standard.data(forKey: Storage.blocksKey) else { return [] }
    return (try? JSONDecoder().decode([ScheduleBlock].self, from: data)) ?? []
}

private func saveBlocks(_ blocks: [ScheduleBlock]) {
    guard let data = try? JSONEncoder().encode(blocks) else { return }
    UserDefaults.standard.set(data, forKey: Storage.blocksKey)
}


// MARK: - Preview

#Preview {
    ContentView()
}

