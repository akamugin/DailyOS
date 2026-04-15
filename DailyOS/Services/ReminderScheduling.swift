import Foundation
import UserNotifications

protocol ReminderScheduling {
    func requestAuthorizationIfNeeded() async -> Bool
    func remove(ids: [UUID]) async
    func sync(blocks: [ScheduleBlock]) async
}

struct PreviewReminderScheduler: ReminderScheduling {
    func requestAuthorizationIfNeeded() async -> Bool { true }
    func remove(ids: [UUID]) async { }
    func sync(blocks: [ScheduleBlock]) async { }
}

actor UserNotificationReminderScheduler: ReminderScheduling {
    private struct ReminderFingerprint: Equatable {
        let activity: String
        let startTime: Date
        let reminderLeadMinutes: Int
        let isDone: Bool
    }

    private let center: UNUserNotificationCenter
    private let tracer: PerformanceTracer
    private var scheduledFingerprints: [UUID: ReminderFingerprint] = [:]

    init(
        center: UNUserNotificationCenter = .current(),
        tracer: PerformanceTracer = .shared
    ) {
        self.center = center
        self.tracer = tracer
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func remove(ids: [UUID]) async {
        guard !ids.isEmpty else { return }

        let identifiers = ids.map(reminderID(for:))
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)

        for id in ids {
            scheduledFingerprints.removeValue(forKey: id)
        }
    }

    func sync(blocks: [ScheduleBlock]) async {
        let trace = tracer.begin(.reminderSync, message: "blocks=\(blocks.count)")
        defer { tracer.end(trace) }

        let isAuthorized = await requestAuthorizationIfNeeded()
        guard isAuthorized else {
            scheduledFingerprints.removeAll()
            return
        }

        let now = Date()
        let desired = Dictionary(uniqueKeysWithValues: blocks.compactMap { block -> (UUID, ScheduleBlock)? in
            guard !block.isDone, reminderDate(for: block) > now else { return nil }
            return (block.id, block)
        })

        let pendingIDs = Set(await pendingReminderIDs())
        let desiredIDs = Set(desired.keys)
        let existingIDs = Set(scheduledFingerprints.keys)
        let removedIDs = existingIDs.union(pendingIDs).subtracting(desiredIDs)

        if !removedIDs.isEmpty {
            await remove(ids: Array(removedIDs))
        }

        for (id, block) in desired {
            let fingerprint = fingerprint(for: block)
            if scheduledFingerprints[id] != fingerprint {
                if scheduledFingerprints[id] != nil {
                    await remove(ids: [id])
                }
                await schedule(block)
                scheduledFingerprints[id] = fingerprint
            }
        }
    }

    private func schedule(_ block: ScheduleBlock) async {
        let content = UNMutableNotificationContent()
        content.title = block.activity
        content.body = "Starts at \(ScheduleFormatters.timeString(block.startTime))"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate(for: block)
        )

        let request = UNNotificationRequest(
            identifier: reminderID(for: block.id),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        )

        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume()
            }
        }
    }

    private func reminderID(for id: UUID) -> String {
        "dailyos.schedule.\(id.uuidString)"
    }

    private nonisolated func parseReminderID(_ rawIdentifier: String) -> UUID? {
        let prefix = "dailyos.schedule."
        guard rawIdentifier.hasPrefix(prefix) else { return nil }
        let uuidString = String(rawIdentifier.dropFirst(prefix.count))
        return UUID(uuidString: uuidString)
    }

    private func pendingReminderIDs() async -> [UUID] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let ids = requests.compactMap { request in
                    self.parseReminderID(request.identifier)
                }
                continuation.resume(returning: ids)
            }
        }
    }

    private func fingerprint(for block: ScheduleBlock) -> ReminderFingerprint {
        ReminderFingerprint(
            activity: block.activity,
            startTime: block.startTime,
            reminderLeadMinutes: block.reminderLeadMinutes,
            isDone: block.isDone
        )
    }

    private func reminderDate(for block: ScheduleBlock) -> Date {
        Calendar.current.date(
            byAdding: .minute,
            value: -block.reminderLeadMinutes,
            to: block.startTime
        ) ?? block.startTime
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
