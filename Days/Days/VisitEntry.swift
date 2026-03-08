import Foundation
import SwiftData

@Model
final class VisitEntry {
    @Attribute(.unique) var visitID: UUID
    var visitedAt: Date
    var note: String

    init(visitID: UUID = UUID(), visitedAt: Date, note: String = "") {
        self.visitID = visitID
        self.visitedAt = visitedAt
        self.note = note
    }
}

struct VisitMoment: Identifiable, Equatable, Sendable {
    let id: UUID
    let visitedAt: Date
    let note: String
}

enum ReturnWindow: String, CaseIterable, Sendable {
    case dawn
    case morning
    case afternoon
    case evening
    case night

    var title: String {
        switch self {
        case .dawn: "새벽"
        case .morning: "아침"
        case .afternoon: "낮"
        case .evening: "저녁"
        case .night: "밤"
        }
    }

    var insight: String {
        "당신은 주로 \(title)에 돌아옵니다."
    }

    static func from(hour: Int) -> ReturnWindow {
        switch hour {
        case 5..<8: .dawn
        case 8..<12: .morning
        case 12..<17: .afternoon
        case 17..<21: .evening
        default: .night
        }
    }
}

struct VisitSnapshot: Equatable, Sendable {
    let moments: [VisitMoment]

    init(moments: [VisitMoment]) {
        self.moments = moments.sorted { $0.visitedAt < $1.visitedAt }
    }

    var isEmpty: Bool { moments.isEmpty }
    var visitCount: Int { moments.count }
    var currentVisitID: UUID? { moments.last?.id }
    var currentNote: String { moments.last?.note ?? "" }
    var firstOpenedAt: Date? { moments.first?.visitedAt }
    var lastOpenedAt: Date? { moments.last?.visitedAt }
    var previousOpenedAt: Date? { moments.dropLast().last?.visitedAt }

    var totalElapsed: TimeInterval? {
        guard let firstOpenedAt, let lastOpenedAt else { return nil }
        return max(0, lastOpenedAt.timeIntervalSince(firstOpenedAt))
    }

    var intervals: [TimeInterval] {
        zip(moments, moments.dropFirst()).map { previous, current in
            max(0, current.visitedAt.timeIntervalSince(previous.visitedAt))
        }
    }

    var latestInterval: TimeInterval? { intervals.last }
    var longestInterval: TimeInterval? { intervals.max() }

    var averageInterval: TimeInterval? {
        guard intervals.isEmpty == false else { return nil }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    var savedWords: [String] {
        var seen = Set<String>()
        return moments.reversed().compactMap { moment in
            let word = moment.note.normalizedVisitWord
            guard word.isEmpty == false, seen.insert(word).inserted else {
                return nil
            }
            return word
        }
    }

    func dominantReturnWindow(calendar: Calendar = .current) -> ReturnWindow? {
        guard moments.count > 1 else { return nil }

        let windows = moments.dropFirst().map {
            ReturnWindow.from(hour: calendar.component(.hour, from: $0.visitedAt))
        }

        return windows.max { left, right in
            windows.filter { $0 == left }.count < windows.filter { $0 == right }.count
        }
    }
}

extension VisitEntry {
    var moment: VisitMoment {
        VisitMoment(id: visitID, visitedAt: visitedAt, note: note.normalizedVisitWord)
    }
}

extension String {
    var normalizedVisitWord: String {
        let collapsed = split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return String(collapsed.prefix(18))
    }
}
