import Foundation
import SwiftData

final class FamilyMemberRelatedDataRepository: FamilyMemberRelatedDataHandling {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func hasRelatedData(memberId: UUID) throws -> Bool {
        let incomes = try context.fetch(FetchDescriptor<IncomeModel>())
        if incomes.contains(where: { $0.memberId == memberId }) {
            return true
        }

        let credits = try context.fetch(FetchDescriptor<CreditModel>())
        return credits.contains(where: { $0.memberId == memberId })
    }

    func deleteRelatedData(memberId: UUID) throws {
        let incomes = try context.fetch(FetchDescriptor<IncomeModel>())
            .filter { $0.memberId == memberId }
        let incomeIds = Set(incomes.map(\.id))
        let overrides = try context.fetch(FetchDescriptor<IncomeOverrideModel>())
            .filter { incomeIds.contains($0.incomeId) }

        let credits = try context.fetch(FetchDescriptor<CreditModel>())
            .filter { $0.memberId == memberId }
        let creditIds = Set(credits.map(\.id))
        let payments = try context.fetch(FetchDescriptor<CreditPaymentModel>())
            .filter { creditIds.contains($0.creditId) }

        overrides.forEach(context.delete)
        incomes.forEach(context.delete)
        payments.forEach(context.delete)
        credits.forEach(context.delete)

        try context.save()
    }
}
