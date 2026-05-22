import SwiftUI
import SwiftData

@main
struct FamilyBudgetApp: App {
    private let modelContainer = {
        do {
            return try PersistenceContainerFactory.makeModelContainer()
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
