import Foundation
import SwiftData

@MainActor
protocol ScheduleBlockRepository {
    func fetchBlocks(for day: Date) throws -> [ScheduleBlock]
    func fetchAllBlocks() throws -> [ScheduleBlock]
    func upsert(block: ScheduleBlock) throws
    func upsert(blocks: [ScheduleBlock]) throws
    func delete(id: UUID) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataScheduleBlockRepository: ScheduleBlockRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchBlocks(for day: Date) throws -> [ScheduleBlock] {
        let dayStart = Calendar.current.startOfDay(for: day)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        let descriptor = FetchDescriptor<ScheduleBlockEntity>(
            predicate: #Predicate { entity in
                entity.day >= dayStart && entity.day < dayEnd
            },
            sortBy: [
                SortDescriptor(\ScheduleBlockEntity.sortOrder, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor).map { $0.asBlock() }
    }

    func fetchAllBlocks() throws -> [ScheduleBlock] {
        let descriptor = FetchDescriptor<ScheduleBlockEntity>(
            sortBy: [
                SortDescriptor(\ScheduleBlockEntity.day, order: .forward),
                SortDescriptor(\ScheduleBlockEntity.sortOrder, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor).map { $0.asBlock() }
    }

    func upsert(block: ScheduleBlock) throws {
        if let existing = try entity(for: block.id) {
            existing.apply(from: block)
        } else {
            modelContext.insert(ScheduleBlockEntity(from: block))
        }
    }

    func upsert(blocks: [ScheduleBlock]) throws {
        guard !blocks.isEmpty else { return }

        let ids = blocks.map(\.id)
        let existingEntities = try entities(for: ids)
        var existingByID = Dictionary(uniqueKeysWithValues: existingEntities.map { ($0.id, $0) })

        for block in blocks {
            if let entity = existingByID.removeValue(forKey: block.id) {
                entity.apply(from: block)
            } else {
                modelContext.insert(ScheduleBlockEntity(from: block))
            }
        }
    }

    func delete(id: UUID) throws {
        guard let existing = try entity(for: id) else { return }
        modelContext.delete(existing)
    }

    func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    private func entity(for id: UUID) throws -> ScheduleBlockEntity? {
        let descriptor = FetchDescriptor<ScheduleBlockEntity>(
            predicate: #Predicate { entity in
                entity.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    private func entities(for ids: [UUID]) throws -> [ScheduleBlockEntity] {
        guard !ids.isEmpty else { return [] }

        let descriptor = FetchDescriptor<ScheduleBlockEntity>(
            predicate: #Predicate { entity in
                ids.contains(entity.id)
            }
        )

        return try modelContext.fetch(descriptor)
    }
}
