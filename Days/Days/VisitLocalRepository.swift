import Foundation
import OSLog
import SwiftData

@MainActor
protocol VisitLocalRepository {
    func fetchMoments() throws -> [VisitMoment]
    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment
    func updateVisitContent(for visitID: UUID, word: String, reflection: String) throws
}

@MainActor
final class SwiftDataVisitLocalRepository: VisitLocalRepository {
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.oozoofrog.ios.Days", category: "VisitLocalRepository")

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    nonisolated static func effectiveVisitDate(for proposedDate: Date, lastDate: Date?) -> Date {
        guard let lastDate else {
            return proposedDate
        }

        if proposedDate <= lastDate {
            return lastDate.addingTimeInterval(1)
        }

        return proposedDate
    }

    func fetchMoments() throws -> [VisitMoment] {
        let descriptor = FetchDescriptor<VisitEntry>(sortBy: [SortDescriptor(\.visitedAt)])
        return try context.fetch(descriptor).map(\.moment)
    }

    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment {
        let lastDate = try fetchMoments().last?.visitedAt
        let effectiveDate = Self.effectiveVisitDate(for: date, lastDate: lastDate)

        let entry = VisitEntry(visitedAt: effectiveDate)
        context.insert(entry)
        try context.save()
        logger.debug("Recorded visit at \(effectiveDate.formatted(date: .omitted, time: .standard))")
        return entry.moment
    }

    func updateVisitContent(for visitID: UUID, word: String, reflection: String) throws {
        let predicate = #Predicate<VisitEntry> { entry in
            entry.visitID == visitID
        }
        var descriptor = FetchDescriptor<VisitEntry>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let entry = try context.fetch(descriptor).first else {
            logger.error("Missing visit entry for content update")
            return
        }

        entry.note = word.normalizedVisitWord
        entry.reflection = reflection.normalizedVisitReflection
        try context.save()
    }
}
