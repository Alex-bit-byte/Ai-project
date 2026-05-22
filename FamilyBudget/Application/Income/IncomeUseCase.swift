import Foundation

protocol IncomeRepositoryProtocol {
    func fetchIncomes(memberId: UUID?) throws -> [Income]
    func fetchIncome(id: UUID) throws -> Income?
    func save(_ income: Income) throws
    func deleteIncome(id: UUID) throws
    func fetchOverrides(incomeId: UUID?) throws -> [IncomeOverride]
    func save(_ override: IncomeOverride) throws
    func deleteOverride(id: UUID) throws
}

struct IncomeListItem: Equatable, Identifiable {
    let id: UUID
    let memberId: UUID
    let memberName: String
    let category: IncomeCategory
    let title: String?
    let amount: Money
    let recurrence: IncomeRecurrence
    let startMonth: YearMonth
    let endMonth: YearMonth?
}

struct IncomeOverrideListItem: Equatable, Identifiable {
    let id: UUID
    let incomeId: UUID
    let month: YearMonth
    let amount: Money
    let note: String?
}

struct IncomeDraft: Equatable {
    var memberId: UUID?
    var category: IncomeCategory
    var title: String
    var amount: Decimal?
    var currencyCode: String
    var recurrence: IncomeRecurrence
    var startMonth: YearMonth
    var endMonth: YearMonth?
}

struct IncomeOverrideDraft: Equatable {
    var incomeId: UUID
    var month: YearMonth
    var amount: Decimal?
    var currencyCode: String
    var note: String
}

enum IncomeUseCaseError: Error, Equatable {
    case memberRequired
    case memberNotFound
    case incomeNotFound
    case invalidAmount
    case invalidPeriod
    case overrideOutsideIncomePeriod
    case overrideOnlyForMonthlyIncome
}

final class IncomeUseCase {
    private let incomeRepository: IncomeRepositoryProtocol
    private let memberRepository: FamilyMemberRepositoryProtocol

    init(incomeRepository: IncomeRepositoryProtocol, memberRepository: FamilyMemberRepositoryProtocol) {
        self.incomeRepository = incomeRepository
        self.memberRepository = memberRepository
    }

    func listMembers() throws -> [FamilyMemberListItem] {
        try memberRepository.fetchAll()
            .sorted { $0.createdAt < $1.createdAt }
            .map { FamilyMemberListItem(id: $0.id, name: $0.name) }
    }

    func listIncomes(memberId: UUID? = nil) throws -> [IncomeListItem] {
        let membersById = Dictionary(uniqueKeysWithValues: try memberRepository.fetchAll().map { ($0.id, $0.name) })

        return try incomeRepository.fetchIncomes(memberId: memberId)
            .sorted { $0.createdAt < $1.createdAt }
            .map { income in
                IncomeListItem(
                    id: income.id,
                    memberId: income.memberId,
                    memberName: membersById[income.memberId] ?? "Участник удален",
                    category: income.category,
                    title: income.title,
                    amount: income.amount,
                    recurrence: income.recurrence,
                    startMonth: income.startMonth,
                    endMonth: income.endMonth
                )
            }
    }

    func listOverrides(incomeId: UUID) throws -> [IncomeOverrideListItem] {
        try incomeRepository.fetchOverrides(incomeId: incomeId)
            .sorted { $0.month < $1.month }
            .map {
                IncomeOverrideListItem(id: $0.id, incomeId: $0.incomeId, month: $0.month, amount: $0.amount, note: $0.note)
            }
    }

    func createIncome(_ draft: IncomeDraft) throws -> [IncomeListItem] {
        let income = try makeIncome(from: draft)
        try incomeRepository.save(income)
        return try listIncomes()
    }

    func updateIncome(id: UUID, draft: IncomeDraft) throws -> [IncomeListItem] {
        guard let existing = try incomeRepository.fetchIncome(id: id) else {
            throw IncomeUseCaseError.incomeNotFound
        }

        let income = try makeIncome(from: draft, id: existing.id, createdAt: existing.createdAt)
        try incomeRepository.save(income)
        try deleteInvalidOverrides(for: income)
        return try listIncomes()
    }

    func deleteIncome(id: UUID) throws -> [IncomeListItem] {
        guard try incomeRepository.fetchIncome(id: id) != nil else {
            throw IncomeUseCaseError.incomeNotFound
        }

        try incomeRepository.deleteIncome(id: id)
        return try listIncomes()
    }

    func createOverride(_ draft: IncomeOverrideDraft) throws -> [IncomeOverrideListItem] {
        let override = try makeOverride(from: draft)
        try incomeRepository.save(override)
        return try listOverrides(incomeId: draft.incomeId)
    }

    func updateOverride(id: UUID, draft: IncomeOverrideDraft) throws -> [IncomeOverrideListItem] {
        guard try incomeRepository.fetchOverrides(incomeId: draft.incomeId).contains(where: { $0.id == id }) else {
            throw IncomeUseCaseError.incomeNotFound
        }

        let override = try makeOverride(from: draft, id: id)
        try incomeRepository.save(override)
        return try listOverrides(incomeId: draft.incomeId)
    }

    func deleteOverride(id: UUID, incomeId: UUID) throws -> [IncomeOverrideListItem] {
        try incomeRepository.deleteOverride(id: id)
        return try listOverrides(incomeId: incomeId)
    }

    private func makeIncome(from draft: IncomeDraft, id: UUID = UUID(), createdAt: Date = Date()) throws -> Income {
        guard let memberId = draft.memberId else {
            throw IncomeUseCaseError.memberRequired
        }

        guard try memberRepository.fetch(id: memberId) != nil else {
            throw IncomeUseCaseError.memberNotFound
        }

        guard let amount = draft.amount, amount > 0 else {
            throw IncomeUseCaseError.invalidAmount
        }

        if let endMonth = draft.endMonth, endMonth < draft.startMonth {
            throw IncomeUseCaseError.invalidPeriod
        }

        do {
            return try Income(
                id: id,
                memberId: memberId,
                category: draft.category,
                title: normalizedOptionalText(draft.title),
                amount: Money(amount: amount, currencyCode: draft.currencyCode),
                recurrence: draft.recurrence,
                startMonth: draft.startMonth,
                endMonth: draft.endMonth,
                createdAt: createdAt,
                updatedAt: Date()
            )
        } catch DomainValidationError.endMonthBeforeStartMonth {
            throw IncomeUseCaseError.invalidPeriod
        }
    }

    private func makeOverride(from draft: IncomeOverrideDraft, id: UUID = UUID()) throws -> IncomeOverride {
        guard let income = try incomeRepository.fetchIncome(id: draft.incomeId) else {
            throw IncomeUseCaseError.incomeNotFound
        }

        guard income.recurrence == .monthly else {
            throw IncomeUseCaseError.overrideOnlyForMonthlyIncome
        }

        guard income.applies(to: draft.month) else {
            throw IncomeUseCaseError.overrideOutsideIncomePeriod
        }

        guard let amount = draft.amount, amount > 0 else {
            throw IncomeUseCaseError.invalidAmount
        }

        return IncomeOverride(
            id: id,
            incomeId: draft.incomeId,
            month: draft.month,
            amount: Money(amount: amount, currencyCode: draft.currencyCode),
            note: normalizedOptionalText(draft.note)
        )
    }

    private func deleteInvalidOverrides(for income: Income) throws {
        let overrides = try incomeRepository.fetchOverrides(incomeId: income.id)
        for override in overrides where income.recurrence != .monthly || !income.applies(to: override.month) {
            try incomeRepository.deleteOverride(id: override.id)
        }
    }

    private func normalizedOptionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
