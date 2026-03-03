import SwiftData
import SwiftUI

@main
struct DailyOSApp: App {
    private let sharedModelContainer: ModelContainer
    @StateObject private var viewModel: ScheduleViewModel

    init() {
        let tracer = PerformanceTracer.shared
        let trace = tracer.begin(.cloudKitInit, message: "initialize-model-container")

        let modelContainer = DailyOSApp.makeModelContainer(tracer: tracer)
        tracer.end(trace, message: "model-container-ready")
        sharedModelContainer = modelContainer

        let repository = SwiftDataScheduleBlockRepository(modelContext: modelContainer.mainContext)
        let reminderScheduler = UserNotificationReminderScheduler()
        let migrationService = MigrationService(repository: repository, tracer: tracer)

        _viewModel = StateObject(
            wrappedValue: ScheduleViewModel(
                repository: repository,
                reminderScheduler: reminderScheduler,
                migrationService: migrationService,
                tracer: tracer
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeModelContainer(tracer: PerformanceTracer) -> ModelContainer {
        let schema = Schema([
            ScheduleBlockEntity.self
        ])

        do {
            let cloudConfiguration = ModelConfiguration(
                "DailyOS",
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch {
            tracer.recordError(error, event: .cloudKitInit, message: "CloudKit init failed. Falling back to local store")

            do {
                let fallbackConfiguration = ModelConfiguration("DailyOSLocalFallback")
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                tracer.recordError(error, event: .cloudKitInit, message: "Fallback model container init failed")
                fatalError("Failed to initialize model container: \(error)")
            }
        }
    }
}
