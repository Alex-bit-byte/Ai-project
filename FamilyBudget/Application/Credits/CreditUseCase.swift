import Foundation

protocol CreditRepositoryProtocol {
    func fetchCredits(memberId: UUID?) throws -> [Credit]
    func fetchCredit(id: UUID) throws -> Credit?
    func save(_ credit: Credit) throws
    func deleteCredit(id: UUID) throws
    func fetchPayments(creditId: UUID?, month: YearMonth?) throws -> [CreditPayment]
    func save(_ payment: CreditPayment) throws
    func deletePayment(id: UUID) throws
}

struct CreditListItem: Equatable, Identifiable {
    let id: UUID
    let memberId: UUID
    let memberName: String
    let title: String
    let totalAmount: Money
    let downPayment: Money
    let monthlyPayment: Money
    let termMonths: Int
    let startMonth: YearMonth
    let endMonth: YearMonth
    let paymentDay: Int
    let reminderEnabled: Bool
    let hasPaidPayments: Bool
}

struct CreditDraft: Equatable {
    var memberId: UUID?
    var title: String
    var totalAmount: Decimal?
    var downPayment: Decimal?
    var monthlyPayment: Decimal?
    var usesCalculatedMonthlyPayment: Bool
    var currencyCode: String
    var termMonths: Int
    var startMonth: YearMonth
    var paymentDay: Int
    var reminderEnabled: Bool
}

enum CreditUseCaseError: Error, Equatable {
    case memberRequired
    case memberNotFound
    case creditNotFound
    case emptyTitle
    case invalidAmount
    case downPaymentExceedsTotalAmount
    case invalidTermMonths
    case invalidPaymentDay
    case paidPaymentsRequireConfirmation
}

final class CreditUseCase {
    private let creditRepository: CreditRepositoryProtocol
    private let memberRepository: FamilyMemberRepositoryProtocol
    private let calendar: Calendar

    init(
        creditRepository: CreditRepositoryProtocol,
        memberRepository: FamilyMemberRepositoryProtocol,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.creditRepository = creditRepository
        self.memberRepository = memberRepository
        self.calendar = calendar
    }

    func listMembers() throws -> [FamilyMemberListItem] {
        try memberRepository.fetchAll()
            .sorted { $0.createdAt < $1.createdAt }
            .map { FamilyMemberListItem(id: $0.id, name: $0.name) }
    }

    func listCredits(memberId: UUID? = nil) throws -> [CreditListItem] {
        let membersById = Dictionary(uniqueKeysWithValues: try memberRepository.fetchAll().map { ($0.id, $0.name) })
        let allPayments = try creditRepository.fetchPayments(creditId: nil, month: nil)

        return try creditRepository.fetchCredits(memberId: memberId)
            .sorted { $0.createdAt < $1.createdAt }
            .map { credit in
                CreditListItem(
                    id: credit.id,
                    memberId: credit.memberId,
                    memberName: membersById[credit.memberId] ?? "Участник удален",
                    title: credit.title,
                    totalAmount: credit.totalAmount,
                    downPayment: credit.downPayment,
                    monthlyPayment: credit.monthlyPayment,
                    termMonths: credit.termMonths,
                    startMonth: credit.startMonth,
                    endMonth: credit.endMonth,
                    paymentDay: credit.paymentDay,
                    reminderEnabled: credit.reminderEnabled,
                    hasPaidPayments: allPayments.contains { $0.creditId == credit.id && $0.status == .paid }
                )
            }
    }

    func listPayments(creditId: UUID) throws -> [CreditPayment] {
        try creditRepository.fetchPayments(creditId: creditId, month: nil)
            .sorted { $0.month < $1.month }
    }

    func calculatedMonthlyPayment(totalAmount: Decimal?, downPayment: Decimal?, termMonths: Int, currencyCode: String) throws -> Money {
        guard let totalAmount, let downPayment, totalAmount >= 0, downPayment >= 0 else {
            throw CreditUseCaseError.invalidAmount
        }

        guard downPayment <= totalAmount else {
            throw CreditUseCaseError.downPaymentExceedsTotalAmount
        }

        guard termMonths > 0 else {
            throw CreditUseCaseError.invalidTermMonths
        }

        return try BudgetCalculator.calculatedMonthlyPayment(
            totalAmount: Money(amount: totalAmount, currencyCode: currencyCode),
            downPayment: Money(amount: downPayment, currencyCode: currencyCode),
            termMonths: termMonths
        )
    }

    func createCredit(_ draft: CreditDraft) throws -> [CreditListItem] {
        let credit = try makeCredit(from: draft)
        try creditRepository.save(credit)
        try regeneratePayments(for: credit, preservingPaidPayments: [])
        return try listCredits()
    }

    func updateCredit(id: UUID, draft: CreditDraft, confirmedPaidPaymentChange: Bool) throws -> [CreditListItem] {
        guard let existing = try creditRepository.fetchCredit(id: id) else {
            throw CreditUseCaseError.creditNotFound
        }

        let existingPayments = try creditRepository.fetchPayments(creditId: id, month: nil)
        let paidPayments = existingPayments.filter { $0.status == .paid }
        if !paidPayments.isEmpty && !confirmedPaidPaymentChange {
            throw CreditUseCaseError.paidPaymentsRequireConfirmation
        }

        let credit = try makeCredit(from: draft, id: existing.id, createdAt: existing.createdAt)
        try creditRepository.save(credit)
        try regeneratePayments(for: credit, preservingPaidPayments: paidPayments)
        return try listCredits()
    }

    func deleteCredit(id: UUID) throws -> [CreditListItem] {
        guard try creditRepository.fetchCredit(id: id) != nil else {
            throw CreditUseCaseError.creditNotFound
        }

        try creditRepository.deleteCredit(id: id)
        return try listCredits()
    }

    private func makeCredit(from draft: CreditDraft, id: UUID = UUID(), createdAt: Date = Date()) throws -> Credit {
        guard let memberId = draft.memberId else {
            throw CreditUseCaseError.memberRequired
        }

        guard try memberRepository.fetch(id: memberId) != nil else {
            throw CreditUseCaseError.memberNotFound
        }

        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw CreditUseCaseError.emptyTitle
        }

        guard let totalAmount = draft.totalAmount,
              let downPayment = draft.downPayment,
              totalAmount >= 0,
              downPayment >= 0 else {
            throw CreditUseCaseError.invalidAmount
        }

        guard draft.termMonths > 0 else {
            throw CreditUseCaseError.invalidTermMonths
        }

        guard (1...31).contains(draft.paymentDay) else {
            throw CreditUseCaseError.invalidPaymentDay
        }

        guard downPayment <= totalAmount else {
            throw CreditUseCaseError.downPaymentExceedsTotalAmount
        }

        let monthlyPayment: Money
        if draft.usesCalculatedMonthlyPayment {
            monthlyPayment = try calculatedMonthlyPayment(
                totalAmount: totalAmount,
                downPayment: downPayment,
                termMonths: draft.termMonths,
                currencyCode: draft.currencyCode
            )
        } else {
            guard let manualMonthlyPayment = draft.monthlyPayment, manualMonthlyPayment >= 0 else {
                throw CreditUseCaseError.invalidAmount
            }
            monthlyPayment = Money(amount: manualMonthlyPayment, currencyCode: draft.currencyCode)
        }

        do {
            return try Credit(
                id: id,
                memberId: memberId,
                title: title,
                totalAmount: Money(amount: totalAmount, currencyCode: draft.currencyCode),
                downPayment: Money(amount: downPayment, currencyCode: draft.currencyCode),
                monthlyPayment: monthlyPayment,
                termMonths: draft.termMonths,
                startMonth: draft.startMonth,
                paymentDay: draft.paymentDay,
                reminderEnabled: draft.reminderEnabled,
                createdAt: createdAt,
                updatedAt: Date()
            )
        } catch DomainValidationError.invalidTermMonths {
            throw CreditUseCaseError.invalidTermMonths
        } catch DomainValidationError.invalidPaymentDay {
            throw CreditUseCaseError.invalidPaymentDay
        } catch DomainValidationError.downPaymentExceedsTotalAmount {
            throw CreditUseCaseError.downPaymentExceedsTotalAmount
        } catch DomainValidationError.negativeMoneyAmount {
            throw CreditUseCaseError.invalidAmount
        }
    }

    private func regeneratePayments(for credit: Credit, preservingPaidPayments paidPayments: [CreditPayment]) throws {
        let paidPaymentIds = Set(paidPayments.map(\.id))
        let existingPayments = try creditRepository.fetchPayments(creditId: credit.id, month: nil)
        for payment in existingPayments where !paidPaymentIds.contains(payment.id) {
            try creditRepository.deletePayment(id: payment.id)
        }

        let paidMonths = Set(paidPayments.map(\.month))
        let generatedPayments = try BudgetCalculator.generatePayments(for: credit, calendar: calendar)
        for payment in generatedPayments where !paidMonths.contains(payment.month) {
            try creditRepository.save(payment)
        }
    }
}
