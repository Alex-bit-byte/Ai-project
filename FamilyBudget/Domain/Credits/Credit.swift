import Foundation

enum PaymentStatus: Equatable {
    case scheduled
    case paid
    case skipped
}

struct Credit: Equatable, Identifiable {
    let id: UUID
    let memberId: UUID
    var title: String
    var totalAmount: Money
    var downPayment: Money
    var monthlyPayment: Money
    var termMonths: Int
    var startMonth: YearMonth
    var endMonth: YearMonth
    var paymentDay: Int
    var reminderEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        memberId: UUID,
        title: String,
        totalAmount: Money,
        downPayment: Money,
        monthlyPayment: Money,
        termMonths: Int,
        startMonth: YearMonth,
        paymentDay: Int,
        reminderEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        guard termMonths > 0 else {
            throw DomainValidationError.invalidTermMonths
        }

        guard (1...31).contains(paymentDay) else {
            throw DomainValidationError.invalidPaymentDay
        }

        _ = try totalAmount.subtracting(downPayment)
        _ = try totalAmount.subtracting(monthlyPayment)

        self.id = id
        self.memberId = memberId
        self.title = title
        self.totalAmount = totalAmount
        self.downPayment = downPayment
        self.monthlyPayment = monthlyPayment
        self.termMonths = termMonths
        self.startMonth = startMonth
        self.endMonth = try startMonth.addingMonths(termMonths - 1)
        self.paymentDay = paymentDay
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreditPayment: Equatable, Identifiable {
    let id: UUID
    let creditId: UUID
    let month: YearMonth
    let dueDate: Date
    var amount: Money
    var status: PaymentStatus
    var paidAt: Date?

    init(
        id: UUID = UUID(),
        creditId: UUID,
        month: YearMonth,
        dueDate: Date,
        amount: Money,
        status: PaymentStatus = .scheduled,
        paidAt: Date? = nil
    ) {
        self.id = id
        self.creditId = creditId
        self.month = month
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.paidAt = paidAt
    }

    func isOverdue(asOf date: Date) -> Bool {
        status != .paid && dueDate < date
    }
}
