import SwiftData
import SwiftUI

@main
@MainActor
struct DaysApp: App {
    private let sharedModelContainer: ModelContainer
    @State private var viewModel: DaysTimelineViewModel

    init() {
        let schema = Schema([VisitEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.sharedModelContainer = container
            let repository = SwiftDataVisitLocalRepository(container: container)
            let model = DaysTimelineViewModel(repository: repository)
            model.handleScenePhaseChange(.active)
            _viewModel = State(initialValue: model)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
