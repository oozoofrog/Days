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
    private(set) var snapshot = VisitSnapshot(moments: [])
    private(set) var presentation: JourneyPresentation = .loading
    var noteDraft = ""

    init(repository: any VisitLocalRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    var canSaveNote: Bool {
        guard case .timeline = presentation else { return false }
        return noteDraft.normalizedVisitWord != snapshot.currentNote.normalizedVisitWord
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

        if newPhase == .background, canSaveNote {
            saveCurrentNote()
            return
        }

        if presentation == .loading {
            refreshPresentation()
        }
    }

    func reload() {
        refreshPresentation()
    }

    func saveCurrentNote() {
        guard let currentVisitID = snapshot.currentVisitID else { return }

        do {
            try repository.updateNote(for: currentVisitID, note: noteDraft)
            logger.debug("Saved visit note")
            refreshPresentation()
        } catch {
            logger.error("Failed to save visit note: \(error.localizedDescription, privacy: .public)")
            presentation = .error("한 단어를 남기지 못했어요. 잠시 후 다시 시도해 주세요.")
        }
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

    private func refreshPresentation() {
        do {
            snapshot = VisitSnapshot(moments: try repository.fetchMoments())
            presentation = TimelineComposer.makePresentation(from: snapshot)
            noteDraft = snapshot.currentNote
        } catch {
            logger.error("Failed to load visits: \(error.localizedDescription, privacy: .public)")
            presentation = .error("기록을 불러오지 못했어요.")
        }
    }
}
