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
        let dayStart = selectedDayStart

        do {
            try tracer.measure(.addBlock, message: "day=\(dayStart)") {
                var blocks = try repository.fetchBlocks(for: dayStart)

                let normalized = newBlock.withDay(dayStart)
                blocks.append(normalized)

                let reordered = blocks
                    .sorted(by: blockStartTimeSort)
                    .enumerated()
                    .map { index, block in
                        block.withSortOrder(index)
                    }

                try repository.upsert(blocks: reordered)
                try repository.saveChanges()
                dayBlocks = reordered
            }

            scheduleReminderSync()
        } catch {
            handle(error, event: .addBlock, message: "Failed to add block")
        }
    }

    func update(_ updatedBlock: ScheduleBlock) {
        let dayStart = calendar.startOfDay(for: updatedBlock.day)

        do {
            try tracer.measure(.editBlock, message: "id=\(updatedBlock.id.uuidString)") {
                let normalized = updatedBlock.withDay(dayStart)
                try repository.upsert(block: normalized)
                try repository.saveChanges()

                if dayStart == selectedDayStart {
                    try normalizeSelectedDayByStartTime()
                } else {
                    try reloadSelectedDay()
                }
            }

            scheduleReminderSync()
        } catch {
            handle(error, event: .editBlock, message: "Failed to update block")
        }
    }

    func delete(_ block: ScheduleBlock) {
        do {
            try tracer.measure(.deleteBlock, message: "id=\(block.id.uuidString)") {
                try repository.delete(id: block.id)
                try repository.saveChanges()

                if calendar.isDate(block.day, inSameDayAs: selectedDayStart) {
                    try normalizeSelectedDayKeepingCurrentOrder()
                } else {
                    try reloadSelectedDay()
                }
            }

            scheduleReminderSync()
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

            scheduleReminderSync()
        } catch {
            handle(error, event: .toggleDone, message: "Failed to toggle block completion")
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        do {
            try tracer.measure(.reorder, message: "day=\(selectedDayStart)") {
                var reordered = dayBlocks
                reordered.move(fromOffsets: source, toOffset: destination)
                reordered = reordered.enumerated().map { index, block in
                    block.withSortOrder(index)
                }

                try repository.upsert(blocks: reordered)
                try repository.saveChanges()
                dayBlocks = reordered
            }
        } catch {
            handle(error, event: .reorder, message: "Failed to reorder blocks")
        }
    }

    func reorderByStartTime() {
        do {
            try tracer.measure(.reorder, message: "sort-by-start-time day=\(selectedDayStart)") {
                try normalizeSelectedDayByStartTime()
            }
        } catch {
            handle(error, event: .reorder, message: "Failed to reorder blocks by start time")
        }
    }

    func swapStartTimesAndResort(first: ScheduleBlock, second: ScheduleBlock) {
        guard first.id != second.id else { return }
        guard calendar.isDate(first.day, inSameDayAs: second.day) else { return }

        do {
            try tracer.measure(.reorder, message: "swap-start-times day=\(selectedDayStart)") {
                var updatedFirst = first
                var updatedSecond = second

                let firstTime = updatedFirst.startTime
                updatedFirst.startTime = updatedSecond.startTime
                updatedSecond.startTime = firstTime

                try repository.upsert(block: updatedFirst)
                try repository.upsert(block: updatedSecond)
                try repository.saveChanges()

                try normalizeSelectedDayByStartTime()
            }
        } catch {
            handle(error, event: .reorder, message: "Failed to swap block times")
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

    private func reloadSelectedDay() throws {
        try loadDay(for: selectedDayStart)
    }

    private func normalizeSelectedDayByStartTime() throws {
        let normalized = try repository.fetchBlocks(for: selectedDayStart)
            .sorted(by: blockStartTimeSort)
            .enumerated()
            .map { index, block in
                block.withSortOrder(index)
            }

        try repository.upsert(blocks: normalized)
        try repository.saveChanges()
        dayBlocks = normalized
    }

    private func normalizeSelectedDayKeepingCurrentOrder() throws {
        let normalized = try repository.fetchBlocks(for: selectedDayStart)
            .sorted(by: blockSortOrderSort)
            .enumerated()
            .map { index, block in
                block.withSortOrder(index)
            }

        try repository.upsert(blocks: normalized)
        try repository.saveChanges()
        dayBlocks = normalized
    }

    private func scheduleReminderSync() {
        Task {
            await syncRemindersFromStore()
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

    private func blockStartTimeSort(_ lhs: ScheduleBlock, _ rhs: ScheduleBlock) -> Bool {
        if lhs.startTime != rhs.startTime {
            return lhs.startTime < rhs.startTime
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    private func blockSortOrderSort(_ lhs: ScheduleBlock, _ rhs: ScheduleBlock) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
