import Foundation
import SwiftData

final class FamilyMemberRepository: FamilyMemberRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [FamilyMember] {
        try context.fetch(FetchDescriptor<FamilyMemberModel>())
            .sorted { $0.createdAt < $1.createdAt }
            .map(PersistenceMapper.domain)
    }

    func fetch(id: UUID) throws -> FamilyMember? {
        try context.fetch(FetchDescriptor<FamilyMemberModel>())
            .first { $0.id == id }
            .map(PersistenceMapper.domain)
    }

    func save(_ member: FamilyMember) throws {
        if let existing = try model(id: member.id) {
            existing.name = member.name
            existing.updatedAt = member.updatedAt
        } else {
            context.insert(PersistenceMapper.model(from: member))
        }

        try context.save()
    }

    func delete(id: UUID) throws {
        if let existing = try model(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    private func model(id: UUID) throws -> FamilyMemberModel? {
        try context.fetch(FetchDescriptor<FamilyMemberModel>())
            .first { $0.id == id }
    }
}
