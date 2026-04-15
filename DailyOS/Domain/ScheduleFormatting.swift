import Foundation

func greetingText(referenceDate: Date = Date()) -> String {
    let hour = Calendar.current.component(.hour, from: referenceDate)
    if hour < 12 { return "Good Morning ♡" }
    if hour < 18 { return "Good Afternoon ♡" }
    return "Good Night ♡"
}

func combine(day: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    var components = DateComponents()
    components.year = dayComponents.year
    components.month = dayComponents.month
    components.day = dayComponents.day
    components.hour = timeComponents.hour
    components.minute = timeComponents.minute

    return calendar.date(from: components) ?? day
}

enum ScheduleFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func timeString(_ date: Date) -> String {
        time.string(from: date)
    }

    static func shortDateString(_ date: Date) -> String {
        shortDate.string(from: date)
    }
}
