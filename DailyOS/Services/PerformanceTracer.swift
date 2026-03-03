import Foundation
import OSLog

struct TraceHandle {
    let id: OSSignpostID
    let event: PerformanceTracer.Event
    let startedAt: ContinuousClock.Instant
    let message: String
}

final class PerformanceTracer {
    enum Event: String {
        case launch
        case migration
        case queryDay = "query_day"
        case addBlock = "add_block"
        case editBlock = "edit_block"
        case deleteBlock = "delete_block"
        case toggleDone = "toggle_done"
        case reorder
        case daySwipe = "day_swipe"
        case reminderSync = "reminder_sync"
        case cloudKitInit = "cloudkit_init"

        var signpostName: StaticString {
            switch self {
            case .launch:
                "launch"
            case .migration:
                "migration"
            case .queryDay:
                "query_day"
            case .addBlock:
                "add_block"
            case .editBlock:
                "edit_block"
            case .deleteBlock:
                "delete_block"
            case .toggleDone:
                "toggle_done"
            case .reorder:
                "reorder"
            case .daySwipe:
                "day_swipe"
            case .reminderSync:
                "reminder_sync"
            case .cloudKitInit:
                "cloudkit_init"
            }
        }
    }

    static let shared = PerformanceTracer()

    private let signpostLog: OSLog
    private let logger: Logger
    private let clock = ContinuousClock()

    private init() {
        let subsystem = Bundle.main.bundleIdentifier ?? "DailyOS"
        signpostLog = OSLog(subsystem: subsystem, category: "performance")
        logger = Logger(subsystem: subsystem, category: "performance")
    }

    @discardableResult
    func begin(_ event: Event, message: String = "") -> TraceHandle {
        let handle = TraceHandle(
            id: OSSignpostID(log: signpostLog),
            event: event,
            startedAt: clock.now,
            message: message
        )

        os_signpost(.begin, log: signpostLog, name: event.signpostName, signpostID: handle.id, "%{public}s", message)
        logger.debug("BEGIN \(event.rawValue, privacy: .public): \(message, privacy: .public)")
        return handle
    }

    func end(_ handle: TraceHandle, message: String = "") {
        os_signpost(.end, log: signpostLog, name: handle.event.signpostName, signpostID: handle.id, "%{public}s", message)
        logger.debug("END \(handle.event.rawValue, privacy: .public): \(message, privacy: .public)")
    }

    @discardableResult
    func measure<T>(_ event: Event, message: String = "", _ block: () throws -> T) rethrows -> T {
        let handle = begin(event, message: message)
        defer { end(handle) }
        return try block()
    }

    @discardableResult
    func measureAsync<T>(_ event: Event, message: String = "", _ block: () async throws -> T) async rethrows -> T {
        let handle = begin(event, message: message)
        defer { end(handle) }
        return try await block()
    }

    func recordError(_ error: Error, event: Event, message: String = "") {
        logger.error("ERROR \(event.rawValue, privacy: .public): \(message, privacy: .public) | \(String(describing: error), privacy: .public)")
    }

    func recordInfo(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}
