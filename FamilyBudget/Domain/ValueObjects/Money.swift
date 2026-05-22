import Foundation

struct Money: Equatable {
    let amount: Decimal
    let currencyCode: String

    init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    static func zero(currencyCode: String) -> Money {
        Money(amount: 0, currencyCode: currencyCode)
    }

    func adding(_ other: Money) throws -> Money {
        try ensureSameCurrency(as: other)
        return Money(amount: amount + other.amount, currencyCode: currencyCode)
    }

    func subtracting(_ other: Money) throws -> Money {
        try ensureSameCurrency(as: other)
        return Money(amount: amount - other.amount, currencyCode: currencyCode)
    }

    func isGreaterThan(_ other: Money) throws -> Bool {
        try ensureSameCurrency(as: other)
        return amount > other.amount
    }

    func isLessThan(_ other: Money) throws -> Bool {
        try ensureSameCurrency(as: other)
        return amount < other.amount
    }

    private func ensureSameCurrency(as other: Money) throws {
        guard currencyCode == other.currencyCode else {
            throw MoneyError.currencyMismatch(left: currencyCode, right: other.currencyCode)
        }
    }
}

enum MoneyError: Error, Equatable {
    case currencyMismatch(left: String, right: String)
}
