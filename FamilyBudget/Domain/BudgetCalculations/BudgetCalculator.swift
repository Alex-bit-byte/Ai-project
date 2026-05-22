import Foundation

enum CreditLoadPercentage: Equatable {
    case notApplicable
    case value(Decimal)
}

enum BudgetCalculator {
    static func calculatedMonthlyPayment(totalAmount: Money, downPayment: Money, termMonths: Int) throws -> Money {
        guard termMonths > 0 else {
            throw DomainValidationError.invalidTermMonths
        }

        let principal = try totalAmount.subtracting(downPayment)
        return Money(amount: principal.amount / Decimal(termMonths), currencyCode: totalAmount.currencyCode)
    }

    static func incomeAmount(
        for income: Income,
        in month: YearMonth,
        overrides: [IncomeOverride]
    ) -> Money? {
        guard income.applies(to: month) else {
            return nil
        }

        if income.recurrence == .monthly,
           let override = overrides.first(where: { $0.incomeId == income.id && $0.month == month }) {
            return override.amount
        }

        return income.amount
    }

    static func memberIncome(
        memberId: UUID,
        month: YearMonth,
        incomes: [Income],
        overrides: [IncomeOverride],
        currencyCode: String
    ) throws -> Money {
        let amounts = incomes
            .filter { $0.memberId == memberId }
            .compactMap { incomeAmount(for: $0, in: month, overrides: overrides) }

        return try sum(amounts, currencyCode: currencyCode)
    }

    static func familyIncome(
        month: YearMonth,
        incomes: [Income],
        overrides: [IncomeOverride],
        currencyCode: String
    ) throws -> Money {
        let amounts = incomes.compactMap { incomeAmount(for: $0, in: month, overrides: overrides) }
        return try sum(amounts, currencyCode: currencyCode)
    }

    static func generatePayments(for credit: Credit, calendar: Calendar = Calendar(identifier: .gregorian)) throws -> [CreditPayment] {
        let months = try YearMonth.months(from: credit.startMonth, through: credit.endMonth)

        return months.map { month in
            CreditPayment(
                creditId: credit.id,
                month: month,
                dueDate: dueDate(for: month, paymentDay: credit.paymentDay, calendar: calendar),
                amount: credit.monthlyPayment
            )
        }
    }

    static func memberCreditLoad(
        memberId: UUID,
        month: YearMonth,
        credits: [Credit],
        payments: [CreditPayment],
        currencyCode: String
    ) throws -> Money {
        let creditIds = Set(credits.filter { $0.memberId == memberId }.map(\.id))
        let amounts = payments
            .filter { creditIds.contains($0.creditId) && $0.month == month }
            .map(\.amount)

        return try sum(amounts, currencyCode: currencyCode)
    }

    static func familyCreditLoad(
        month: YearMonth,
        payments: [CreditPayment],
        currencyCode: String
    ) throws -> Money {
        let amounts = payments
            .filter { $0.month == month }
            .map(\.amount)

        return try sum(amounts, currencyCode: currencyCode)
    }

    static func remaining(income: Money, creditLoad: Money) throws -> Money {
        try income.subtracting(creditLoad)
    }

    static func creditLoadPercentage(income: Money, creditLoad: Money) throws -> CreditLoadPercentage {
        _ = try income.adding(creditLoad)

        guard income.amount != 0 else {
            return .notApplicable
        }

        return .value((creditLoad.amount / income.amount) * 100)
    }

    private static func sum(_ amounts: [Money], currencyCode: String) throws -> Money {
        try amounts.reduce(Money.zero(currencyCode: currencyCode)) { partialResult, amount in
            try partialResult.adding(amount)
        }
    }

    private static func dueDate(for month: YearMonth, paymentDay: Int, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.year = month.year
        components.month = month.month
        components.day = 1

        let firstDay = calendar.date(from: components)!
        let dayRange = calendar.range(of: .day, in: .month, for: firstDay)!
        components.day = min(paymentDay, dayRange.count)

        return calendar.date(from: components)!
    }
}
