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
        repository.moments = [VisitMoment(id: UUID(), visitedAt: firstVisit, word: "", reflection: "")]
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

    @Test func saveCurrentWordUpdatesLatestVisitAndOpensReflectionComposer() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)

        viewModel.wordDraft = "여행"
        viewModel.saveCurrentWord()

        #expect(repository.moments.last?.word == "여행")
        #expect(viewModel.snapshot.savedWords.first == "여행")
        #expect(viewModel.showsReflectionComposer)
    }

    @Test func saveCurrentReflectionUpdatesLatestVisit() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)
        viewModel.wordDraft = "산책"
        viewModel.saveCurrentWord()

        viewModel.reflectionDraft = "해 질 무렵 골목 공기가 오래 남았어요."
        viewModel.saveCurrentReflection()

        #expect(repository.moments.last?.reflection == "해 질 무렵 골목 공기가 오래 남았어요.")
        #expect(viewModel.snapshot.latestWrittenMoment?.reflection == "해 질 무렵 골목 공기가 오래 남았어요.")
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
        viewModel.wordDraft = "겨울"

        viewModel.handleScenePhaseChange(.background)

        #expect(repository.moments.last?.word == "겨울")
    }

    @Test func backgroundPhaseAutosavesLatestReflection() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)
        viewModel.wordDraft = "노을"
        viewModel.saveCurrentWord()
        viewModel.reflectionDraft = "생각보다 오래 붉은 하늘을 보고 있었어요."

        viewModel.handleScenePhaseChange(.background)

        #expect(repository.moments.last?.reflection == "생각보다 오래 붉은 하늘을 보고 있었어요.")
    }

    @Test func skipReflectionHidesComposerAndAllowsReentry() {
        let firstVisit = makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0)
        let secondVisit = makeDate(year: 2026, month: 3, day: 9, hour: 12, minute: 30)
        let clock = StubClock([firstVisit, secondVisit])
        let repository = InMemoryVisitRepository()
        let viewModel = DaysTimelineViewModel(repository: repository, now: clock.next)

        viewModel.handleScenePhaseChange(.active)
        viewModel.handleScenePhaseChange(.background)
        viewModel.handleScenePhaseChange(.active)
        viewModel.wordDraft = "소풍"
        viewModel.saveCurrentWord()

        viewModel.skipReflectionEntry()

        #expect(viewModel.showsReflectionComposer == false)
        #expect(viewModel.canStartReflection)

        viewModel.beginReflectionEntry()

        #expect(viewModel.showsReflectionComposer)
    }

    @Test func timelineComposerBuildsTranslatedRhythmLinesAndLatestPreview() {
        let firstVisit = VisitMoment(
            id: UUID(),
            visitedAt: makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
            word: "",
            reflection: ""
        )
        let secondVisit = VisitMoment(
            id: UUID(),
            visitedAt: makeDate(year: 2026, month: 3, day: 9, hour: 9, minute: 0),
            word: "",
            reflection: ""
        )
        let thirdVisit = VisitMoment(
            id: UUID(),
            visitedAt: makeDate(year: 2026, month: 3, day: 11, hour: 12, minute: 0),
            word: "여행",
            reflection: "낯선 공기를 오래 맡고 돌아온 날이었어요."
        )
        let snapshot = VisitSnapshot(moments: [firstVisit, secondVisit, thirdVisit])

        guard case .timeline(let presentation) = TimelineComposer.makePresentation(from: snapshot) else {
            Issue.record("세 번 이상 방문한 경우 타임라인 화면이어야 합니다.")
            return
        }

        #expect(presentation.translatedLine == "해가 3번 졌습니다.")
        #expect(presentation.rhythmLine == "이번에는 지난번보다 조금 더 늦게 돌아왔네요.")
        #expect(presentation.savedWords == ["여행"])
        #expect(presentation.latestRecordedEntry == LatestRecordedEntryPresentation(word: "여행", reflection: "낯선 공기를 오래 맡고 돌아온 날이었어요."))
    }

    @Test func shareCardExporterProducesPNGData() throws {
        let presentation = TimelinePresentation(
            headline: "처음 만난 뒤 3일 11시간이 지났습니다.",
            subtitle: "지난 방문 이후 2일 7시간 만에 돌아왔어요.",
            visitCountLine: "당신은 3번째로 돌아왔습니다.",
            translatedLine: "해가 3번 졌습니다.",
            rhythmLine: "이번에는 지난번보다 조금 더 늦게 돌아왔네요.",
            statCards: [
                StatCard(title: "지난 방문 이후", value: "2일 7시간"),
                StatCard(title: "가장 긴 공백", value: "2일 7시간")
            ],
            savedWords: ["노을", "여행"],
            latestRecordedEntry: LatestRecordedEntryPresentation(
                word: "노을",
                reflection: "생각보다 오래 붉은 하늘을 보고 있었어요."
            ),
            backgroundLevel: 10
        )

        let data = try ShareCardExporter.pngData(for: presentation)

        #expect(data.isEmpty == false)
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
        let moment = VisitMoment(id: UUID(), visitedAt: date, word: "", reflection: "")
        moments.append(moment)
        return moment
    }

    func updateVisitContent(for visitID: UUID, word: String, reflection: String) throws {
        guard let index = moments.firstIndex(where: { $0.id == visitID }) else { return }
        moments[index] = VisitMoment(
            id: moments[index].id,
            visitedAt: moments[index].visitedAt,
            word: word.normalizedVisitWord,
            reflection: reflection.normalizedVisitReflection
        )
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
