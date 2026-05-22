import Foundation

protocol FamilyMemberRepositoryProtocol {
    func fetchAll() throws -> [FamilyMember]
    func fetch(id: UUID) throws -> FamilyMember?
    func save(_ member: FamilyMember) throws
    func delete(id: UUID) throws
}

protocol FamilyMemberRelatedDataHandling {
    func hasRelatedData(memberId: UUID) throws -> Bool
    func deleteRelatedData(memberId: UUID) throws
}

struct FamilyMemberListItem: Equatable, Identifiable {
    let id: UUID
    let name: String
}

enum FamilyMemberDeletePlan: Equatable {
    case canDelete
    case requiresDestructiveConfirmation
}

enum FamilyMemberUseCaseError: Error, Equatable {
    case emptyName
    case memberNotFound
    case destructiveConfirmationRequired
}

final class FamilyMemberUseCase {
    private let repository: FamilyMemberRepositoryProtocol
    private let relatedDataHandler: FamilyMemberRelatedDataHandling

    init(repository: FamilyMemberRepositoryProtocol, relatedDataHandler: FamilyMemberRelatedDataHandling) {
        self.repository = repository
        self.relatedDataHandler = relatedDataHandler
    }

    func listMembers() throws -> [FamilyMemberListItem] {
        try repository.fetchAll()
            .sorted { $0.createdAt < $1.createdAt }
            .map { FamilyMemberListItem(id: $0.id, name: $0.name) }
    }

    func createMember(name: String) throws -> [FamilyMemberListItem] {
        let normalizedName = try normalize(name)
        try repository.save(FamilyMember(name: normalizedName))
        return try listMembers()
    }

    func updateMember(id: UUID, name: String) throws -> [FamilyMemberListItem] {
        let normalizedName = try normalize(name)
        guard var member = try repository.fetch(id: id) else {
            throw FamilyMemberUseCaseError.memberNotFound
        }

        member.name = normalizedName
        member.updatedAt = Date()
        try repository.save(member)
        return try listMembers()
    }

    func deletePlan(memberId: UUID) throws -> FamilyMemberDeletePlan {
        try relatedDataHandler.hasRelatedData(memberId: memberId) ? .requiresDestructiveConfirmation : .canDelete
    }

    func deleteMember(id: UUID, confirmedDestructiveDelete: Bool) throws -> [FamilyMemberListItem] {
        guard try repository.fetch(id: id) != nil else {
            throw FamilyMemberUseCaseError.memberNotFound
        }

        let hasRelatedData = try relatedDataHandler.hasRelatedData(memberId: id)
        if hasRelatedData && !confirmedDestructiveDelete {
            throw FamilyMemberUseCaseError.destructiveConfirmationRequired
        }

        if hasRelatedData {
            try relatedDataHandler.deleteRelatedData(memberId: id)
        }

        try repository.delete(id: id)
        return try listMembers()
    }

    private func normalize(_ name: String) throws -> String {
        do {
            return try FamilyMemberNameValidator.normalizedName(name)
        } catch FamilyMemberValidationError.emptyName {
            throw FamilyMemberUseCaseError.emptyName
        }
    }
}
