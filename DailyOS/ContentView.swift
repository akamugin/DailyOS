import SwiftData
import SwiftUI

// MARK: - Theme

enum DailyTheme {
    static let babyPink = Color(red: 0.99, green: 0.86, blue: 0.92)
    static let skyBlue = Color(red: 0.82, green: 0.92, blue: 1.00)
    static let babyPurple = Color(red: 0.88, green: 0.84, blue: 1.00)
    static let pinkMist = Color(red: 0.99, green: 0.94, blue: 0.97)
    static let lilacMist = Color(red: 0.95, green: 0.93, blue: 1.00)
    static let cream = Color(red: 0.99, green: 0.98, blue: 0.97)
    static let roseText = Color(red: 0.38, green: 0.29, blue: 0.34)
    static let ribbon = Color(red: 0.91, green: 0.78, blue: 0.97)

    static let stroke = roseText.opacity(0.12)
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @AppStorage(StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(StorageKeys.onboardingPainPoint) private var onboardingPainPointRaw = OnboardingPainPoint.procrastination.rawValue

    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock?
    @State private var pendingDeleteBlock: ScheduleBlock?
    @State private var showCalendar = false
    @State private var showOnboarding = false
    @State private var swipeDirection = 0

    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.selectedDate },
            set: { viewModel.selectDate($0) }
        )
    }

    private var onboardingPainPoint: OnboardingPainPoint {
        OnboardingPainPoint(rawValue: onboardingPainPointRaw) ?? .procrastination
    }

    private var completedBlockCount: Int {
        viewModel.dayBlocks.filter(\.isDone).count
    }

    private var completionSummary: String {
        guard !viewModel.dayBlocks.isEmpty else { return "Starter day helps you begin faster" }
        return "\(completedBlockCount)/\(viewModel.dayBlocks.count) complete today"
    }

    private var emptyStateMessage: String {
        onboardingPainPoint.emptyStatePrompt
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                GreetingBoxView()
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                HStack(alignment: .firstTextBaseline) {
                    Text(ScheduleFormatters.shortDateString(viewModel.selectedDate))
                        .cuteHeadline()
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(viewModel.dayBlocks.count) plans")
                            .cuteCaption()
                    }
                    .foregroundStyle(DailyTheme.roseText.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(DailyTheme.lilacMist.opacity(0.8)))
                }
                .padding(.horizontal, 24)

                HStack {
                    Text(completionSummary)
                        .cuteCaption(weight: .demiBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(DailyTheme.skyBlue.opacity(0.28)))
                    Spacer()
                }
                .padding(.horizontal, 24)

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
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                }
                                // NOTE: List reordering only works in Edit mode.
                                // Keeping the handler here so you can re-enable later if you want.
                                .onMove(perform: moveTodayBlocks)
                            }
                            .onMove(perform: moveTodayBlocks)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: 760, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        .cuteBody()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(DailyTheme.babyPurple.opacity(0.42))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Jump to today")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCalendar = true } label: {
                        toolbarBubble(systemName: "calendar", fill: DailyTheme.skyBlue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open calendar")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        toolbarBubble(systemName: "plus", fill: DailyTheme.babyPink)
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
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView { selectedPainPoint, shouldCreateStarterDay in
                    onboardingPainPointRaw = selectedPainPoint.rawValue
                    hasCompletedOnboarding = true
                    if shouldCreateStarterDay {
                        addStarterDayIfNeeded(for: viewModel.selectedDate, painPoint: selectedPainPoint)
                    }
                    showOnboarding = false
                }
                .interactiveDismissDisabled()
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
            showOnboarding = !hasCompletedOnboarding
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nothing planned yet")
                .cuteBody(weight: .demiBold)
            Text(emptyStateMessage)
                .cuteCaption()
                .foregroundStyle(.secondary)
            Button {
                addStarterDayIfNeeded(for: viewModel.selectedDate, painPoint: onboardingPainPoint)
            } label: {
                Label("Build starter day", systemImage: "wand.and.stars")
                    .cuteCaption(weight: .demiBold)
            }
            .buttonStyle(.borderedProminent)
            .tint(DailyTheme.babyPurple)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private func blockRow(_ block: ScheduleBlock) -> some View {
        HStack(spacing: 12) {
            Button { viewModel.toggleDone(block) } label: {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(block.isDone ? DailyTheme.babyPurple : DailyTheme.roseText.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(block.isDone ? "Mark block as not done" : "Mark block as done")

            Text(ScheduleFormatters.timeString(block.startTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.activity)
                    .cuteBody(weight: .demiBold)
                    .strikethrough(block.isDone, color: .secondary)
                    .foregroundStyle(block.isDone ? .secondary : DailyTheme.roseText)

                Text("\(block.durationMinutes) min")
                    .cuteCaption()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(DailyTheme.pinkMist.opacity(0.9)))
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundStyle(DailyTheme.skyBlue.opacity(0.85))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DailyTheme.stroke, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(DailyTheme.ribbon.opacity(0.8))
                .padding(8)
        }
        .shadow(color: DailyTheme.skyBlue.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.activity), \(ScheduleFormatters.timeString(block.startTime)), \(block.durationMinutes) minutes")
        .accessibilityHint("Double tap to edit")
    }

    private func toolbarBubble(systemName: String, fill: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(DailyTheme.roseText)
            .frame(minWidth: 44, minHeight: 44)
            .background(
                Circle().fill(fill.opacity(0.4))
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(x: 2, y: -2)
            }
    }

    private func addStarterDayIfNeeded(for day: Date, painPoint: OnboardingPainPoint) {
        viewModel.selectDate(day)
        guard viewModel.dayBlocks.isEmpty else { return }

        let starterBlocks = painPoint.starterTemplate.map { item in
            ScheduleBlock(
                day: day,
                activity: item.activity,
                startTime: date(for: day, hour: item.hour, minute: item.minute),
                durationMinutes: item.durationMinutes,
                reminderLeadMinutes: item.reminderLeadMinutes
            )
        }

        for block in starterBlocks {
            viewModel.add(block)
        }
    }

    private func moveTodayBlocks(from source: IndexSet, to destination: Int) {
        viewModel.move(from: source, to: destination)
    }
}

// MARK: - Onboarding

struct StarterTemplateItem {
    let activity: String
    let hour: Int
    let minute: Int
    let durationMinutes: Int
    let reminderLeadMinutes: Int
}

enum OnboardingPainPoint: String, CaseIterable, Identifiable {
    case procrastination
    case overwhelmed
    case distracted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .procrastination: return "I procrastinate getting started"
        case .overwhelmed: return "My day feels overloaded"
        case .distracted: return "I lose focus after I start"
        }
    }

    var subtitle: String {
        switch self {
        case .procrastination: return "Short warm-up blocks and quick wins."
        case .overwhelmed: return "Fewer blocks with breathing room."
        case .distracted: return "Deep work windows with reset breaks."
        }
    }

    var emptyStatePrompt: String {
        switch self {
        case .procrastination: return "Start with a prebuilt day and beat the first-task friction."
        case .overwhelmed: return "Use a lighter starter day so your plan feels realistic."
        case .distracted: return "Use a focus-first starter day to reduce context switching."
        }
    }

    var starterTemplate: [StarterTemplateItem] {
        switch self {
        case .procrastination:
            return [
                StarterTemplateItem(activity: "10-min setup sprint", hour: 9, minute: 0, durationMinutes: 10, reminderLeadMinutes: 5),
                StarterTemplateItem(activity: "Priority task (part 1)", hour: 9, minute: 15, durationMinutes: 45, reminderLeadMinutes: 10),
                StarterTemplateItem(activity: "Break + reset", hour: 10, minute: 5, durationMinutes: 15, reminderLeadMinutes: 5),
                StarterTemplateItem(activity: "Priority task (part 2)", hour: 10, minute: 25, durationMinutes: 45, reminderLeadMinutes: 10)
            ]
        case .overwhelmed:
            return [
                StarterTemplateItem(activity: "Top 3 plan", hour: 9, minute: 0, durationMinutes: 20, reminderLeadMinutes: 5),
                StarterTemplateItem(activity: "Most important task", hour: 9, minute: 30, durationMinutes: 60, reminderLeadMinutes: 10),
                StarterTemplateItem(activity: "Admin / messages", hour: 11, minute: 0, durationMinutes: 30, reminderLeadMinutes: 10),
                StarterTemplateItem(activity: "Buffer block", hour: 14, minute: 0, durationMinutes: 45, reminderLeadMinutes: 10)
            ]
        case .distracted:
            return [
                StarterTemplateItem(activity: "Focus block 1", hour: 9, minute: 0, durationMinutes: 50, reminderLeadMinutes: 10),
                StarterTemplateItem(activity: "Short walk", hour: 9, minute: 55, durationMinutes: 10, reminderLeadMinutes: 5),
                StarterTemplateItem(activity: "Focus block 2", hour: 10, minute: 10, durationMinutes: 50, reminderLeadMinutes: 10),
                StarterTemplateItem(activity: "Review + next action", hour: 11, minute: 5, durationMinutes: 20, reminderLeadMinutes: 5)
            ]
        }
    }
}

struct OnboardingView: View {
    @State private var selectedPainPoint: OnboardingPainPoint = .procrastination

    let onComplete: (OnboardingPainPoint, Bool) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Plan your day in 60 seconds")
                        .cuteHeadline()

                    Text("What gets in the way most often?")
                        .cuteBody(weight: .demiBold)

                    VStack(spacing: 12) {
                        ForEach(OnboardingPainPoint.allCases) { painPoint in
                            Button {
                                selectedPainPoint = painPoint
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: selectedPainPoint == painPoint ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedPainPoint == painPoint ? DailyTheme.babyPurple : DailyTheme.roseText.opacity(0.5))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(painPoint.title)
                                            .cuteBody(weight: .demiBold)
                                        Text(painPoint.subtitle)
                                            .cuteCaption()
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(.white.opacity(0.72))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    Button {
                        onComplete(selectedPainPoint, true)
                    } label: {
                        Text("Create my starter day")
                            .cuteBody(weight: .demiBold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DailyTheme.babyPurple)

                    Button("Skip for now") {
                        onComplete(selectedPainPoint, false)
                    }
                    .frame(maxWidth: .infinity)
                    .cuteCaption()
                }
                .padding(24)
                .frame(maxWidth: 760, maxHeight: .infinity, alignment: .topLeading)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - GreetingBoxView

struct GreetingBoxView: View {
    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text(greetingText())
                    .cuteBody(weight: .demiBold)
            }
            .foregroundStyle(DailyTheme.roseText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(DailyTheme.babyPink.opacity(0.38))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1)
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
            ZStack {
                PastelOrbBackground()
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .glassPanel()
                .padding(.horizontal, 14)
                .frame(maxWidth: 560)
            }
            .padding(.bottom)
            .navigationTitle("Pick a date")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .cuteBody(weight: .demiBold)
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
                .cuteCaption(weight: .demiBold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(DailyTheme.lilacMist.opacity(0.88))
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
    @State private var reminderLeadMinutes: Int = 10
    @State private var notes: String = ""

    let onSave: (ScheduleBlock) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground()

                Form {
                    Section("Activity") {
                        TextField("e.g., Study, Work out, Dance", text: $activity)
                            .cuteBody()
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

                    Section("Reminder") {
                        Picker("Remind me", selection: $reminderLeadMinutes) {
                            ForEach(ReminderLeadOptions.all, id: \.self) { minutes in
                                Text(reminderLabel(for: minutes)).tag(minutes)
                            }
                        }
                    }

                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 180)
                            .font(.custom("AvenirNext-Regular", size: 17))
                    }
                }
                .scrollContentBackground(.hidden)
                .formStyle(.grouped)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .cuteBody(weight: .demiBold)
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
                                reminderLeadMinutes: reminderLeadMinutes,
                                notes: normalizedNotes
                            )
                        )
                        dismiss()
                    }
                    .cuteBody(weight: .demiBold)
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
    @State private var reminderLeadMinutes: Int
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
        _reminderLeadMinutes = State(initialValue: block.reminderLeadMinutes)
        _notes = State(initialValue: block.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground()

                Form {
                    Section("Activity") {
                        TextField("Activity", text: $activity)
                            .cuteBody()
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

                    Section("Reminder") {
                        Picker("Remind me", selection: $reminderLeadMinutes) {
                            ForEach(ReminderLeadOptions.all, id: \.self) { minutes in
                                Text(reminderLabel(for: minutes)).tag(minutes)
                            }
                        }
                    }

                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 180)
                            .font(.custom("AvenirNext-Regular", size: 17))
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
                .formStyle(.grouped)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .cuteBody(weight: .demiBold)
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
                                reminderLeadMinutes: reminderLeadMinutes,
                                notes: normalizedNotes,
                                isDone: original.isDone
                            )
                        )
                        dismiss()
                    }
                    .cuteBody(weight: .demiBold)
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
                    .stroke(.white.opacity(0.50), lineWidth: 1)
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

struct PastelOrbBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 1.00),
                    Color(red: 1.00, green: 0.96, blue: 0.98),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(DailyTheme.skyBlue.opacity(0.28))
                .frame(width: 270, height: 270)
                .offset(x: 130, y: -280)
                .blur(radius: 12)

            Circle()
                .fill(DailyTheme.babyPink.opacity(0.30))
                .frame(width: 230, height: 230)
                .offset(x: -130, y: -180)
                .blur(radius: 14)

            Circle()
                .fill(DailyTheme.babyPurple.opacity(0.26))
                .frame(width: 260, height: 260)
                .offset(x: -120, y: 330)
                .blur(radius: 16)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func glassPanel() -> some View { modifier(GlassPanel()) }

    func cuteHeadline() -> some View {
        self
            .font(.custom("Didot-Bold", size: 38))
            .foregroundStyle(DailyTheme.roseText)
    }

    func cuteBody(weight: AvenirWeight = .regular) -> some View {
        self
            .font(.custom(weight.fontName, size: 17))
            .foregroundStyle(DailyTheme.roseText)
    }

    func cuteCaption(weight: AvenirWeight = .medium) -> some View {
        self
            .font(.custom(weight.fontName, size: 14))
            .foregroundStyle(DailyTheme.roseText.opacity(0.8))
    }
}

enum AvenirWeight {
    case regular
    case medium
    case demiBold

    var fontName: String {
        switch self {
        case .regular:
            return "AvenirNext-Regular"
        case .medium:
            return "AvenirNext-Medium"
        case .demiBold:
            return "AvenirNext-DemiBold"
        }
    }
}

private enum ReminderLeadOptions {
    static let all = [0, 5, 10, 15, 30, 60]
}

private func reminderLabel(for minutes: Int) -> String {
    if minutes == 0 { return "At start time" }
    if minutes == 1 { return "1 minute before" }
    return "\(minutes) minutes before"
}

private func date(for day: Date, hour: Int, minute: Int) -> Date {
    let cal = Calendar.current
    let dayComps = cal.dateComponents([.year, .month, .day], from: day)

    var comps = DateComponents()
    comps.year = dayComps.year
    comps.month = dayComps.month
    comps.day = dayComps.day
    comps.hour = hour
    comps.minute = minute

    return cal.date(from: comps) ?? day
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
