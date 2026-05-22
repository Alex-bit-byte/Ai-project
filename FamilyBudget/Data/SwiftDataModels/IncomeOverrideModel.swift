import Foundation
import SwiftData

@Model
final class IncomeOverrideModel {
    @Attribute(.unique) var id: UUID
    var incomeId: UUID
    var year: Int
    var month: Int
    var amountString: String
    var currencyCode: String
    var note: String?

    init(
        id: UUID,
        incomeId: UUID,
        year: Int,
        month: Int,
        amountString: String,
        currencyCode: String,
        note: String?
    ) {
        self.id = id
        self.incomeId = incomeId
        self.year = year
        self.month = month
        self.amountString = amountString
        self.currencyCode = currencyCode
        self.note = note
    }
}
