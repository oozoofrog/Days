import Foundation
import Observation
import OSLog
import SwiftUI

@MainActor
@Observable
final class DaysTimelineViewModel {
    private let repository: any VisitLocalRepository
    private let now: () -> Date
    private let logger = Logger(subsystem: "com.oozoofrog.ios.Days", category: "DaysTimelineViewModel")

    private var hasSeenActivePhase = false
    private var hasEnteredBackgroundSinceLastVisit = false
    private var isReflectionComposerDismissed = false
    private(set) var snapshot = VisitSnapshot(moments: [])
    private(set) var presentation: JourneyPresentation = .loading
    var wordDraft = ""
    var reflectionDraft = ""

    init(repository: any VisitLocalRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    var canSaveWord: Bool {
        guard case .timeline = presentation else { return false }
        return wordDraft.normalizedVisitWord != snapshot.currentWord.normalizedVisitWord
    }

    var canSaveReflection: Bool {
        guard case .timeline = presentation else { return false }
        return reflectionDraft.normalizedVisitReflection != snapshot.currentReflection.normalizedVisitReflection
    }

    var showsReflectionComposer: Bool {
        guard case .timeline = presentation else { return false }

        let hasWord = wordDraft.normalizedVisitWord.isEmpty == false
        let hasReflection = reflectionDraft.normalizedVisitReflection.isEmpty == false
        return hasWord && (isReflectionComposerDismissed == false || hasReflection)
    }

    var canStartReflection: Bool {
        guard case .timeline = presentation else { return false }
        return wordDraft.normalizedVisitWord.isEmpty == false && showsReflectionComposer == false
    }

    var backgroundLevel: Int {
        switch presentation {
        case .loading:
            return 2
        case .quiet:
            return 4
        case .timeline(let timeline):
            return timeline.backgroundLevel
        case .error:
            return 2
        }
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        defer {
            if newPhase == .active {
                hasSeenActivePhase = true
            }
            if newPhase == .background {
                hasEnteredBackgroundSinceLastVisit = true
            }
        }

        if shouldRecordVisit(for: newPhase) {
            hasEnteredBackgroundSinceLastVisit = false
            recordVisit()
            return
        }

        if newPhase == .background, canSaveWord || canSaveReflection {
            saveCurrentVisit(errorMessage: "기록을 남기지 못했어요. 잠시 후 다시 시도해 주세요.")
            return
        }

        if presentation == .loading {
            refreshPresentation()
        }
    }

    func reload() {
        refreshPresentation()
    }

    func saveCurrentWord() {
        isReflectionComposerDismissed = false
        saveCurrentVisit(errorMessage: "한 단어를 남기지 못했어요. 잠시 후 다시 시도해 주세요.")
    }

    func saveCurrentReflection() {
        saveCurrentVisit(errorMessage: "한 줄 이유를 남기지 못했어요. 잠시 후 다시 시도해 주세요.")
    }

    func skipReflectionEntry() {
        reflectionDraft = snapshot.currentReflection
        isReflectionComposerDismissed = true
    }

    func beginReflectionEntry() {
        isReflectionComposerDismissed = false
    }

    private func shouldRecordVisit(for newPhase: ScenePhase) -> Bool {
        guard newPhase == .active else {
            return false
        }

        if hasSeenActivePhase == false {
            return true
        }

        return hasEnteredBackgroundSinceLastVisit
    }

    private func recordVisit() {
        do {
            _ = try repository.recordVisit(at: now())
            refreshPresentation()
        } catch {
            logger.error("Failed to record visit: \(error.localizedDescription, privacy: .public)")
            presentation = .error("시간을 기억하는 데 실패했어요. 앱을 다시 열어 주세요.")
        }
    }

    private func saveCurrentVisit(errorMessage: String) {
        guard let currentVisitID = snapshot.currentVisitID else { return }

        do {
            try repository.updateVisitContent(
                for: currentVisitID,
                word: wordDraft,
                reflection: reflectionDraft
            )
            logger.debug("Saved visit content")
            refreshPresentation()
        } catch {
            logger.error("Failed to save visit content: \(error.localizedDescription, privacy: .public)")
            presentation = .error(errorMessage)
        }
    }

    private func refreshPresentation() {
        do {
            let previousVisitID = snapshot.currentVisitID
            snapshot = VisitSnapshot(moments: try repository.fetchMoments())
            if snapshot.currentVisitID != previousVisitID {
                isReflectionComposerDismissed = false
            }
            presentation = TimelineComposer.makePresentation(from: snapshot)
            wordDraft = snapshot.currentWord
            reflectionDraft = snapshot.currentReflection
        } catch {
            logger.error("Failed to load visits: \(error.localizedDescription, privacy: .public)")
            presentation = .error("기록을 불러오지 못했어요.")
        }
    }
}
