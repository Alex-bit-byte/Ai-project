import Foundation
import SwiftData

final class IncomeRepository: IncomeRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchIncomes(memberId: UUID? = nil) throws -> [Income] {
        try context.fetch(FetchDescriptor<IncomeModel>())
            .filter { memberId == nil || $0.memberId == memberId }
            .map(PersistenceMapper.domain)
    }

    func fetchIncome(id: UUID) throws -> Income? {
        try context.fetch(FetchDescriptor<IncomeModel>())
            .first { $0.id == id }
            .map(PersistenceMapper.domain)
    }

    func save(_ income: Income) throws {
        if let existing = try incomeModel(id: income.id) {
            let replacement = PersistenceMapper.model(from: income)
            copyIncomeFields(from: replacement, to: existing)
        } else {
            context.insert(PersistenceMapper.model(from: income))
        }

        try context.save()
    }

    func deleteIncome(id: UUID) throws {
        if let existing = try incomeModel(id: id) {
            let overrides = try context.fetch(FetchDescriptor<IncomeOverrideModel>())
                .filter { $0.incomeId == id }
            overrides.forEach { context.delete($0) }
            context.delete(existing)
            try context.save()
        }
    }

    func fetchOverrides(incomeId: UUID? = nil) throws -> [IncomeOverride] {
        try context.fetch(FetchDescriptor<IncomeOverrideModel>())
            .filter { incomeId == nil || $0.incomeId == incomeId }
            .map(PersistenceMapper.domain)
    }

    func save(_ override: IncomeOverride) throws {
        if let existing = try overrideModel(id: override.id) {
            let replacement = PersistenceMapper.model(from: override)
            existing.incomeId = replacement.incomeId
            existing.year = replacement.year
            existing.month = replacement.month
            existing.amountString = replacement.amountString
            existing.currencyCode = replacement.currencyCode
            existing.note = replacement.note
        } else {
            context.insert(PersistenceMapper.model(from: override))
        }

        try context.save()
    }

    func deleteOverride(id: UUID) throws {
        if let existing = try overrideModel(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    private func incomeModel(id: UUID) throws -> IncomeModel? {
        try context.fetch(FetchDescriptor<IncomeModel>())
            .first { $0.id == id }
    }

    private func overrideModel(id: UUID) throws -> IncomeOverrideModel? {
        try context.fetch(FetchDescriptor<IncomeOverrideModel>())
            .first { $0.id == id }
    }

    private func copyIncomeFields(from source: IncomeModel, to destination: IncomeModel) {
        destination.memberId = source.memberId
        destination.categoryRawValue = source.categoryRawValue
        destination.title = source.title
        destination.amountString = source.amountString
        destination.currencyCode = source.currencyCode
        destination.recurrenceRawValue = source.recurrenceRawValue
        destination.startYear = source.startYear
        destination.startMonth = source.startMonth
        destination.endYear = source.endYear
        destination.endMonth = source.endMonth
        destination.updatedAt = source.updatedAt
    }
}
