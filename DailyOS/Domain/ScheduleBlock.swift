import Foundation

struct ScheduleBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var day: Date
    var sortOrder: Int
    var activity: String
    var startTime: Date
    var durationMinutes: Int
    var reminderLeadMinutes: Int
    var notes: String
    var isDone: Bool

    init(
        id: UUID = UUID(),
        day: Date,
        sortOrder: Int = 0,
        activity: String,
        startTime: Date,
        durationMinutes: Int,
        reminderLeadMinutes: Int = 10,
        notes: String = "",
        isDone: Bool = false
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
    }

    enum CodingKeys: String, CodingKey {
        case id
        case day
        case sortOrder
        case activity
        case startTime
        case durationMinutes
        case reminderLeadMinutes
        case notes
        case isDone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        day = try container.decode(Date.self, forKey: .day)
        sortOrder = (try? container.decode(Int.self, forKey: .sortOrder)) ?? 0
        activity = try container.decode(String.self, forKey: .activity)
        startTime = try container.decode(Date.self, forKey: .startTime)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        reminderLeadMinutes = (try? container.decode(Int.self, forKey: .reminderLeadMinutes)) ?? 10
        notes = (try? container.decode(String.self, forKey: .notes)) ?? ""
        isDone = (try? container.decode(Bool.self, forKey: .isDone)) ?? false
        day = Calendar.current.startOfDay(for: day)
    }

    func withDay(_ newDay: Date) -> ScheduleBlock {
        var copy = self
        copy.day = Calendar.current.startOfDay(for: newDay)
        return copy
    }

    func withStartTime(_ newStartTime: Date) -> ScheduleBlock {
        var copy = self
        copy.startTime = newStartTime
        return copy
    }

    func withSortOrder(_ newSortOrder: Int) -> ScheduleBlock {
        var copy = self
        copy.sortOrder = newSortOrder
        return copy
    }

    func toggledDone() -> ScheduleBlock {
        var copy = self
        copy.isDone.toggle()
        return copy
    }
}
