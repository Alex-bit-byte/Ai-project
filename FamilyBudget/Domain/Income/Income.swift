import Foundation

enum IncomeCategory: Equatable {
    case salary
    case bonus
    case other
}

enum IncomeRecurrence: Equatable {
    case oneTime
    case monthly
}

struct Income: Equatable, Identifiable {
    let id: UUID
    let memberId: UUID
    var category: IncomeCategory
    var title: String?
    var amount: Money
    var recurrence: IncomeRecurrence
    var startMonth: YearMonth
    var endMonth: YearMonth?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        memberId: UUID,
        category: IncomeCategory,
        title: String? = nil,
        amount: Money,
        recurrence: IncomeRecurrence,
        startMonth: YearMonth,
        endMonth: YearMonth? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        if let endMonth, endMonth < startMonth {
            throw DomainValidationError.endMonthBeforeStartMonth
        }

        self.id = id
        self.memberId = memberId
        self.category = category
        self.title = title
        self.amount = amount
        self.recurrence = recurrence
        self.startMonth = startMonth
        self.endMonth = endMonth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func applies(to month: YearMonth) -> Bool {
        switch recurrence {
        case .oneTime:
            return month == startMonth
        case .monthly:
            guard month >= startMonth else {
                return false
            }

            if let endMonth {
                return month <= endMonth
            }

            return true
        }
    }
}

struct IncomeOverride: Equatable, Identifiable {
    let id: UUID
    let incomeId: UUID
    let month: YearMonth
    var amount: Money
    var note: String?

    init(
        id: UUID = UUID(),
        incomeId: UUID,
        month: YearMonth,
        amount: Money,
        note: String? = nil
    ) {
        self.id = id
        self.incomeId = incomeId
        self.month = month
        self.amount = amount
        self.note = note
    }
}

enum DomainValidationError: Error, Equatable {
    case endMonthBeforeStartMonth
    case invalidTermMonths
    case invalidPaymentDay
}
