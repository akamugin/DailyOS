import SwiftUI

// MARK: - Model

struct ScheduleBlock: Identifiable, Equatable {
    let id: UUID
    var day: Date
    var activity: String
    var startTime: Date
    var durationMinutes: Int

    init(
        id: UUID = UUID(),
        day: Date,
        activity: String,
        startTime: Date,
        durationMinutes: Int
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
    }
}

// MARK: - ContentView (Today)

struct ContentView: View {
    @State private var blocks: [ScheduleBlock] = []
    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock? = nil
    @State private var selectedDate: Date = Date()
    @State private var showCalendar = false

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
            List {
                if todaysBlocks.isEmpty {
                    emptyState
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
                    }
                }
            }
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
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing scheduled for today.")
                .font(.headline)
            Text("Tap + to add your first block.")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func blockRow(_ block: ScheduleBlock) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(timeString(block.startTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.activity)
                    .font(.headline)

                Text("\(block.durationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Toolbar Items

    private var titleToolbar: ToolbarItem<Void, some View> {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 8) {
                Text("Today")
                    .font(.headline)
                Text(shortDate(selectedDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private var calendarToolbar: ToolbarItem<Void, some View> {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
            }
        }
    }

    private var addToolbar: ToolbarItem<Void, some View> {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
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
}

// MARK: - Calendar View

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Pick a date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Block View

struct AddBlockView: View {
    @Environment(\.dismiss) private var dismiss

    let day: Date

    @State private var activity: String = ""
    @State private var startTimeOnly: Date = Date()
    @State private var durationMinutes: Int = 30

    let onSave: (ScheduleBlock) -> Void

    var body: some View {
        NavigationStack {
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
                    Stepper(
                        "\(durationMinutes) minutes",
                        value: $durationMinutes,
                        in: 5...600,
                        step: 5
                    )
                }
            }
            .navigationTitle("New Block")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                                durationMinutes: durationMinutes
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
    }

    var body: some View {
        NavigationStack {
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
                    Stepper(
                        "\(durationMinutes) minutes",
                        value: $durationMinutes,
                        in: 5...600,
                        step: 5
                    )
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
            .navigationTitle("Edit Block")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                                durationMinutes: durationMinutes
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

// MARK: - Helpers

private func timeString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f.string(from: date)
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

// MARK: - Preview

#Preview {
    ContentView()
}

