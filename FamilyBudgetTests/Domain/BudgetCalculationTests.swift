import XCTest
@testable import FamilyBudget

final class BudgetCalculationTests: XCTestCase {
    func testMemberAndFamilyCreditLoad() throws {
        let firstMemberId = UUID()
        let secondMemberId = UUID()
        let month = try YearMonth(year: 2026, month: 1)
        let firstCredit = try makeCredit(memberId: firstMemberId, amount: 200, month: month)
        let secondCredit = try makeCredit(memberId: secondMemberId, amount: 300, month: month)
        let payments = try BudgetCalculator.generatePayments(for: firstCredit)
            + BudgetCalculator.generatePayments(for: secondCredit)

        let memberLoad = try BudgetCalculator.memberCreditLoad(
            memberId: firstMemberId,
            month: month,
            credits: [firstCredit, secondCredit],
            payments: payments,
            currencyCode: "USD"
        )
        let familyLoad = try BudgetCalculator.familyCreditLoad(
            month: month,
            payments: payments,
            currencyCode: "USD"
        )

        XCTAssertEqual(memberLoad, Money(amount: 200, currencyCode: "USD"))
        XCTAssertEqual(familyLoad, Money(amount: 500, currencyCode: "USD"))
    }

    func testRemainingMoneyCanBeNegative() throws {
        let remaining = try BudgetCalculator.remaining(
            income: Money(amount: 300, currencyCode: "USD"),
            creditLoad: Money(amount: 500, currencyCode: "USD")
        )

        XCTAssertEqual(remaining, Money(amount: -200, currencyCode: "USD"))
    }

    func testCreditLoadPercentage() throws {
        let percentage = try BudgetCalculator.creditLoadPercentage(
            income: Money(amount: 1_000, currencyCode: "USD"),
            creditLoad: Money(amount: 250, currencyCode: "USD")
        )

        XCTAssertEqual(percentage, .value(25))
    }

    func testCreditLoadPercentageWithZeroIncomeIsNotApplicable() throws {
        let percentage = try BudgetCalculator.creditLoadPercentage(
            income: Money(amount: 0, currencyCode: "USD"),
            creditLoad: Money(amount: 250, currencyCode: "USD")
        )

        XCTAssertEqual(percentage, .notApplicable)
    }

    private func makeCredit(memberId: UUID, amount: Decimal, month: YearMonth) throws -> Credit {
        try Credit(
            memberId: memberId,
            title: "Credit",
            totalAmount: Money(amount: amount, currencyCode: "USD"),
            downPayment: Money(amount: 0, currencyCode: "USD"),
            monthlyPayment: Money(amount: amount, currencyCode: "USD"),
            termMonths: 1,
            startMonth: month,
            paymentDay: 10
        )
    }
}
