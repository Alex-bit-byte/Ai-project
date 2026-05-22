import Foundation
import SwiftData

@Model
final class CreditModel {
    @Attribute(.unique) var id: UUID
    var memberId: UUID
    var title: String
    var totalAmountString: String
    var downPaymentString: String
    var monthlyPaymentString: String
    var currencyCode: String
    var termMonths: Int
    var startYear: Int
    var startMonth: Int
    var endYear: Int
    var endMonth: Int
    var paymentDay: Int
    var reminderEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        memberId: UUID,
        title: String,
        totalAmountString: String,
        downPaymentString: String,
        monthlyPaymentString: String,
        currencyCode: String,
        termMonths: Int,
        startYear: Int,
        startMonth: Int,
        endYear: Int,
        endMonth: Int,
        paymentDay: Int,
        reminderEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.memberId = memberId
        self.title = title
        self.totalAmountString = totalAmountString
        self.downPaymentString = downPaymentString
        self.monthlyPaymentString = monthlyPaymentString
        self.currencyCode = currencyCode
        self.termMonths = termMonths
        self.startYear = startYear
        self.startMonth = startMonth
        self.endYear = endYear
        self.endMonth = endMonth
        self.paymentDay = paymentDay
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
