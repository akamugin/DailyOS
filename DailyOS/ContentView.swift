import SwiftUI

// MARK: - Model

enum Importance: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

struct ScheduleBlock: Identifiable, Equatable {
    let id: UUID
    var activity: String
    var startTime: Date
    var durationMinutes: Int
    var importance: Importance

    init(
        id: UUID = UUID(),
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        importance: Importance
    ) {
        self.id = id
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.importance = importance
    }
}

// MARK: - ContentView (Today)

struct ContentView: View {
    @State private var blocks: [ScheduleBlock] = []              // ✅ no pre-scheduleblocks
    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock? = nil        // controls edit sheet

    var sortedBlocks: [ScheduleBlock] {
        blocks.sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationStack {
            List {
                if blocks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing scheduled for today.")
                            .font(.headline)
                        Text("Tap + to add your first block.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(sortedBlocks) { block in
                        blockRow(block)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingBlock = block // tap to edit
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    editingBlock = block
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    delete(block)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Add sheet
            .sheet(isPresented: $showAdd) {
                AddBlockView { newBlock in
                    blocks.append(newBlock)
                }
            }
            // Edit sheet
            .sheet(item: $editingBlock) { block in
                EditBlockView(
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
        }
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

                Text("\(block.durationMinutes) min • \(block.importance.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Visible edit affordance (so it’s not “hidden” behind swipe)
            Image(systemName: "pencil")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }

    private func delete(_ block: ScheduleBlock) {
        blocks.removeAll { $0.id == block.id }
    }
}

// MARK: - Add modal

struct AddBlockView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var activity: String = ""
    @State private var startTime: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var importance: Importance = .medium

    let onSave: (ScheduleBlock) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("e.g., Study, Gym, Japanese", text: $activity)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                }

                Section("Duration") {
                    Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...600, step: 5)
                }

                Section("Importance") {
                    Picker("Importance", selection: $importance) {
                        ForEach(Importance.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
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

                        onSave(ScheduleBlock(
                            activity: trimmed,
                            startTime: startTime,
                            durationMinutes: durationMinutes,
                            importance: importance
                        ))
                        dismiss()
                    }
                    .disabled(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit modal (includes Delete)

struct EditBlockView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var activity: String
    @State private var startTime: Date
    @State private var durationMinutes: Int
    @State private var importance: Importance

    private let original: ScheduleBlock
    let onSave: (ScheduleBlock) -> Void
    let onDelete: (ScheduleBlock) -> Void

    init(block: ScheduleBlock, onSave: @escaping (ScheduleBlock) -> Void, onDelete: @escaping (ScheduleBlock) -> Void) {
        self.original = block
        self.onSave = onSave
        self.onDelete = onDelete

        _activity = State(initialValue: block.activity)
        _startTime = State(initialValue: block.startTime)
        _durationMinutes = State(initialValue: block.durationMinutes)
        _importance = State(initialValue: block.importance)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Activity", text: $activity)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                }

                Section("Duration") {
                    Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...600, step: 5)
                }

                Section("Importance") {
                    Picker("Importance", selection: $importance) {
                        ForEach(Importance.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = activity.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        onSave(ScheduleBlock(
                            id: original.id,
                            activity: trimmed,
                            startTime: startTime,
                            durationMinutes: durationMinutes,
                            importance: importance
                        ))
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

#Preview {
    ContentView()
}

