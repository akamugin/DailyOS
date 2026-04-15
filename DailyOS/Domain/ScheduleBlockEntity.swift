import Foundation
import SwiftData

@Model
final class ScheduleBlockEntity {
    var id: UUID = UUID()
    var day: Date = Date()
    var sortOrder: Int = 0
    var activity: String = ""
    var startTime: Date = Date()
    var durationMinutes: Int = 30
    var reminderLeadMinutes: Int = 10
    var notes: String = ""
    var isDone: Bool = false
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        day: Date,
        sortOrder: Int = 0,
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        reminderLeadMinutes: Int = 10,
        notes: String = "",
        isDone: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.sortOrder = sortOrder
        self.activity = activity
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.reminderLeadMinutes = reminderLeadMinutes
        self.notes = notes
        self.isDone = isDone
        self.updatedAt = updatedAt
    }

    convenience init(from block: ScheduleBlock) {
        self.init(
            id: block.id,
            day: block.day,
            sortOrder: block.sortOrder,
            activity: block.activity,
            startTime: block.startTime,
            durationMinutes: block.durationMinutes,
            reminderLeadMinutes: block.reminderLeadMinutes,
            notes: block.notes,
            isDone: block.isDone,
            updatedAt: Date()
        )
    }

    func asBlock() -> ScheduleBlock {
        ScheduleBlock(
            id: id,
            day: day,
            sortOrder: sortOrder,
            activity: activity,
            startTime: startTime,
            durationMinutes: durationMinutes,
            reminderLeadMinutes: reminderLeadMinutes,
            notes: notes,
            isDone: isDone
        )
    }

    func apply(from block: ScheduleBlock) {
        day = Calendar.current.startOfDay(for: block.day)
        sortOrder = block.sortOrder
        activity = block.activity
        startTime = block.startTime
        durationMinutes = block.durationMinutes
        reminderLeadMinutes = block.reminderLeadMinutes
        notes = block.notes
        isDone = block.isDone
        updatedAt = Date()
    }
}
