import Foundation
import SwiftUI

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published private(set) var selectedDate: Date
    @Published private(set) var dayBlocks: [ScheduleBlock] = []
    @Published var errorMessage: String?

    private let repository: ScheduleBlockRepository
    private let reminderScheduler: ReminderScheduling
    private let migrationService: MigrationService
    private let tracer: PerformanceTracer
    private let calendar = Calendar.current

    private var didBootstrap = false

    init(
        repository: ScheduleBlockRepository,
        reminderScheduler: ReminderScheduling,
        migrationService: MigrationService,
        tracer: PerformanceTracer = .shared,
        initialDate: Date = Date()
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
        self.migrationService = migrationService
        self.tracer = tracer
        self.selectedDate = calendar.startOfDay(for: initialDate)
    }

    var selectedDayStart: Date {
        calendar.startOfDay(for: selectedDate)
    }

    func onAppear() {
        guard !didBootstrap else { return }
        didBootstrap = true

        Task {
            await bootstrap()
        }
    }

    func jumpToToday() {
        selectDate(Date())
    }

    func selectDate(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        selectedDate = day

        do {
            try loadDay(for: day)
        } catch {
            handle(error, event: .queryDay, message: "Failed to load selected day")
        }
    }

    func goToNextDay() {
        tracer.measure(.daySwipe, message: "next-day") {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            selectDate(nextDay)
        }
    }

    func goToPreviousDay() {
        tracer.measure(.daySwipe, message: "previous-day") {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            selectDate(previousDay)
        }
    }

    func add(_ newBlock: ScheduleBlock) {
        do {
            try tracer.measure(.addBlock, message: "day=\(selectedDayStart)") {
                var blocks = try repository.fetchBlocks(for: selectedDayStart)
                blocks.append(newBlock.withDay(selectedDayStart))

                let anchor = blocks.map(\.startTime).min() ?? newBlock.startTime
                let recalculated = recalculateTimes(for: blocks, anchor: anchor, dayStart: selectedDayStart)

                try repository.upsert(blocks: recalculated)
                try repository.saveChanges()
                dayBlocks = recalculated
            }

            Task {
                await syncRemindersFromStore()
            }
        } catch {
            handle(error, event: .addBlock, message: "Failed to add block")
        }
    }

    func update(_ updatedBlock: ScheduleBlock) {
        let dayStart = calendar.startOfDay(for: updatedBlock.day)

        do {
            try tracer.measure(.editBlock, message: "id=\(updatedBlock.id.uuidString)") {
                var blocks = try repository.fetchBlocks(for: dayStart)

                if let index = blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
                    blocks[index] = updatedBlock.withDay(dayStart)
                } else {
                    blocks.append(updatedBlock.withDay(dayStart))
                }

                let anchor = blocks.map(\.startTime).min() ?? updatedBlock.startTime
                let recalculated = recalculateTimes(for: blocks, anchor: anchor, dayStart: dayStart)

                try repository.upsert(blocks: recalculated)
                try repository.saveChanges()

                if calendar.isDate(dayStart, inSameDayAs: selectedDayStart) {
                    dayBlocks = recalculated
                } else {
                    try loadDay(for: selectedDayStart)
                }
            }

            Task {
                await syncRemindersFromStore()
            }
        } catch {
            handle(error, event: .editBlock, message: "Failed to update block")
        }
    }

    func delete(_ block: ScheduleBlock) {
        let dayStart = calendar.startOfDay(for: block.day)

        do {
            try tracer.measure(.deleteBlock, message: "id=\(block.id.uuidString)") {
                try repository.delete(id: block.id)
                try repository.saveChanges()
                try normalizeDaySchedule(for: dayStart)

                if calendar.isDate(dayStart, inSameDayAs: selectedDayStart) {
                    try loadDay(for: selectedDayStart)
                }
            }

            Task {
                await syncRemindersFromStore()
            }
        } catch {
            handle(error, event: .deleteBlock, message: "Failed to delete block")
        }
    }

    func toggleDone(_ block: ScheduleBlock) {
        do {
            try tracer.measure(.toggleDone, message: "id=\(block.id.uuidString)") {
                let updated = block.toggledDone().withDay(block.day)
                try repository.upsert(block: updated)
                try repository.saveChanges()

                if let index = dayBlocks.firstIndex(where: { $0.id == updated.id }) {
                    dayBlocks[index] = updated
                }
            }

            Task {
                await syncRemindersFromStore()
            }
        } catch {
            handle(error, event: .toggleDone, message: "Failed to toggle block completion")
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        do {
            try tracer.measure(.reorder, message: "day=\(selectedDayStart)") {
                var moved = dayBlocks
                moved.move(fromOffsets: source, toOffset: destination)
                guard !moved.isEmpty else { return }

                let anchor = moved.map(\.startTime).min() ?? selectedDayStart
                let recalculated = recalculateTimes(for: moved, anchor: anchor, dayStart: selectedDayStart)

                try repository.upsert(blocks: recalculated)
                try repository.saveChanges()
                dayBlocks = recalculated
            }

            Task {
                await syncRemindersFromStore()
            }
        } catch {
            handle(error, event: .reorder, message: "Failed to reorder blocks")
        }
    }

    private func bootstrap() async {
        let trace = tracer.begin(.launch, message: "initial-bootstrap")
        defer { tracer.end(trace) }

        do {
            _ = try migrationService.migrateIfNeeded()
            try loadDay(for: selectedDayStart)
        } catch {
            handle(error, event: .launch, message: "Bootstrap migration/load failed")
            return
        }

        _ = await reminderScheduler.requestAuthorizationIfNeeded()
        await syncRemindersFromStore()
    }

    private func loadDay(for day: Date) throws {
        let dayStart = calendar.startOfDay(for: day)

        dayBlocks = try tracer.measure(.queryDay, message: "day=\(dayStart)") {
            try repository.fetchBlocks(for: dayStart)
        }
    }

    private func normalizeDaySchedule(for day: Date) throws {
        let dayStart = calendar.startOfDay(for: day)
        let blocks = try repository.fetchBlocks(for: dayStart)

        guard !blocks.isEmpty else { return }

        let anchor = blocks.map(\.startTime).min() ?? dayStart
        let recalculated = recalculateTimes(for: blocks, anchor: anchor, dayStart: dayStart)

        try repository.upsert(blocks: recalculated)
        try repository.saveChanges()
    }

    private func recalculateTimes(for blocks: [ScheduleBlock], anchor: Date, dayStart: Date) -> [ScheduleBlock] {
        let ordered = blocks.sorted { $0.startTime < $1.startTime }
        var cursor = anchor

        return ordered.map { block in
            defer {
                cursor = calendar.date(byAdding: .minute, value: block.durationMinutes, to: cursor) ?? cursor
            }

            return block
                .withDay(dayStart)
                .withStartTime(cursor)
        }
    }

    private func syncRemindersFromStore() async {
        do {
            let blocks = try repository.fetchAllBlocks()
            await reminderScheduler.sync(blocks: blocks)
        } catch {
            handle(error, event: .reminderSync, message: "Failed to sync reminders")
        }
    }

    private func handle(_ error: Error, event: PerformanceTracer.Event, message: String) {
        tracer.recordError(error, event: event, message: message)
        errorMessage = message
    }
}
