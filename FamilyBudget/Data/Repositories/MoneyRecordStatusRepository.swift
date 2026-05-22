import SwiftData

final class MoneyRecordStatusRepository: MoneyRecordStatusChecking {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func hasMoneyRecords() throws -> Bool {
        let incomes = try context.fetch(FetchDescriptor<IncomeModel>())
        if !incomes.isEmpty {
            return true
        }

        let credits = try context.fetch(FetchDescriptor<CreditModel>())
        if !credits.isEmpty {
            return true
        }

        let payments = try context.fetch(FetchDescriptor<CreditPaymentModel>())
        return !payments.isEmpty
    }
}
