import Foundation

@MainActor
final class MigrationService {
    private let repository: ScheduleBlockRepository
    private let defaults: UserDefaults
    private let tracer: PerformanceTracer

    init(
        repository: ScheduleBlockRepository,
        defaults: UserDefaults = .standard,
        tracer: PerformanceTracer = .shared
    ) {
        self.repository = repository
        self.defaults = defaults
        self.tracer = tracer
    }

    @discardableResult
    func migrateIfNeeded() throws -> Bool {
        try tracer.measure(.migration, message: "legacy-to-swiftdata") {
            if defaults.bool(forKey: StorageKeys.cloudMigrationComplete) {
                return false
            }

            var didMigrate = false
            let currentBlocks = try repository.fetchAllBlocks()

            if currentBlocks.isEmpty, let legacyBlocks = loadLegacyBlocks(), !legacyBlocks.isEmpty {
                try repository.upsert(blocks: legacyBlocks)
                try repository.saveChanges()
                didMigrate = true
            }

            defaults.set(true, forKey: StorageKeys.cloudMigrationComplete)
            defaults.removeObject(forKey: StorageKeys.legacyBlocks)
            return didMigrate
        }
    }

    private func loadLegacyBlocks() -> [ScheduleBlock]? {
        guard let data = defaults.data(forKey: StorageKeys.legacyBlocks) else {
            return nil
        }

        return try? JSONDecoder().decode([ScheduleBlock].self, from: data)
    }
}
