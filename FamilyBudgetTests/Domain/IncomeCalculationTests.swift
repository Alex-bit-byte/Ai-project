import XCTest
@testable import FamilyBudget

final class IncomeCalculationTests: XCTestCase {
    func testRecurringIncomeAppliesWithinPeriod() throws {
        let memberId = UUID()
        let income = try Income(
            memberId: memberId,
            category: .salary,
            amount: Money(amount: 1_000, currencyCode: "USD"),
            recurrence: .monthly,
            startMonth: try YearMonth(year: 2026, month: 1),
            endMonth: try YearMonth(year: 2026, month: 3)
        )

        XCTAssertNotNil(BudgetCalculator.incomeAmount(for: income, in: try YearMonth(year: 2026, month: 2), overrides: []))
        XCTAssertNil(BudgetCalculator.incomeAmount(for: income, in: try YearMonth(year: 2026, month: 4), overrides: []))
    }

    func testOneTimeIncomeAppliesOnlyToStartMonth() throws {
        let income = try Income(
            memberId: UUID(),
            category: .bonus,
            amount: Money(amount: 500, currencyCode: "USD"),
            recurrence: .oneTime,
            startMonth: try YearMonth(year: 2026, month: 5)
        )

        XCTAssertEqual(
            BudgetCalculator.incomeAmount(for: income, in: try YearMonth(year: 2026, month: 5), overrides: []),
            Money(amount: 500, currencyCode: "USD")
        )
        XCTAssertNil(BudgetCalculator.incomeAmount(for: income, in: try YearMonth(year: 2026, month: 6), overrides: []))
    }

    func testRecurringIncomeOverrideReplacesAmountForMonth() throws {
        let income = try Income(
            memberId: UUID(),
            category: .salary,
            amount: Money(amount: 1_000, currencyCode: "USD"),
            recurrence: .monthly,
            startMonth: try YearMonth(year: 2026, month: 1)
        )
        let month = try YearMonth(year: 2026, month: 2)
        let override = IncomeOverride(
            incomeId: income.id,
            month: month,
            amount: Money(amount: 1_200, currencyCode: "USD")
        )

        XCTAssertEqual(
            BudgetCalculator.incomeAmount(for: income, in: month, overrides: [override]),
            Money(amount: 1_200, currencyCode: "USD")
        )
    }

    func testMemberAndFamilyIncome() throws {
        let firstMemberId = UUID()
        let secondMemberId = UUID()
        let month = try YearMonth(year: 2026, month: 1)
        let incomes = [
            try Income(memberId: firstMemberId, category: .salary, amount: Money(amount: 1_000, currencyCode: "USD"), recurrence: .monthly, startMonth: month),
            try Income(memberId: secondMemberId, category: .salary, amount: Money(amount: 700, currencyCode: "USD"), recurrence: .monthly, startMonth: month)
        ]

        let memberIncome = try BudgetCalculator.memberIncome(
            memberId: firstMemberId,
            month: month,
            incomes: incomes,
            overrides: [],
            currencyCode: "USD"
        )
        let familyIncome = try BudgetCalculator.familyIncome(
            month: month,
            incomes: incomes,
            overrides: [],
            currencyCode: "USD"
        )

        XCTAssertEqual(memberIncome, Money(amount: 1_000, currencyCode: "USD"))
        XCTAssertEqual(familyIncome, Money(amount: 1_700, currencyCode: "USD"))
    }
}
