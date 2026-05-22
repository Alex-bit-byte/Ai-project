import Foundation
import SwiftData

@Model
final class CreditPaymentModel {
    @Attribute(.unique) var id: UUID
    var creditId: UUID
    var year: Int
    var month: Int
    var dueDate: Date
    var amountString: String
    var currencyCode: String
    var statusRawValue: String
    var paidAt: Date?

    init(
        id: UUID,
        creditId: UUID,
        year: Int,
        month: Int,
        dueDate: Date,
        amountString: String,
        currencyCode: String,
        statusRawValue: String,
        paidAt: Date?
    ) {
        self.id = id
        self.creditId = creditId
        self.year = year
        self.month = month
        self.dueDate = dueDate
        self.amountString = amountString
        self.currencyCode = currencyCode
        self.statusRawValue = statusRawValue
        self.paidAt = paidAt
    }
}
