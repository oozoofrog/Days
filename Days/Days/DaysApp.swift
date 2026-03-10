import SwiftData
import SwiftUI

@main
@MainActor
struct DaysApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let sharedModelContainer: ModelContainer
    private let launchConfiguration: DaysLaunchConfiguration
    @State private var viewModel: DaysTimelineViewModel
    @State private var hasLoadedStaticScenario = false

    init() {
        let launchConfiguration = DaysLaunchConfiguration()
        self.launchConfiguration = launchConfiguration

        let schema = Schema([VisitEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: launchConfiguration.usesInMemoryStore
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.sharedModelContainer = container
            let repository = try launchConfiguration.makeRepository(container: container)
            _viewModel = State(initialValue: DaysTimelineViewModel(repository: repository))
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
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            if launchConfiguration.disablesAutomaticSceneHandling {
                guard hasLoadedStaticScenario == false else { return }
                hasLoadedStaticScenario = true
                viewModel.reload()
                return
            }

            viewModel.handleScenePhaseChange(newPhase)
        }
    }
}
