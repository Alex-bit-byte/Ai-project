import XCTest
@testable import FamilyBudget

final class CreditUseCaseTests: XCTestCase {
    func testCreateCreditGeneratesPayments() throws {
        let member = FamilyMember(name: "Alex")
        let repository = InMemoryCreditRepository()
        let useCase = CreditUseCase(
            creditRepository: repository,
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )

        let created = try useCase.createCredit(
            CreditDraft(
                memberId: member.id,
                title: " Phone ",
                totalAmount: 900,
                downPayment: 0,
                monthlyPayment: nil,
                usesCalculatedMonthlyPayment: true,
                currencyCode: "USD",
                termMonths: 3,
                startMonth: try YearMonth(year: 2026, month: 1),
                paymentDay: 31,
                reminderEnabled: false
            )
        )

        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created[0].title, "Phone")
        XCTAssertEqual(created[0].monthlyPayment, Money(amount: 300, currencyCode: "USD"))
        XCTAssertEqual(try repository.fetchPayments(creditId: created[0].id, month: nil).count, 3)
        XCTAssertEqual(
            try repository.fetchPayments(creditId: created[0].id, month: nil).map(\.month),
            [try YearMonth(year: 2026, month: 1), try YearMonth(year: 2026, month: 2), try YearMonth(year: 2026, month: 3)]
        )
    }

    func testManualMonthlyPaymentIsUsed() throws {
        let member = FamilyMember(name: "Alex")
        let useCase = CreditUseCase(
            creditRepository: InMemoryCreditRepository(),
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )

        let created = try useCase.createCredit(
            CreditDraft(
                memberId: member.id,
                title: "Manual",
                totalAmount: 1_000,
                downPayment: 100,
                monthlyPayment: 350,
                usesCalculatedMonthlyPayment: false,
                currencyCode: "USD",
                termMonths: 3,
                startMonth: try YearMonth(year: 2026, month: 1),
                paymentDay: 10,
                reminderEnabled: false
            )
        )

        XCTAssertEqual(created[0].monthlyPayment, Money(amount: 350, currencyCode: "USD"))
    }

    func testValidationRejectsMissingMemberEmptyTitleAndInvalidAmounts() throws {
        let member = FamilyMember(name: "Alex")
        let useCase = CreditUseCase(
            creditRepository: InMemoryCreditRepository(),
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )
        let month = try YearMonth(year: 2026, month: 1)

        XCTAssertThrowsError(
            try useCase.createCredit(
                CreditDraft(memberId: nil, title: "Credit", totalAmount: 100, downPayment: 0, monthlyPayment: 10, usesCalculatedMonthlyPayment: false, currencyCode: "USD", termMonths: 1, startMonth: month, paymentDay: 1, reminderEnabled: false)
            )
        ) { error in
            XCTAssertEqual(error as? CreditUseCaseError, .memberRequired)
        }

        XCTAssertThrowsError(
            try useCase.createCredit(
                CreditDraft(memberId: member.id, title: " ", totalAmount: 100, downPayment: 0, monthlyPayment: 10, usesCalculatedMonthlyPayment: false, currencyCode: "USD", termMonths: 1, startMonth: month, paymentDay: 1, reminderEnabled: false)
            )
        ) { error in
            XCTAssertEqual(error as? CreditUseCaseError, .emptyTitle)
        }

        XCTAssertThrowsError(
            try useCase.createCredit(
                CreditDraft(memberId: member.id, title: "Credit", totalAmount: 100, downPayment: 120, monthlyPayment: 10, usesCalculatedMonthlyPayment: false, currencyCode: "USD", termMonths: 1, startMonth: month, paymentDay: 1, reminderEnabled: false)
            )
        ) { error in
            XCTAssertEqual(error as? CreditUseCaseError, .downPaymentExceedsTotalAmount)
        }
    }

    func testUpdateCreditRegeneratesUnpaidPayments() throws {
        let member = FamilyMember(name: "Alex")
        let repository = InMemoryCreditRepository()
        let useCase = CreditUseCase(
            creditRepository: repository,
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )
        let created = try useCase.createCredit(
            CreditDraft(memberId: member.id, title: "Phone", totalAmount: 900, downPayment: 0, monthlyPayment: nil, usesCalculatedMonthlyPayment: true, currencyCode: "USD", termMonths: 3, startMonth: try YearMonth(year: 2026, month: 1), paymentDay: 10, reminderEnabled: false)
        )[0]

        _ = try useCase.updateCredit(
            id: created.id,
            draft: CreditDraft(memberId: member.id, title: "Phone", totalAmount: 1_200, downPayment: 0, monthlyPayment: nil, usesCalculatedMonthlyPayment: true, currencyCode: "USD", termMonths: 4, startMonth: try YearMonth(year: 2026, month: 2), paymentDay: 15, reminderEnabled: false),
            confirmedPaidPaymentChange: false
        )

        let payments = try repository.fetchPayments(creditId: created.id, month: nil)
        XCTAssertEqual(payments.count, 4)
        XCTAssertEqual(payments.map(\.month), [
            try YearMonth(year: 2026, month: 2),
            try YearMonth(year: 2026, month: 3),
            try YearMonth(year: 2026, month: 4),
            try YearMonth(year: 2026, month: 5)
        ])
    }

    func testUpdateCreditWithPaidPaymentsRequiresConfirmationAndPreservesPaidPayment() throws {
        let member = FamilyMember(name: "Alex")
        let repository = InMemoryCreditRepository()
        let useCase = CreditUseCase(
            creditRepository: repository,
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )
        let created = try useCase.createCredit(
            CreditDraft(memberId: member.id, title: "Phone", totalAmount: 900, downPayment: 0, monthlyPayment: nil, usesCalculatedMonthlyPayment: true, currencyCode: "USD", termMonths: 3, startMonth: try YearMonth(year: 2026, month: 1), paymentDay: 10, reminderEnabled: false)
        )[0]
        var firstPayment = try repository.fetchPayments(creditId: created.id, month: nil)[0]
        firstPayment.status = .paid
        firstPayment.paidAt = Date(timeIntervalSince1970: 100)
        try repository.save(firstPayment)

        let draft = CreditDraft(memberId: member.id, title: "Phone", totalAmount: 1_200, downPayment: 0, monthlyPayment: nil, usesCalculatedMonthlyPayment: true, currencyCode: "USD", termMonths: 4, startMonth: try YearMonth(year: 2026, month: 1), paymentDay: 15, reminderEnabled: false)

        XCTAssertThrowsError(try useCase.updateCredit(id: created.id, draft: draft, confirmedPaidPaymentChange: false)) { error in
            XCTAssertEqual(error as? CreditUseCaseError, .paidPaymentsRequireConfirmation)
        }

        _ = try useCase.updateCredit(id: created.id, draft: draft, confirmedPaidPaymentChange: true)
        let payments = try repository.fetchPayments(creditId: created.id, month: nil)

        XCTAssertTrue(payments.contains(firstPayment))
        XCTAssertEqual(payments.count, 4)
    }

    func testDeleteCreditDeletesPayments() throws {
        let member = FamilyMember(name: "Alex")
        let repository = InMemoryCreditRepository()
        let useCase = CreditUseCase(
            creditRepository: repository,
            memberRepository: InMemoryCreditMemberRepository(members: [member])
        )
        let created = try useCase.createCredit(
            CreditDraft(memberId: member.id, title: "Phone", totalAmount: 900, downPayment: 0, monthlyPayment: nil, usesCalculatedMonthlyPayment: true, currencyCode: "USD", termMonths: 3, startMonth: try YearMonth(year: 2026, month: 1), paymentDay: 10, reminderEnabled: false)
        )[0]

        _ = try useCase.deleteCredit(id: created.id)

        XCTAssertTrue(try repository.fetchPayments(creditId: created.id, month: nil).isEmpty)
    }
}

private final class InMemoryCreditRepository: CreditRepositoryProtocol {
    private var credits: [Credit] = []
    private var payments: [CreditPayment] = []

    func fetchCredits(memberId: UUID?) throws -> [Credit] {
        credits.filter { memberId == nil || $0.memberId == memberId }
    }

    func fetchCredit(id: UUID) throws -> Credit? {
        credits.first { $0.id == id }
    }

    func save(_ credit: Credit) throws {
        if let index = credits.firstIndex(where: { $0.id == credit.id }) {
            credits[index] = credit
        } else {
            credits.append(credit)
        }
    }

    func deleteCredit(id: UUID) throws {
        credits.removeAll { $0.id == id }
        payments.removeAll { $0.creditId == id }
    }

    func fetchPayments(creditId: UUID?, month: YearMonth?) throws -> [CreditPayment] {
        payments.filter { payment in
            let matchesCredit = creditId == nil || payment.creditId == creditId
            let matchesMonth = month == nil || payment.month == month
            return matchesCredit && matchesMonth
        }
    }

    func save(_ payment: CreditPayment) throws {
        if let index = payments.firstIndex(where: { $0.id == payment.id }) {
            payments[index] = payment
        } else {
            payments.append(payment)
        }
    }

    func deletePayment(id: UUID) throws {
        payments.removeAll { $0.id == id }
    }
}

private final class InMemoryCreditMemberRepository: FamilyMemberRepositoryProtocol {
    private var members: [FamilyMember]

    init(members: [FamilyMember]) {
        self.members = members
    }

    func fetchAll() throws -> [FamilyMember] {
        members
    }

    func fetch(id: UUID) throws -> FamilyMember? {
        members.first { $0.id == id }
    }

    func save(_ member: FamilyMember) throws {
        members.append(member)
    }

    func delete(id: UUID) throws {
        members.removeAll { $0.id == id }
    }
}
