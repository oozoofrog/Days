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

    @Test func inactiveThenActiveOnFirstLaunchCreatesQuietPresentation() {
        let clock = StubClock([
            makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        ])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.inactive)
        viewModel.handleScenePhaseChange(.active)

        #expect(repository.moments.count == 1)
        guard case .quiet = viewModel.presentation else {
            Issue.record("첫 실행이 inactive에서 시작해도 첫 활성화 시 조용한 첫 방문 상태여야 합니다.")
            return
        }
    }

    @Test func inactiveThenActiveOnColdLaunchWithExistingVisitRecordsReturnVisit() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([secondVisit])
        let repository = InMemoryVisitRepository()
        repository.moments = [VisitMoment(id: UUID(), visitedAt: firstVisit, note: "")]
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.inactive)
        viewModel.handleScenePhaseChange(.active)

        #expect(repository.moments.count == 2)
        #expect(viewModel.snapshot.latestInterval == secondVisit.timeIntervalSince(firstVisit))
        guard case .timeline = viewModel.presentation else {
            Issue.record("기존 방문 기록이 있을 때 cold launch 후 첫 활성화는 재방문으로 기록되어야 합니다.")
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

    @Test func backgroundPhaseAutosavesLatestWord() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)
        viewModel.noteDraft = "겨울"

        viewModel.handleScenePhaseChange(.background)

        #expect(repository.moments.last?.note == "겨울")
    }

    @Test func timelineComposerBuildsTranslatedAndRhythmLines() {
        let firstVisit = VisitMoment(id: UUID(), visitedAt: makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0), note: "")
        let secondVisit = VisitMoment(id: UUID(), visitedAt: makeDate(year: 2026, month: 3, day: 9, hour: 9, minute: 0), note: "")
        let thirdVisit = VisitMoment(id: UUID(), visitedAt: makeDate(year: 2026, month: 3, day: 11, hour: 12, minute: 0), note: "여행")
        let snapshot = VisitSnapshot(moments: [firstVisit, secondVisit, thirdVisit])

        guard case .timeline(let presentation) = TimelineComposer.makePresentation(from: snapshot) else {
            Issue.record("세 번 이상 방문한 경우 타임라인 화면이어야 합니다.")
            return
        }

        #expect(presentation.translatedLine == "해가 3번 졌습니다.")
        #expect(presentation.rhythmLine == "이번에는 지난번보다 조금 더 늦게 돌아왔네요.")
        #expect(presentation.savedWords == ["여행"])
    }

    @Test func visitDateCorrectionMakesMomentsMonotonic() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let earlierVisit = makeDate(year: 2026, month: 3, day: 8, hour: 8, minute: 30)
        let laterVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 30)

        let correctedDate = SwiftDataVisitLocalRepository.effectiveVisitDate(for: earlierVisit, lastDate: firstVisit)
        let untouchedDate = SwiftDataVisitLocalRepository.effectiveVisitDate(for: laterVisit, lastDate: firstVisit)
        let initialDate = SwiftDataVisitLocalRepository.effectiveVisitDate(for: firstVisit, lastDate: nil)

        #expect(correctedDate == firstVisit.addingTimeInterval(1))
        #expect(untouchedDate == laterVisit)
        #expect(initialDate == firstVisit)
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
