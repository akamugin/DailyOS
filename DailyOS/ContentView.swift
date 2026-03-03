import SwiftData
import SwiftUI

// MARK: - Theme

enum DailyTheme {
    static let babyPink = Color(red: 1.00, green: 0.83, blue: 0.90)
    static let skyBlue = Color(red: 0.74, green: 0.90, blue: 1.00)
    static let lavender = Color(red: 0.86, green: 0.82, blue: 1.00)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.95)

    static let stroke = skyBlue.opacity(0.35)
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var viewModel: ScheduleViewModel

    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock?
    @State private var pendingDeleteBlock: ScheduleBlock?
    @State private var showCalendar = false
    @State private var swipeDirection = 0

    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.selectedDate },
            set: { viewModel.selectDate($0) }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                GreetingBoxView()
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                Text(ScheduleFormatters.shortDateString(viewModel.selectedDate))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .padding(.horizontal, 26)

                List {
                    Section {
                        if viewModel.dayBlocks.isEmpty {
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
                            ForEach(viewModel.dayBlocks) { block in
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
            .id(viewModel.selectedDayStart)
            .transition(
                .asymmetric(
                    insertion: .move(edge: swipeDirection == -1 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: swipeDirection == -1 ? .leading : .trailing).combined(with: .opacity)
                )
            )
            .animation(.easeInOut(duration: 0.22), value: viewModel.selectedDayStart)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            swipeDirection = -1
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.goToNextDay()
                            }
                        } else if value.translation.width > 50 {
                            swipeDirection = 1
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.goToPreviousDay()
                            }
                        }
                    }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.jumpToToday()
                        }
                    } label: {
                        Text(
                            Calendar.current.isDateInToday(viewModel.selectedDate)
                                ? "Today"
                                : ScheduleFormatters.shortDateString(viewModel.selectedDate)
                        )
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
                AddBlockView(day: viewModel.selectedDate) { newBlock in
                    viewModel.add(newBlock)
                }
            }
            .sheet(item: $editingBlock) { block in
                EditBlockView(
                    day: viewModel.selectedDate,
                    block: block,
                    onSave: { updated in
                        viewModel.update(updated)
                        editingBlock = nil
                    },
                    onDelete: { toDelete in
                        viewModel.delete(toDelete)
                        editingBlock = nil
                    }
                )
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(selectedDate: selectedDateBinding)
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
                        viewModel.delete(block)
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
            .alert(
                "Operation failed",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
        .onAppear {
            viewModel.onAppear()
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
            Button { viewModel.toggleDone(block) } label: {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(block.isDone ? DailyTheme.skyBlue : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(block.isDone ? "Mark block as not done" : "Mark block as done")

            Text(ScheduleFormatters.timeString(block.startTime))
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
        .accessibilityLabel("\(block.activity), \(ScheduleFormatters.timeString(block.startTime)), \(block.durationMinutes) minutes")
        .accessibilityHint("Double tap to edit")
    }

    private func moveTodayBlocks(from source: IndexSet, to destination: Int) {
        viewModel.move(from: source, to: destination)
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

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ScheduleBlockEntity.self, configurations: configuration)
    let repository = SwiftDataScheduleBlockRepository(modelContext: container.mainContext)
    let migrationDefaults = UserDefaults(suiteName: "DailyOSPreview") ?? .standard
    let migrationService = MigrationService(repository: repository, defaults: migrationDefaults)
    let viewModel = ScheduleViewModel(
        repository: repository,
        reminderScheduler: PreviewReminderScheduler(),
        migrationService: migrationService
    )

    return ContentView(viewModel: viewModel)
        .modelContainer(container)
}
