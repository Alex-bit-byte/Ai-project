import XCTest
@testable import FamilyBudget

final class PersistenceMapperTests: XCTestCase {
    func testMoneySerializesWithoutLosingDecimalText() throws {
        let money = try PersistenceMapper.money(amountString: "1234.56", currencyCode: "USD")

        XCTAssertEqual(money, Money(amount: 1234.56, currencyCode: "USD"))
        XCTAssertEqual(PersistenceMapper.amountString(from: money.amount), "1234.56")
    }

    func testInvalidMoneyStringThrowsDiagnosticError() {
        XCTAssertThrowsError(try PersistenceMapper.money(amountString: "abc", currencyCode: "USD")) { error in
            XCTAssertEqual(error as? PersistenceMappingError, .invalidDecimal("abc"))
        }
    }

    func testIncomeRoundTripMapsValueObjectsAndEnums() throws {
        let income = try Income(
            memberId: UUID(),
            category: .salary,
            title: "Base salary",
            amount: Money(amount: 2500.25, currencyCode: "USD"),
            recurrence: .monthly,
            startMonth: try YearMonth(year: 2026, month: 1),
            endMonth: try YearMonth(year: 2026, month: 12)
        )

        let roundTrip = try PersistenceMapper.domain(from: PersistenceMapper.model(from: income))

        XCTAssertEqual(roundTrip, income)
    }

    func testCreditPaymentRoundTripMapsStatusAndMonth() throws {
        let payment = CreditPayment(
            creditId: UUID(),
            month: try YearMonth(year: 2026, month: 2),
            dueDate: Date(timeIntervalSince1970: 100),
            amount: Money(amount: 300, currencyCode: "USD"),
            status: .paid,
            paidAt: Date(timeIntervalSince1970: 120)
        )

        let roundTrip = try PersistenceMapper.domain(from: PersistenceMapper.model(from: payment))

        XCTAssertEqual(roundTrip, payment)
    }

    func testInvalidEnumRawValueThrowsDiagnosticError() throws {
        let model = IncomeModel(
            id: UUID(),
            memberId: UUID(),
            categoryRawValue: "unexpected",
            title: nil,
            amountString: "100",
            currencyCode: "USD",
            recurrenceRawValue: "monthly",
            startYear: 2026,
            startMonth: 1,
            endYear: nil,
            endMonth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertThrowsError(try PersistenceMapper.domain(from: model)) { error in
            XCTAssertEqual(error as? PersistenceMappingError, .invalidIncomeCategory("unexpected"))
        }
    }
}
