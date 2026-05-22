import XCTest
@testable import FamilyBudget

final class FamilyMemberUseCaseTests: XCTestCase {
    func testCreateUpdateDeleteMember() throws {
        let repository = InMemoryFamilyMemberRepository()
        let useCase = FamilyMemberUseCase(repository: repository, relatedDataHandler: InMemoryRelatedDataHandler(hasData: false))

        let created = try useCase.createMember(name: " Alex ")
        XCTAssertEqual(created.map(\.name), ["Alex"])

        let updated = try useCase.updateMember(id: created[0].id, name: "Alex Updated")
        XCTAssertEqual(updated.map(\.name), ["Alex Updated"])

        let remaining = try useCase.deleteMember(id: created[0].id, confirmedDestructiveDelete: false)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testDuplicateNamesAreAllowed() throws {
        let repository = InMemoryFamilyMemberRepository()
        let useCase = FamilyMemberUseCase(repository: repository, relatedDataHandler: InMemoryRelatedDataHandler(hasData: false))

        _ = try useCase.createMember(name: "Alex")
        let items = try useCase.createMember(name: "Alex")

        XCTAssertEqual(items.map(\.name), ["Alex", "Alex"])
    }

    func testDeleteWithRelatedDataRequiresConfirmation() throws {
        let repository = InMemoryFamilyMemberRepository()
        let relatedDataHandler = InMemoryRelatedDataHandler(hasData: true)
        let useCase = FamilyMemberUseCase(repository: repository, relatedDataHandler: relatedDataHandler)
        let item = try useCase.createMember(name: "Alex")[0]

        XCTAssertEqual(try useCase.deletePlan(memberId: item.id), .requiresDestructiveConfirmation)
        XCTAssertThrowsError(try useCase.deleteMember(id: item.id, confirmedDestructiveDelete: false)) { error in
            XCTAssertEqual(error as? FamilyMemberUseCaseError, .destructiveConfirmationRequired)
        }

        _ = try useCase.deleteMember(id: item.id, confirmedDestructiveDelete: true)
        XCTAssertTrue(relatedDataHandler.didDeleteRelatedData)
    }
}

private final class InMemoryFamilyMemberRepository: FamilyMemberRepositoryProtocol {
    private var members: [FamilyMember] = []

    func fetchAll() throws -> [FamilyMember] {
        members
    }

    func fetch(id: UUID) throws -> FamilyMember? {
        members.first { $0.id == id }
    }

    func save(_ member: FamilyMember) throws {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
        } else {
            members.append(member)
        }
    }

    func delete(id: UUID) throws {
        members.removeAll { $0.id == id }
    }
}

private final class InMemoryRelatedDataHandler: FamilyMemberRelatedDataHandling {
    private let hasData: Bool
    private(set) var didDeleteRelatedData = false

    init(hasData: Bool) {
        self.hasData = hasData
    }

    func hasRelatedData(memberId: UUID) throws -> Bool {
        hasData
    }

    func deleteRelatedData(memberId: UUID) throws {
        didDeleteRelatedData = true
    }
}
