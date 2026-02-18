//
//  DailyOSApp.swift
//  DailyOS
//
//  Created by Stella Lee on 2/7/26.
//

import SwiftUI
import SwiftData

@main
struct DailyOSApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ScheduleBlockEntity.self
        ])

        do {
            let configuration = ModelConfiguration(
                "DailyOS",
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fall back to a local store so the app still launches if CloudKit is unavailable.
            let nsError = error as NSError
            print("CloudKit container init failed: \(error)")
            print("CloudKit NSError domain=\(nsError.domain) code=\(nsError.code) userInfo=\(nsError.userInfo)")
            print("Falling back to local store.")
            do {
                let fallbackConfiguration = ModelConfiguration("DailyOSLocalFallback")
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                let fallbackNSError = error as NSError
                print("Fallback container init failed: \(error)")
                print("Fallback NSError domain=\(fallbackNSError.domain) code=\(fallbackNSError.code) userInfo=\(fallbackNSError.userInfo)")
                fatalError("Failed to initialize fallback model container: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
