import XCTest
@testable import FamilyBudget

final class MoneyTests: XCTestCase {
    func testAddingMoneyWithSameCurrency() throws {
        let result = try Money(amount: 100, currencyCode: "USD")
            .adding(Money(amount: 25, currencyCode: "USD"))

        XCTAssertEqual(result, Money(amount: 125, currencyCode: "USD"))
    }

    func testSubtractingMoneyWithSameCurrency() throws {
        let result = try Money(amount: 100, currencyCode: "USD")
            .subtracting(Money(amount: 125, currencyCode: "USD"))

        XCTAssertEqual(result, Money(amount: -25, currencyCode: "USD"))
    }

    func testAddingMoneyWithDifferentCurrencyThrows() {
        XCTAssertThrowsError(
            try Money(amount: 100, currencyCode: "USD")
                .adding(Money(amount: 25, currencyCode: "EUR"))
        )
    }
}
