import SwiftData
import XCTest
@testable import FamilyBudget

final class RepositoryPersistenceTests: XCTestCase {
    func testDefaultSettingsAreInitializedOnce() throws {
        let context = try makeContext()
        let repository = AppSettingsRepository(context: context)

        let first = try repository.loadOrCreateDefault()
        let second = try repository.loadOrCreateDefault()

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.currencyCode, AppSettingsRepository.defaultCurrencyCode)
        XCTAssertFalse(first.biometricLockEnabled)
        XCTAssertFalse(first.notificationsEnabled)
    }

    func testFamilyMemberCreateUpdateDelete() throws {
        let context = try makeContext()
        let repository = FamilyMemberRepository(context: context)
        let memberId = UUID()
        let createdAt = Date(timeIntervalSince1970: 100)
        let updatedAt = Date(timeIntervalSince1970: 200)

        try repository.save(FamilyMember(id: memberId, name: "Alex", createdAt: createdAt, updatedAt: createdAt))
        XCTAssertEqual(try repository.fetch(id: memberId)?.name, "Alex")

        try repository.save(FamilyMember(id: memberId, name: "Alex Updated", createdAt: createdAt, updatedAt: updatedAt))
        XCTAssertEqual(try repository.fetch(id: memberId)?.name, "Alex Updated")

        try repository.delete(id: memberId)
        XCTAssertNil(try repository.fetch(id: memberId))
    }

    func testIncomeAndOverridePersistence() throws {
        let context = try makeContext()
        let repository = IncomeRepository(context: context)
        let memberId = UUID()
        let income = try Income(
            memberId: memberId,
            category: .salary,
            amount: Money(amount: 1000, currencyCode: "USD"),
            recurrence: .monthly,
            startMonth: try YearMonth(year: 2026, month: 1)
        )
        let override = IncomeOverride(
            incomeId: income.id,
            month: try YearMonth(year: 2026, month: 2),
            amount: Money(amount: 1200, currencyCode: "USD")
        )

        try repository.save(income)
        try repository.save(override)

        XCTAssertEqual(try repository.fetchIncomes(memberId: memberId), [income])
        XCTAssertEqual(try repository.fetchOverrides(incomeId: income.id), [override])
    }

    func testCreditAndPaymentPersistence() throws {
        let context = try makeContext()
        let repository = CreditRepository(context: context)
        let memberId = UUID()
        let month = try YearMonth(year: 2026, month: 1)
        let credit = try Credit(
            memberId: memberId,
            title: "Phone",
            totalAmount: Money(amount: 900, currencyCode: "USD"),
            downPayment: Money(amount: 0, currencyCode: "USD"),
            monthlyPayment: Money(amount: 300, currencyCode: "USD"),
            termMonths: 3,
            startMonth: month,
            paymentDay: 15
        )
        let payment = try BudgetCalculator.generatePayments(for: credit)[0]

        try repository.save(credit)
        try repository.save(payment)

        XCTAssertEqual(try repository.fetchCredits(memberId: memberId), [credit])
        XCTAssertEqual(try repository.fetchPayments(creditId: credit.id, month: month), [payment])
    }

    private func makeContext() throws -> ModelContext {
        let container = try PersistenceContainerFactory.makeModelContainer(inMemory: true)
        return ModelContext(container)
    }
}
