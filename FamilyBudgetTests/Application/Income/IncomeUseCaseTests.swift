import XCTest
@testable import FamilyBudget

final class IncomeUseCaseTests: XCTestCase {
    func testCreateUpdateDeleteIncome() throws {
        let member = FamilyMember(name: "Alex")
        let incomeRepository = InMemoryIncomeRepository()
        let useCase = IncomeUseCase(
            incomeRepository: incomeRepository,
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )
        let startMonth = try YearMonth(year: 2026, month: 1)

        let created = try useCase.createIncome(
            IncomeDraft(
                memberId: member.id,
                category: .salary,
                title: " Salary ",
                amount: 1_000,
                currencyCode: "USD",
                recurrence: .monthly,
                startMonth: startMonth,
                endMonth: nil
            )
        )

        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created[0].title, "Salary")
        XCTAssertEqual(created[0].amount, Money(amount: 1_000, currencyCode: "USD"))

        let updated = try useCase.updateIncome(
            id: created[0].id,
            draft: IncomeDraft(
                memberId: member.id,
                category: .bonus,
                title: "",
                amount: 1_200,
                currencyCode: "USD",
                recurrence: .oneTime,
                startMonth: startMonth,
                endMonth: nil
            )
        )

        XCTAssertEqual(updated[0].category, .bonus)
        XCTAssertNil(updated[0].title)
        XCTAssertEqual(updated[0].amount, Money(amount: 1_200, currencyCode: "USD"))

        let remaining = try useCase.deleteIncome(id: created[0].id)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testCreateIncomeRequiresMemberAndPositiveAmount() throws {
        let member = FamilyMember(name: "Alex")
        let useCase = IncomeUseCase(
            incomeRepository: InMemoryIncomeRepository(),
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )
        let month = try YearMonth(year: 2026, month: 1)

        XCTAssertThrowsError(
            try useCase.createIncome(
                IncomeDraft(memberId: nil, category: .salary, title: "", amount: 1_000, currencyCode: "USD", recurrence: .monthly, startMonth: month, endMonth: nil)
            )
        ) { error in
            XCTAssertEqual(error as? IncomeUseCaseError, .memberRequired)
        }

        XCTAssertThrowsError(
            try useCase.createIncome(
                IncomeDraft(memberId: member.id, category: .salary, title: "", amount: 0, currencyCode: "USD", recurrence: .monthly, startMonth: month, endMonth: nil)
            )
        ) { error in
            XCTAssertEqual(error as? IncomeUseCaseError, .invalidAmount)
        }
    }

    func testCreateIncomeRejectsInvalidPeriod() throws {
        let member = FamilyMember(name: "Alex")
        let useCase = IncomeUseCase(
            incomeRepository: InMemoryIncomeRepository(),
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )

        XCTAssertThrowsError(
            try useCase.createIncome(
                IncomeDraft(
                    memberId: member.id,
                    category: .salary,
                    title: "",
                    amount: 1_000,
                    currencyCode: "USD",
                    recurrence: .monthly,
                    startMonth: try YearMonth(year: 2026, month: 3),
                    endMonth: try YearMonth(year: 2026, month: 2)
                )
            )
        ) { error in
            XCTAssertEqual(error as? IncomeUseCaseError, .invalidPeriod)
        }
    }

    func testOverrideLifecycleAndValidation() throws {
        let member = FamilyMember(name: "Alex")
        let incomeRepository = InMemoryIncomeRepository()
        let useCase = IncomeUseCase(
            incomeRepository: incomeRepository,
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )
        let startMonth = try YearMonth(year: 2026, month: 1)
        let income = try useCase.createIncome(
            IncomeDraft(memberId: member.id, category: .salary, title: "", amount: 1_000, currencyCode: "USD", recurrence: .monthly, startMonth: startMonth, endMonth: try YearMonth(year: 2026, month: 3))
        )[0]

        let overrides = try useCase.createOverride(
            IncomeOverrideDraft(
                incomeId: income.id,
                month: try YearMonth(year: 2026, month: 2),
                amount: 1_200,
                currencyCode: "USD",
                note: " Bonus month "
            )
        )

        XCTAssertEqual(overrides.count, 1)
        XCTAssertEqual(overrides[0].amount, Money(amount: 1_200, currencyCode: "USD"))
        XCTAssertEqual(overrides[0].note, "Bonus month")

        let updated = try useCase.updateOverride(
            id: overrides[0].id,
            draft: IncomeOverrideDraft(incomeId: income.id, month: try YearMonth(year: 2026, month: 2), amount: 1_300, currencyCode: "USD", note: "")
        )
        XCTAssertEqual(updated[0].amount, Money(amount: 1_300, currencyCode: "USD"))
        XCTAssertNil(updated[0].note)

        XCTAssertThrowsError(
            try useCase.createOverride(
                IncomeOverrideDraft(incomeId: income.id, month: try YearMonth(year: 2026, month: 4), amount: 1_100, currencyCode: "USD", note: "")
            )
        ) { error in
            XCTAssertEqual(error as? IncomeUseCaseError, .overrideOutsideIncomePeriod)
        }

        XCTAssertTrue(try useCase.deleteOverride(id: overrides[0].id, incomeId: income.id).isEmpty)
    }

    func testDeletingIncomeDeletesOverrides() throws {
        let member = FamilyMember(name: "Alex")
        let incomeRepository = InMemoryIncomeRepository()
        let useCase = IncomeUseCase(
            incomeRepository: incomeRepository,
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )
        let month = try YearMonth(year: 2026, month: 1)
        let income = try useCase.createIncome(
            IncomeDraft(memberId: member.id, category: .salary, title: "", amount: 1_000, currencyCode: "USD", recurrence: .monthly, startMonth: month, endMonth: nil)
        )[0]
        _ = try useCase.createOverride(
            IncomeOverrideDraft(incomeId: income.id, month: month, amount: 1_200, currencyCode: "USD", note: "")
        )

        _ = try useCase.deleteIncome(id: income.id)

        XCTAssertTrue(try incomeRepository.fetchOverrides(incomeId: income.id).isEmpty)
    }

    func testUpdatingIncomeRemovesOverridesOutsideNewPeriod() throws {
        let member = FamilyMember(name: "Alex")
        let incomeRepository = InMemoryIncomeRepository()
        let useCase = IncomeUseCase(
            incomeRepository: incomeRepository,
            memberRepository: InMemoryIncomeMemberRepository(members: [member])
        )
        let income = try useCase.createIncome(
            IncomeDraft(
                memberId: member.id,
                category: .salary,
                title: "",
                amount: 1_000,
                currencyCode: "USD",
                recurrence: .monthly,
                startMonth: try YearMonth(year: 2026, month: 1),
                endMonth: try YearMonth(year: 2026, month: 3)
            )
        )[0]
        _ = try useCase.createOverride(
            IncomeOverrideDraft(incomeId: income.id, month: try YearMonth(year: 2026, month: 3), amount: 1_200, currencyCode: "USD", note: "")
        )

        _ = try useCase.updateIncome(
            id: income.id,
            draft: IncomeDraft(
                memberId: member.id,
                category: .salary,
                title: "",
                amount: 1_000,
                currencyCode: "USD",
                recurrence: .monthly,
                startMonth: try YearMonth(year: 2026, month: 1),
                endMonth: try YearMonth(year: 2026, month: 2)
            )
        )

        XCTAssertTrue(try incomeRepository.fetchOverrides(incomeId: income.id).isEmpty)
    }
}

private final class InMemoryIncomeRepository: IncomeRepositoryProtocol {
    private var incomes: [Income] = []
    private var overrides: [IncomeOverride] = []

    func fetchIncomes(memberId: UUID?) throws -> [Income] {
        incomes.filter { memberId == nil || $0.memberId == memberId }
    }

    func fetchIncome(id: UUID) throws -> Income? {
        incomes.first { $0.id == id }
    }

    func save(_ income: Income) throws {
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            incomes[index] = income
        } else {
            incomes.append(income)
        }
    }

    func deleteIncome(id: UUID) throws {
        incomes.removeAll { $0.id == id }
        overrides.removeAll { $0.incomeId == id }
    }

    func fetchOverrides(incomeId: UUID?) throws -> [IncomeOverride] {
        overrides.filter { incomeId == nil || $0.incomeId == incomeId }
    }

    func save(_ override: IncomeOverride) throws {
        if let index = overrides.firstIndex(where: { $0.id == override.id }) {
            overrides[index] = override
        } else {
            overrides.append(override)
        }
    }

    func deleteOverride(id: UUID) throws {
        overrides.removeAll { $0.id == id }
    }
}

private final class InMemoryIncomeMemberRepository: FamilyMemberRepositoryProtocol {
    private var members: [FamilyMember]

    init(members: [FamilyMember]) {
        self.members = members
    }

    func fetchAll() throws -> [FamilyMember] {
        members
    }

    func fetch(id: UUID) throws -> FamilyMember? {
        members.first { $0.id == id }
    }

    func save(_ member: FamilyMember) throws {
        members.append(member)
    }

    func delete(id: UUID) throws {
        members.removeAll { $0.id == id }
    }
}
