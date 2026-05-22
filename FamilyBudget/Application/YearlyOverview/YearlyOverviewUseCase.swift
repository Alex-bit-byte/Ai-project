import Foundation

enum CreditLoadLevel: Equatable {
    case noIncome
    case normal
    case warning
    case high
}

enum PaymentMonthStatus: Equatable {
    case noPayments
    case scheduled
    case paid
    case overdue
}

struct MonthlyBudgetSummary: Equatable, Identifiable {
    var id: YearMonth { month }

    let month: YearMonth
    let familyIncome: Money
    let creditLoad: Money
    let remaining: Money
    let creditLoadPercentage: CreditLoadPercentage
    let creditLoadLevel: CreditLoadLevel
    let paymentStatus: PaymentMonthStatus
}

struct YearlyOverviewState: Equatable {
    let year: Int
    let summaries: [MonthlyBudgetSummary]
    let hasMembers: Bool
    let hasFinancialData: Bool
}

final class YearlyOverviewUseCase {
    private let memberRepository: FamilyMemberRepositoryProtocol
    private let incomeRepository: IncomeRepositoryProtocol
    private let creditRepository: CreditRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let calendar: Calendar

    init(
        memberRepository: FamilyMemberRepositoryProtocol,
        incomeRepository: IncomeRepositoryProtocol,
        creditRepository: CreditRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.memberRepository = memberRepository
        self.incomeRepository = incomeRepository
        self.creditRepository = creditRepository
        self.settingsRepository = settingsRepository
        self.calendar = calendar
    }

    func overview(year: Int, asOf date: Date = Date()) throws -> YearlyOverviewState {
        let members = try memberRepository.fetchAll()
        let incomes = try incomeRepository.fetchIncomes(memberId: nil)
        let overrides = try incomeRepository.fetchOverrides(incomeId: nil)
        let credits = try creditRepository.fetchCredits(memberId: nil)
        let payments = try creditRepository.fetchPayments(creditId: nil, month: nil)
        let settings = try settingsRepository.loadOrCreateDefault()
        let months = try YearMonth.months(inYear: year)

        let summaries = try months.map { month in
            let income = try BudgetCalculator.familyIncome(
                month: month,
                incomes: incomes,
                overrides: overrides,
                currencyCode: settings.currencyCode
            )
            let creditLoad = try BudgetCalculator.familyCreditLoad(
                month: month,
                payments: payments,
                currencyCode: settings.currencyCode
            )
            let remaining = try BudgetCalculator.remaining(income: income, creditLoad: creditLoad)
            let percentage = try BudgetCalculator.creditLoadPercentage(income: income, creditLoad: creditLoad)

            return MonthlyBudgetSummary(
                month: month,
                familyIncome: income,
                creditLoad: creditLoad,
                remaining: remaining,
                creditLoadPercentage: percentage,
                creditLoadLevel: Self.creditLoadLevel(for: percentage),
                paymentStatus: Self.paymentStatus(for: payments.filter { $0.month == month }, asOf: date)
            )
        }

        return YearlyOverviewState(
            year: year,
            summaries: summaries,
            hasMembers: !members.isEmpty,
            hasFinancialData: !incomes.isEmpty || !credits.isEmpty || !payments.isEmpty
        )
    }

    static func creditLoadLevel(for percentage: CreditLoadPercentage) -> CreditLoadLevel {
        switch percentage {
        case .notApplicable:
            return .noIncome
        case .value(let value) where value < 30:
            return .normal
        case .value(let value) where value <= 50:
            return .warning
        case .value:
            return .high
        }
    }

    static func paymentStatus(for payments: [CreditPayment], asOf date: Date) -> PaymentMonthStatus {
        guard !payments.isEmpty else {
            return .noPayments
        }

        if payments.contains(where: { $0.isOverdue(asOf: date) }) {
            return .overdue
        }

        if payments.allSatisfy({ $0.status == .paid }) {
            return .paid
        }

        return .scheduled
    }
}
