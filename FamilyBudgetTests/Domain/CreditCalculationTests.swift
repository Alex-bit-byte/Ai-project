import XCTest
@testable import FamilyBudget

final class CreditCalculationTests: XCTestCase {
    func testCreditScheduleGenerationClampsPaymentDayToEndOfMonth() throws {
        let credit = try Credit(
            memberId: UUID(),
            title: "Installment",
            totalAmount: Money(amount: 1_000, currencyCode: "USD"),
            downPayment: Money(amount: 100, currencyCode: "USD"),
            monthlyPayment: Money(amount: 300, currencyCode: "USD"),
            termMonths: 3,
            startMonth: try YearMonth(year: 2026, month: 1),
            paymentDay: 31
        )

        let payments = try BudgetCalculator.generatePayments(for: credit)

        XCTAssertEqual(payments.map(\.month), [
            try YearMonth(year: 2026, month: 1),
            try YearMonth(year: 2026, month: 2),
            try YearMonth(year: 2026, month: 3)
        ])
        XCTAssertEqual(Calendar(identifier: .gregorian).component(.day, from: payments[1].dueDate), 28)
    }

    func testInvalidCreditTermThrows() throws {
        XCTAssertThrowsError(
            try Credit(
                memberId: UUID(),
                title: "Invalid",
                totalAmount: Money(amount: 1_000, currencyCode: "USD"),
                downPayment: Money(amount: 0, currencyCode: "USD"),
                monthlyPayment: Money(amount: 100, currencyCode: "USD"),
                termMonths: 0,
                startMonth: try YearMonth(year: 2026, month: 1),
                paymentDay: 10
            )
        )
    }

    func testCalculatedMonthlyPaymentUsesSimpleFormula() throws {
        let payment = try BudgetCalculator.calculatedMonthlyPayment(
            totalAmount: Money(amount: 1_000, currencyCode: "USD"),
            downPayment: Money(amount: 100, currencyCode: "USD"),
            termMonths: 3
        )

        XCTAssertEqual(payment, Money(amount: 300, currencyCode: "USD"))
    }

    func testCreditRejectsNegativeAmountsAndDownPaymentAboveTotal() throws {
        XCTAssertThrowsError(
            try Credit(
                memberId: UUID(),
                title: "Invalid",
                totalAmount: Money(amount: -1_000, currencyCode: "USD"),
                downPayment: Money(amount: 0, currencyCode: "USD"),
                monthlyPayment: Money(amount: 100, currencyCode: "USD"),
                termMonths: 1,
                startMonth: try YearMonth(year: 2026, month: 1),
                paymentDay: 10
            )
        ) { error in
            XCTAssertEqual(error as? DomainValidationError, .negativeMoneyAmount)
        }

        XCTAssertThrowsError(
            try Credit(
                memberId: UUID(),
                title: "Invalid",
                totalAmount: Money(amount: 1_000, currencyCode: "USD"),
                downPayment: Money(amount: 1_200, currencyCode: "USD"),
                monthlyPayment: Money(amount: 100, currencyCode: "USD"),
                termMonths: 1,
                startMonth: try YearMonth(year: 2026, month: 1),
                paymentDay: 10
            )
        ) { error in
            XCTAssertEqual(error as? DomainValidationError, .downPaymentExceedsTotalAmount)
        }
    }

    func testPaymentOverdueDetection() throws {
        let payment = CreditPayment(
            creditId: UUID(),
            month: try YearMonth(year: 2026, month: 1),
            dueDate: Date(timeIntervalSince1970: 100),
            amount: Money(amount: 100, currencyCode: "USD"),
            status: .scheduled
        )

        XCTAssertTrue(payment.isOverdue(asOf: Date(timeIntervalSince1970: 200)))
        XCTAssertFalse(payment.isOverdue(asOf: Date(timeIntervalSince1970: 50)))
    }

    func testPaidPaymentIsNotOverdue() throws {
        let payment = CreditPayment(
            creditId: UUID(),
            month: try YearMonth(year: 2026, month: 1),
            dueDate: Date(timeIntervalSince1970: 100),
            amount: Money(amount: 100, currencyCode: "USD"),
            status: .paid,
            paidAt: Date(timeIntervalSince1970: 90)
        )

        XCTAssertFalse(payment.isOverdue(asOf: Date(timeIntervalSince1970: 200)))
    }
}
