import Foundation

struct QuietPresentation: Equatable {
    let title: String
    let message: String
}

struct StatCard: Identifiable, Equatable {
    let title: String
    let value: String

    var id: String { title }
}

struct LatestRecordedEntryPresentation: Equatable {
    let word: String
    let reflection: String
}

struct TimelinePresentation: Equatable {
    let headline: String
    let subtitle: String
    let visitCountLine: String
    let translatedLine: String?
    let rhythmLine: String?
    let statCards: [StatCard]
    let savedWords: [String]
    let latestRecordedEntry: LatestRecordedEntryPresentation?
    let backgroundLevel: Int
}

enum JourneyPresentation: Equatable {
    case loading
    case quiet(QuietPresentation)
    case timeline(TimelinePresentation)
    case error(String)
}

enum TimelineComposer {
    static func makePresentation(from snapshot: VisitSnapshot, calendar: Calendar = .current) -> JourneyPresentation {
        guard snapshot.isEmpty == false else {
            return .loading
        }

        if snapshot.visitCount == 1 {
            return .quiet(
                QuietPresentation(
                    title: "이 앱은 두 번째부터 시작됩니다.",
                    message: "지금은 첫 시간을 조용히 기억하고 있어요. 다시 돌아오면, 바깥에서 흐른 시간이 말을 걸 거예요."
                )
            )
        }

        let totalElapsed = formattedInterval(snapshot.totalElapsed ?? 0)
        let latestInterval = formattedInterval(snapshot.latestInterval ?? 0)
        let statCards = buildStatCards(from: snapshot, calendar: calendar)

        return .timeline(
            TimelinePresentation(
                headline: "처음 만난 뒤 \(totalElapsed)이 지났습니다.",
                subtitle: "지난 방문 이후 \(latestInterval) 만에 돌아왔어요.",
                visitCountLine: "당신은 \(snapshot.visitCount)번째로 돌아왔습니다.",
                translatedLine: translatedLine(for: snapshot),
                rhythmLine: rhythmLine(for: snapshot, calendar: calendar),
                statCards: statCards,
                savedWords: snapshot.savedWords,
                latestRecordedEntry: snapshot.latestWrittenMoment.map {
                    LatestRecordedEntryPresentation(word: $0.word, reflection: $0.reflection)
                },
                backgroundLevel: backgroundLevel(for: snapshot)
            )
        )
    }

    static func formattedInterval(_ interval: TimeInterval) -> String {
        guard interval >= 60 else {
            return "잠시"
        }

        let totalMinutes = Int(interval / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)일") }
        if hours > 0, parts.count < 2 { parts.append("\(hours)시간") }
        if minutes > 0, parts.count < 2 { parts.append("\(minutes)분") }

        return parts.isEmpty ? "잠시" : parts.joined(separator: " ")
    }

    private static func buildStatCards(from snapshot: VisitSnapshot, calendar: Calendar) -> [StatCard] {
        var cards: [StatCard] = []

        if let latestInterval = snapshot.latestInterval {
            cards.append(StatCard(title: "지난 방문 이후", value: formattedInterval(latestInterval)))
        }

        if let longestInterval = snapshot.longestInterval {
            cards.append(StatCard(title: "가장 긴 공백", value: formattedInterval(longestInterval)))
        }

        if let averageInterval = snapshot.averageInterval {
            cards.append(StatCard(title: "평균 간격", value: formattedInterval(averageInterval)))
        }

        if let returnWindow = snapshot.dominantReturnWindow(calendar: calendar) {
            cards.append(StatCard(title: "주로 돌아오는 시간", value: returnWindow.title))
        }

        return cards
    }

    private static func translatedLine(for snapshot: VisitSnapshot) -> String? {
        guard let totalElapsed = snapshot.totalElapsed else { return nil }

        let days = Int(totalElapsed / 86_400)
        if days >= 1 {
            return "해가 \(max(days, 1))번 졌습니다."
        }

        let hours = Int(totalElapsed / 3_600)
        if hours >= 6 {
            return "조용한 시간이 \(hours)시간 흘렀습니다."
        }

        return "아직 짧은 시간이지만, 분명한 사이가 생겼어요."
    }

    private static func rhythmLine(for snapshot: VisitSnapshot, calendar: Calendar) -> String? {
        guard let latestInterval = snapshot.latestInterval else { return nil }

        let previousIntervals = Array(snapshot.intervals.dropLast())
        if previousIntervals.isEmpty == false {
            let baseline = previousIntervals.reduce(0, +) / Double(previousIntervals.count)
            if latestInterval > baseline * 1.2 {
                return "이번에는 지난번보다 조금 더 늦게 돌아왔네요."
            }
            if latestInterval < baseline * 0.8 {
                return "이번에는 조금 더 일찍 돌아왔네요."
            }
            return "이번에도 비슷한 리듬으로 돌아왔어요."
        }

        return snapshot.dominantReturnWindow(calendar: calendar)?.insight
    }

    private static func backgroundLevel(for snapshot: VisitSnapshot) -> Int {
        let visitGrowth = min(snapshot.visitCount * 2, 18)
        let gapGrowth = Int((snapshot.longestInterval ?? 0) / 86_400)
        return max(3, min(visitGrowth + gapGrowth, 22))
    }
}
