import Foundation
import SwiftUI
import Testing
@testable import Days

@MainActor
struct DaysTests {

    @Test func firstActivationCreatesQuietPresentation() {
        let clock = StubClock([
            makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        ])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)

        #expect(repository.moments.count == 1)
        guard case .quiet = viewModel.presentation else {
            Issue.record("첫 활성화는 조용한 첫 방문 상태여야 합니다.")
            return
        }
    }

    @Test func backgroundReturnCreatesTimelinePresentation() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)

        #expect(repository.moments.count == 2)
        #expect(viewModel.snapshot.visitCount == 2)
        #expect(viewModel.snapshot.latestInterval == secondVisit.timeIntervalSince(firstVisit))

        guard case .timeline(let presentation) = viewModel.presentation else {
            Issue.record("두 번째 방문부터 타임라인 화면이어야 합니다.")
            return
        }

        #expect(presentation.visitCountLine == "당신은 2번째로 돌아왔습니다.")
    }

    @Test func inactivePhaseDoesNotCreateDuplicateVisit() {
        let clock = StubClock([
            makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
            makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 1)
        ])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.inactive)
        viewModel.handleScenePhaseChange(.active)

        #expect(repository.moments.count == 1)
    }

    @Test func saveCurrentWordUpdatesLatestVisit() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)

        viewModel.noteDraft = "여행"
        viewModel.saveCurrentNote()

        #expect(repository.moments.last?.note == "여행")
        #expect(viewModel.snapshot.savedWords.first == "여행")
    }
}

@MainActor
private final class InMemoryVisitRepository: VisitLocalRepository {
    var moments: [VisitMoment] = []

    func fetchMoments() throws -> [VisitMoment] {
        moments.sorted { $0.visitedAt < $1.visitedAt }
    }

    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment {
        let moment = VisitMoment(id: UUID(), visitedAt: date, note: "")
        moments.append(moment)
        return moment
    }

    func updateNote(for visitID: UUID, note: String) throws {
        guard let index = moments.firstIndex(where: { $0.id == visitID }) else { return }
        moments[index] = VisitMoment(id: moments[index].id, visitedAt: moments[index].visitedAt, note: note.normalizedVisitWord)
    }
}

private final class StubClock {
    private var dates: [Date]

    init(_ dates: [Date]) {
        self.dates = dates
    }

    func next() -> Date {
        if dates.count > 1 {
            return dates.removeFirst()
        }
        return dates[0]
    }
}

private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
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
