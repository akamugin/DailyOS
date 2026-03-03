import Foundation
import SwiftData

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

    func asBlock() -> ScheduleBlock {
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
