import Foundation
import SwiftData

final class CreditRepository: CreditRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCredits(memberId: UUID? = nil) throws -> [Credit] {
        try context.fetch(FetchDescriptor<CreditModel>())
            .filter { memberId == nil || $0.memberId == memberId }
            .map(PersistenceMapper.domain)
    }

    func fetchCredit(id: UUID) throws -> Credit? {
        try context.fetch(FetchDescriptor<CreditModel>())
            .first { $0.id == id }
            .map(PersistenceMapper.domain)
    }

    func save(_ credit: Credit) throws {
        if let existing = try creditModel(id: credit.id) {
            let replacement = PersistenceMapper.model(from: credit)
            copyCreditFields(from: replacement, to: existing)
        } else {
            context.insert(PersistenceMapper.model(from: credit))
        }

        try context.save()
    }

    func deleteCredit(id: UUID) throws {
        if let existing = try creditModel(id: id) {
            let payments = try context.fetch(FetchDescriptor<CreditPaymentModel>())
                .filter { $0.creditId == id }
            payments.forEach { context.delete($0) }
            context.delete(existing)
            try context.save()
        }
    }

    func fetchPayments(creditId: UUID? = nil, month: YearMonth? = nil) throws -> [CreditPayment] {
        try context.fetch(FetchDescriptor<CreditPaymentModel>())
            .filter { model in
                let matchesCredit = creditId == nil || model.creditId == creditId
                let matchesMonth = month == nil || (model.year == month?.year && model.month == month?.month)
                return matchesCredit && matchesMonth
            }
            .map(PersistenceMapper.domain)
    }

    func save(_ payment: CreditPayment) throws {
        if let existing = try paymentModel(id: payment.id) {
            let replacement = PersistenceMapper.model(from: payment)
            existing.creditId = replacement.creditId
            existing.year = replacement.year
            existing.month = replacement.month
            existing.dueDate = replacement.dueDate
            existing.amountString = replacement.amountString
            existing.currencyCode = replacement.currencyCode
            existing.statusRawValue = replacement.statusRawValue
            existing.paidAt = replacement.paidAt
        } else {
            context.insert(PersistenceMapper.model(from: payment))
        }

        try context.save()
    }

    func deletePayment(id: UUID) throws {
        if let existing = try paymentModel(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    private func creditModel(id: UUID) throws -> CreditModel? {
        try context.fetch(FetchDescriptor<CreditModel>())
            .first { $0.id == id }
    }

    private func paymentModel(id: UUID) throws -> CreditPaymentModel? {
        try context.fetch(FetchDescriptor<CreditPaymentModel>())
            .first { $0.id == id }
    }

    private func copyCreditFields(from source: CreditModel, to destination: CreditModel) {
        destination.memberId = source.memberId
        destination.title = source.title
        destination.totalAmountString = source.totalAmountString
        destination.downPaymentString = source.downPaymentString
        destination.monthlyPaymentString = source.monthlyPaymentString
        destination.currencyCode = source.currencyCode
        destination.termMonths = source.termMonths
        destination.startYear = source.startYear
        destination.startMonth = source.startMonth
        destination.endYear = source.endYear
        destination.endMonth = source.endMonth
        destination.paymentDay = source.paymentDay
        destination.reminderEnabled = source.reminderEnabled
        destination.updatedAt = source.updatedAt
    }
}
