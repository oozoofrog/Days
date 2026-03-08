import Foundation
import OSLog
import SwiftData

@MainActor
protocol VisitLocalRepository {
    func fetchMoments() throws -> [VisitMoment]
    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment
    func updateNote(for visitID: UUID, note: String) throws
}

@MainActor
final class SwiftDataVisitLocalRepository: VisitLocalRepository {
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.oozoofrog.ios.Days", category: "VisitLocalRepository")

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchMoments() throws -> [VisitMoment] {
        let descriptor = FetchDescriptor<VisitEntry>(sortBy: [SortDescriptor(\.visitedAt)])
        return try context.fetch(descriptor).map(\.moment)
    }

    @discardableResult
    func recordVisit(at date: Date) throws -> VisitMoment {
        let lastDate = try fetchMoments().last?.visitedAt
        let effectiveDate: Date

        if let lastDate, date <= lastDate {
            effectiveDate = lastDate.addingTimeInterval(1)
        } else {
            effectiveDate = date
        }

        let entry = VisitEntry(visitedAt: effectiveDate)
        context.insert(entry)
        try context.save()
        logger.debug("Recorded visit at \(effectiveDate.formatted(date: .omitted, time: .standard))")
        return entry.moment
    }

    func updateNote(for visitID: UUID, note: String) throws {
        let predicate = #Predicate<VisitEntry> { entry in
            entry.visitID == visitID
        }
        var descriptor = FetchDescriptor<VisitEntry>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let entry = try context.fetch(descriptor).first else {
            logger.error("Missing visit entry for note update")
            return
        }

        entry.note = note.normalizedVisitWord
        try context.save()
    }
}
