import Foundation
import SwiftData

@Model
final class IncomeModel {
    @Attribute(.unique) var id: UUID
    var memberId: UUID
    var categoryRawValue: String
    var title: String?
    var amountString: String
    var currencyCode: String
    var recurrenceRawValue: String
    var startYear: Int
    var startMonth: Int
    var endYear: Int?
    var endMonth: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        memberId: UUID,
        categoryRawValue: String,
        title: String?,
        amountString: String,
        currencyCode: String,
        recurrenceRawValue: String,
        startYear: Int,
        startMonth: Int,
        endYear: Int?,
        endMonth: Int?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.memberId = memberId
        self.categoryRawValue = categoryRawValue
        self.title = title
        self.amountString = amountString
        self.currencyCode = currencyCode
        self.recurrenceRawValue = recurrenceRawValue
        self.startYear = startYear
        self.startMonth = startMonth
        self.endYear = endYear
        self.endMonth = endMonth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
