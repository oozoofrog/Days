import Foundation
import SwiftData

enum DaysLaunchScenario: String {
    case live
    case quiet
    case timeline
    case error
}

struct DaysLaunchConfiguration {
    let scenario: DaysLaunchScenario
    let usesInMemoryStore: Bool

    init(processInfo: ProcessInfo = .processInfo) {
        let arguments = processInfo.arguments
        let rawScenario = arguments.value(after: "-days-scenario") ?? DaysLaunchScenario.live.rawValue
        self.scenario = DaysLaunchScenario(rawValue: rawScenario) ?? .live
        self.usesInMemoryStore = arguments.contains("-days-ui-testing") || arguments.contains("-days-use-in-memory-store") || scenario != .live
    }

    var disablesAutomaticSceneHandling: Bool {
        scenario != .live
    }

    @MainActor
    func makeRepository(container: ModelContainer) throws -> any VisitLocalRepository {
        switch scenario {
        case .live:
            return SwiftDataVisitLocalRepository(container: container)
        case .quiet, .timeline:
            try seedVisitsIfNeeded(into: container.mainContext)
            return SwiftDataVisitLocalRepository(container: container)
        case .error:
            return FailingVisitRepository()
        }
    }

    @MainActor
    private func seedVisitsIfNeeded(into context: ModelContext) throws {
        guard seedVisits.isEmpty == false else { return }

        for visit in seedVisits {
            context.insert(
                VisitEntry(
                    visitedAt: visit.visitedAt,
                    note: visit.note,
                    reflection: visit.reflection
                )
            )
        }
        try context.save()
    }

    private var seedVisits: [SeedVisit] {
        switch scenario {
        case .live, .error:
            return []
        case .quiet:
            return [
                SeedVisit(
                    visitedAt: Self.makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
                    note: "",
                    reflection: ""
                )
            ]
        case .timeline:
            return [
                SeedVisit(
                    visitedAt: Self.makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
                    note: "",
                    reflection: ""
                ),
                SeedVisit(
                    visitedAt: Self.makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30),
                    note: "여행",
                    reflection: "낯선 공기를 오래 맡고 돌아온 날이었어요."
                ),
                SeedVisit(
                    visitedAt: Self.makeDate(year: 2026, month: 3, day: 11, hour: 20, minute: 0),
                    note: "",
                    reflection: ""
                )
            ]
        }
    }

    private static func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return components.date ?? .distantPast
    }
}

private struct SeedVisit {
    let visitedAt: Date
    let note: String
    let reflection: String
}

@MainActor
private struct FailingVisitRepository: VisitLocalRepository {
    func fetchMoments() throws -> [VisitMoment] {
        throw LaunchScenarioError.simulatedFailure
    }

    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment {
        throw LaunchScenarioError.simulatedFailure
    }

    func updateVisitContent(for visitID: UUID, word: String, reflection: String) throws {
        throw LaunchScenarioError.simulatedFailure
    }
}

private enum LaunchScenarioError: LocalizedError {
    case simulatedFailure

    var errorDescription: String? {
        "UI 테스트용 오류 시나리오입니다."
    }
}

private extension [String] {
    func value(after flag: String) -> String? {
        guard let index = firstIndex(of: flag), indices.contains(index + 1) else {
            return nil
        }
        return self[index + 1]
    }
}
