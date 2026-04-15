import SwiftData
import SwiftUI

// MARK: - Theme

enum DailyTheme {
    static func softSky(for tint: AppTint) -> Color {
        tint.baseColor
    }

    static func accent(for tint: AppTint) -> Color {
        tint.strongColor
    }

    static func accentSoft(for tint: AppTint) -> Color {
        tint.baseColor.opacity(0.9)
    }

    static let sky = Color(red: 0.94, green: 0.98, blue: 1.00)
    static let mist = Color(red: 0.97, green: 0.99, blue: 1.00)
    static let cloud = Color.white
    static let cloudSoft = Color(red: 0.98, green: 0.99, blue: 1.00)

    static let text = Color(red: 0.38, green: 0.49, blue: 0.60)
    static let textSoft = Color(red: 0.55, green: 0.66, blue: 0.77)
    static let sparkle = Color(red: 0.96, green: 0.99, blue: 1.00)

    static func shadowColor(for tint: AppTint) -> Color {
        tint.strongColor
    }

    static func stroke(for tint: AppTint) -> Color {
        tint.strongColor.opacity(0.14)
    }

    static let softStroke = Color.white.opacity(0.92)
}

enum AppTint: String, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var baseColor: Color {
        switch self {
        case .red:
            return Color(red: 1.00, green: 0.72, blue: 0.72)
        case .orange:
            return Color(red: 1.00, green: 0.82, blue: 0.66)
        case .yellow:
            return Color(red: 1.00, green: 0.92, blue: 0.62)
        case .green:
            return Color(red: 0.72, green: 0.90, blue: 0.74)
        case .blue:
            return Color(red: 0.74, green: 0.88, blue: 1.00)
        case .purple:
            return Color(red: 0.82, green: 0.74, blue: 1.00)
        case .pink:
            return Color(red: 1.00, green: 0.78, blue: 0.88)
        }
    }

    var strongColor: Color {
        switch self {
        case .red:
            return Color(red: 0.93, green: 0.45, blue: 0.45)
        case .orange:
            return Color(red: 0.95, green: 0.62, blue: 0.34)
        case .yellow:
            return Color(red: 0.90, green: 0.76, blue: 0.28)
        case .green:
            return Color(red: 0.42, green: 0.73, blue: 0.48)
        case .blue:
            return Color(red: 0.56, green: 0.77, blue: 1.00)
        case .purple:
            return Color(red: 0.67, green: 0.56, blue: 0.94)
        case .pink:
            return Color(red: 0.95, green: 0.55, blue: 0.73)
        }
    }
}

struct CandyButtonStyle: ButtonStyle {
    var tint: AppTint = .blue

    func makeBody(configuration: Configuration) -> some View {
        let fill = LinearGradient(
            colors: [
                DailyTheme.cloud,
                DailyTheme.mist,
                DailyTheme.softSky(for: tint).opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let shadowColor = DailyTheme.shadowColor(for: tint).opacity(configuration.isPressed ? 0.05 : 0.14)
        let shadowRadius: CGFloat = configuration.isPressed ? 4 : 12
        let shadowY: CGFloat = configuration.isPressed ? 2 : 6
        let scale: CGFloat = configuration.isPressed ? 0.97 : 1

        return configuration.label
            .foregroundStyle(DailyTheme.text)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(fill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DailyTheme.softStroke, lineWidth: 1.2)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DailyTheme.stroke(for: tint), lineWidth: 0.9)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SoftPillButtonStyle: ButtonStyle {
    var tint: AppTint = .blue
    var fill: Color = DailyTheme.cloud.opacity(0.96)

    func makeBody(configuration: Configuration) -> some View {
        let gradient = LinearGradient(
            colors: [fill, DailyTheme.mist],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let borderColor = DailyTheme.accent(for: tint).opacity(0.12)
        let shadowColor = DailyTheme.shadowColor(for: tint).opacity(configuration.isPressed ? 0.03 : 0.08)
        let shadowRadius: CGFloat = configuration.isPressed ? 2 : 8
        let shadowY: CGFloat = configuration.isPressed ? 1 : 4
        let scale: CGFloat = configuration.isPressed ? 0.98 : 1

        return configuration.label
            .foregroundStyle(DailyTheme.text.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(gradient)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DailyTheme.softStroke, lineWidth: 1)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 0.8)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @AppStorage private var hasCompletedOnboarding: Bool
    @AppStorage private var onboardingPainPointRaw: String
    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    private let skipsBootstrapOnAppear: Bool

    @State private var showAdd = false
    @State private var editingBlock: ScheduleBlock?
    @State private var pendingDeleteBlock: ScheduleBlock?
    @State private var showCalendar = false
    @State private var showOnboarding = false
    @State private var showThemePicker = false
    @State private var swipeDirection = 0
    @State private var draggedBlock: ScheduleBlock?
    @State private var dragOffset: CGSize = .zero

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    @MainActor
    private static let previewDependencies = makePreviewDependencies()

    init(
        viewModel: ScheduleViewModel,
        appStorage: UserDefaults? = nil,
        skipsBootstrapOnAppear: Bool = false
    ) {
        self.viewModel = viewModel
        self.skipsBootstrapOnAppear = skipsBootstrapOnAppear
        _hasCompletedOnboarding = AppStorage(
            wrappedValue: false,
            StorageKeys.hasCompletedOnboarding,
            store: appStorage
        )
        _onboardingPainPointRaw = AppStorage(
            wrappedValue: OnboardingPainPoint.procrastination.rawValue,
            StorageKeys.onboardingPainPoint,
            store: appStorage
        )
    }

    @MainActor
    init() {
        let preview = Self.previewDependencies

        self.init(
            viewModel: preview.viewModel,
            appStorage: preview.defaults,
            skipsBootstrapOnAppear: true
        )
    }

    @MainActor
    private static func makePreviewDependencies() -> PreviewDependencies {
        let defaults = UserDefaults(suiteName: "DailyOSPreview") ?? .standard
        defaults.set(true, forKey: StorageKeys.hasCompletedOnboarding)
        defaults.set(OnboardingPainPoint.procrastination.rawValue, forKey: StorageKeys.onboardingPainPoint)
        defaults.set(AppTint.blue.rawValue, forKey: "selectedAppTint")

        let previewDay = Calendar.current.startOfDay(for: .now)
        let repository = PreviewScheduleBlockRepository(blocks: [
            ScheduleBlock(
                day: previewDay,
                sortOrder: 0,
                activity: "Morning reset",
                startTime: date(for: previewDay, hour: 9, minute: 0),
                durationMinutes: 20,
                reminderLeadMinutes: 5
            ),
            ScheduleBlock(
                day: previewDay,
                sortOrder: 1,
                activity: "Deep work",
                startTime: date(for: previewDay, hour: 10, minute: 0),
                durationMinutes: 90,
                reminderLeadMinutes: 10,
                notes: "Ship the current feature branch"
            ),
            ScheduleBlock(
                day: previewDay,
                sortOrder: 2,
                activity: "Lunch walk",
                startTime: date(for: previewDay, hour: 12, minute: 30),
                durationMinutes: 30,
                reminderLeadMinutes: 0
            )
        ])
        let migrationService = MigrationService(repository: repository, defaults: defaults)

        let viewModel = ScheduleViewModel(
            repository: repository,
            reminderScheduler: PreviewReminderScheduler(),
            migrationService: migrationService,
            initialDate: previewDay
        )
        viewModel.selectDate(previewDay)

        return PreviewDependencies(
            defaults: defaults,
            viewModel: viewModel
        )
    }

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
        return "\(completedBlockCount)/\(viewModel.dayBlocks.count) done"
    }

    private var emptyStateMessage: String {
        onboardingPainPoint.emptyStatePrompt
    }

    var body: some View {
        NavigationStack {
            mainContent
                .toolbar { mainToolbar }
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
        .sheet(isPresented: $showThemePicker) {
            ThemePickerView(selectedTintRaw: $selectedAppTintRaw)
                .presentationDetents([.medium])
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
        .onAppear {
            if !skipsBootstrapOnAppear {
                viewModel.onAppear()
            }
            showOnboarding = !hasCompletedOnboarding
        }
    }

    @ToolbarContentBuilder
    private var mainToolbar: some ToolbarContent {
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
            }
            .buttonStyle(CandyButtonStyle(tint: selectedAppTint))
            .accessibilityLabel("Jump to today")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button { showThemePicker = true } label: {
                toolbarBubble(
                    systemName: "paintpalette",
                    fill: DailyTheme.softSky(for: selectedAppTint)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose theme color")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button { showCalendar = true } label: {
                toolbarBubble(
                    systemName: "calendar",
                    fill: DailyTheme.accent(for: selectedAppTint)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open calendar")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button { showAdd = true } label: {
                toolbarBubble(
                    systemName: "plus",
                    fill: DailyTheme.softSky(for: selectedAppTint)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add schedule block")
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            GreetingBoxView()
                .padding(.horizontal, 20)
                .padding(.top, 0)

            headerRow
            completionRow
            blocksList
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: 760, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    DailyTheme.accent(for: selectedAppTint).opacity(0.35),
                    DailyTheme.softSky(for: selectedAppTint).opacity(0.25),
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
        .gesture(daySwipeGesture)
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            Text(ScheduleFormatters.shortDateString(viewModel.selectedDate))
                .cuteHeadline()
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()
            
        }
        .padding(.horizontal, 24)
    }

    private var completionRow: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(completionSummary)
                    .cuteCaption()
                    .lineLimit(1)
            }
            .foregroundStyle(DailyTheme.text.opacity(0.85))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(DailyTheme.mist.opacity(0.8)))
        }
        .padding(.horizontal, 24)
    }

    private var blocksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.dayBlocks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        emptyState
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .glassPanel()
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                } else {
                    ForEach(viewModel.dayBlocks) { block in
                        draggableBlockRow(block)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var daySwipeGesture: some Gesture {
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
            .buttonStyle(CandyButtonStyle(tint: selectedAppTint))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private func blockRow(_ block: ScheduleBlock) -> some View {
        HStack(spacing: 12) {
            Button { viewModel.toggleDone(block) } label: {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        block.isDone
                            ? DailyTheme.accent(for: selectedAppTint)
                            : DailyTheme.text.opacity(0.5)
                    )
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
                    .foregroundStyle(block.isDone ? .secondary : DailyTheme.text)

                Text("\(block.durationMinutes) min")
                    .cuteCaption()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(DailyTheme.cloud.opacity(0.9)))
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundStyle(DailyTheme.accent(for: selectedAppTint).opacity(0.85))
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
                .stroke(DailyTheme.stroke(for: selectedAppTint), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(DailyTheme.sparkle.opacity(0.8))
                .padding(8)
        }
        .shadow(
            color: DailyTheme.accent(for: selectedAppTint).opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.activity), \(ScheduleFormatters.timeString(block.startTime)), \(block.durationMinutes) minutes")
        .accessibilityHint("Double tap to edit")
    }

    private func toolbarBubble(systemName: String, fill: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(DailyTheme.text)
            .frame(minWidth: 38, minHeight: 38)
            .background(
                Circle().fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            fill.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.95), lineWidth: 1.1)
            )
            .overlay(
                Circle().stroke(
                    DailyTheme.accent(for: selectedAppTint).opacity(0.16),
                    lineWidth: 0.8
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 9, height: 9)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(
                                DailyTheme.accent(for: selectedAppTint).opacity(0.9)
                            )
                    )
                    .offset(x: 2, y: -2)
            }
            .shadow(
                color: DailyTheme.accent(for: selectedAppTint).opacity(0.14),
                radius: 7,
                x: 0,
                y: 3
            )
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

    @ViewBuilder
    private func draggableBlockRow(_ block: ScheduleBlock) -> some View {
        let isDragged = draggedBlock?.id == block.id

        blockRow(block)
            .scaleEffect(isDragged ? 1.02 : 1.0)
            .offset(y: isDragged ? dragOffset.height : 0)
            .zIndex(isDragged ? 1 : 0)
            .opacity(isDragged ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isDragged)
            .contentShape(Rectangle())
            .onTapGesture {
                if draggedBlock == nil {
                    editingBlock = block
                }
            }
            .contextMenu {
                Button("Edit") {
                    editingBlock = block
                }

                Button("Delete", role: .destructive) {
                    pendingDeleteBlock = block
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if draggedBlock == nil {
                            draggedBlock = block
                        }

                        guard draggedBlock?.id == block.id else { return }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard draggedBlock?.id == block.id else {
                            draggedBlock = nil
                            dragOffset = .zero
                            return
                        }

                        finishDrag(for: block, translation: value.translation)

                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            draggedBlock = nil
                            dragOffset = .zero
                        }
                    }
            )
    }
    
    private func finishDrag(for block: ScheduleBlock, translation: CGSize) {
        guard let currentIndex = viewModel.dayBlocks.firstIndex(where: { $0.id == block.id }) else { return }

        let rowHeight: CGFloat = 86
        let offset = Int((translation.height / rowHeight).rounded())

        let proposedIndex = currentIndex + offset
        let newIndex = min(max(proposedIndex, 0), viewModel.dayBlocks.count - 1)

        guard newIndex != currentIndex else { return }

        let targetBlock = viewModel.dayBlocks[newIndex]

        withAnimation(.easeInOut(duration: 0.18)) {
            viewModel.swapStartTimesAndResort(first: block, second: targetBlock)
        }
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
    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue
    @State private var selectedPainPoint: OnboardingPainPoint = .procrastination

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    let onComplete: (OnboardingPainPoint, Bool) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground(tint: selectedAppTint)

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
                                        .foregroundStyle(
                                            selectedPainPoint == painPoint
                                                ? DailyTheme.accent(for: selectedAppTint)
                                                : DailyTheme.text.opacity(0.5)
                                        )

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
                    .buttonStyle(CandyButtonStyle(tint: selectedAppTint))

                    Button("Skip for now") {
                        onComplete(selectedPainPoint, false)
                    }
                    .frame(maxWidth: .infinity)
                    .cuteCaption()
                    .buttonStyle(SoftPillButtonStyle(tint: selectedAppTint))
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
    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text(greetingText())
                    .cuteBody(weight: .demiBold)
            }
            .foregroundStyle(DailyTheme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(DailyTheme.softSky(for: selectedAppTint).opacity(0.38))
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
    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground(tint: selectedAppTint)

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
                        .buttonStyle(SoftPillButtonStyle(tint: selectedAppTint))
                }
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let title: String
    let action: () -> Void

    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .cuteCaption(weight: .demiBold)
                .frame(minHeight: 44)
        }
        .buttonStyle(SoftPillButtonStyle(tint: selectedAppTint))
    }
}

// MARK: - Add Block View

struct AddBlockView: View {
    @Environment(\.dismiss) private var dismiss
    let day: Date

    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    @State private var activity: String = ""
    @State private var startTimeOnly: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var reminderLeadMinutes: Int = 10
    @State private var notes: String = ""

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

    let onSave: (ScheduleBlock) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PastelOrbBackground(tint: selectedAppTint)

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

    @AppStorage("selectedAppTint") private var selectedAppTintRaw: String = AppTint.blue.rawValue

    @State private var activity: String
    @State private var startTimeOnly: Date
    @State private var durationMinutes: Int
    @State private var reminderLeadMinutes: Int
    @State private var notes: String

    private var selectedAppTint: AppTint {
        AppTint(rawValue: selectedAppTintRaw) ?? .blue
    }

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
                PastelOrbBackground(tint: selectedAppTint)

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
                                sortOrder: original.sortOrder,
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

// MARK: - Theme Picker

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTintRaw: String

    private var selectedTint: AppTint {
        AppTint(rawValue: selectedTintRaw) ?? .blue
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pick your color")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(DailyTheme.text)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 16)], spacing: 16) {
                    ForEach(AppTint.allCases) { tint in
                        Button {
                            selectedTintRaw = tint.rawValue
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(tint.baseColor)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                    )
                                    .overlay {
                                        if selectedTint == tint {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }

                                Text(tint.displayName)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DailyTheme.text)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [DailyTheme.sky, DailyTheme.mist, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Theme")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
    var tint: AppTint = .blue

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DailyTheme.sky,
                    DailyTheme.mist,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(DailyTheme.accent(for: tint).opacity(0.28))
                .frame(width: 270, height: 270)
                .offset(x: 130, y: -280)
                .blur(radius: 12)

            Circle()
                .fill(DailyTheme.softSky(for: tint).opacity(0.30))
                .frame(width: 230, height: 230)
                .offset(x: -130, y: -180)
                .blur(radius: 14)

            Circle()
                .fill(DailyTheme.mist.opacity(0.26))
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
            .foregroundStyle(DailyTheme.text)
    }

    func cuteBody(weight: AvenirWeight = .regular) -> some View {
        self
            .font(.custom(weight.fontName, size: 17))
            .foregroundStyle(DailyTheme.text)
    }

    func cuteCaption(weight: AvenirWeight = .medium) -> some View {
        self
            .font(.custom(weight.fontName, size: 14))
            .foregroundStyle(DailyTheme.text.opacity(0.8))
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

private struct PreviewDependencies {
    let defaults: UserDefaults
    let viewModel: ScheduleViewModel
}

@MainActor
private final class PreviewScheduleBlockRepository: ScheduleBlockRepository {
    private var blocks: [ScheduleBlock]

    init(blocks: [ScheduleBlock]) {
        self.blocks = blocks.sorted(by: previewBlockSort)
    }

    func fetchBlocks(for day: Date) throws -> [ScheduleBlock] {
        let dayStart = Calendar.current.startOfDay(for: day)
        return blocks
            .filter { Calendar.current.isDate($0.day, inSameDayAs: dayStart) }
            .sorted(by: previewBlockSort)
    }

    func fetchAllBlocks() throws -> [ScheduleBlock] {
        blocks.sorted(by: previewBlockSort)
    }

    func upsert(block: ScheduleBlock) throws {
        if let index = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[index] = block
        } else {
            blocks.append(block)
        }
    }

    func upsert(blocks newBlocks: [ScheduleBlock]) throws {
        for block in newBlocks {
            try upsert(block: block)
        }
    }

    func delete(id: UUID) throws {
        blocks.removeAll { $0.id == id }
    }

    func saveChanges() throws { }
}

private func previewBlockSort(_ lhs: ScheduleBlock, _ rhs: ScheduleBlock) -> Bool {
    if !Calendar.current.isDate(lhs.day, inSameDayAs: rhs.day) {
        return lhs.day < rhs.day
    }
    return lhs.sortOrder < rhs.sortOrder
}

// MARK: - Preview

#Preview {
    ContentView()
}
