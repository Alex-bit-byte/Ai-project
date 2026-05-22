import Combine
import Foundation

@MainActor
final class CreditViewModel: ObservableObject {
    private static let defaultCurrencyCode = "USD"

    enum State: Equatable {
        case idle
        case loading
        case noMembers
        case empty(members: [FamilyMemberListItem])
        case loaded(credits: [CreditListItem], members: [FamilyMemberListItem])
        case editing(CreditListItem?, members: [FamilyMemberListItem])
        case payments(credit: CreditListItem, payments: [CreditPayment])
        case confirmDelete(CreditListItem)
        case confirmPaidPaymentUpdate(CreditListItem)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var draftMemberId: UUID?
    @Published var draftTitle: String = ""
    @Published var draftTotalAmount: String = ""
    @Published var draftDownPayment: String = "0"
    @Published var draftMonthlyPayment: String = ""
    @Published var draftUsesCalculatedMonthlyPayment: Bool = true
    @Published var draftCurrencyCode: String = defaultCurrencyCode
    @Published var draftTermMonths: Int = 1
    @Published var draftStartYear: Int = Calendar.current.component(.year, from: Date())
    @Published var draftStartMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var draftPaymentDay: Int = 1
    @Published var draftReminderEnabled: Bool = false

    private var pendingPaidPaymentDraft: CreditDraft?

    func load(useCase: CreditUseCase) {
        state = .loading
        refresh(useCase: useCase)
    }

    func startCreate(members: [FamilyMemberListItem]) {
        resetDraft(member: members.first)
        state = .editing(nil, members: members)
    }

    func startEdit(_ credit: CreditListItem, members: [FamilyMemberListItem]) {
        draftMemberId = credit.memberId
        draftTitle = credit.title
        draftTotalAmount = Self.format(credit.totalAmount.amount)
        draftDownPayment = Self.format(credit.downPayment.amount)
        draftMonthlyPayment = Self.format(credit.monthlyPayment.amount)
        draftUsesCalculatedMonthlyPayment = false
        draftCurrencyCode = credit.totalAmount.currencyCode
        draftTermMonths = credit.termMonths
        draftStartYear = credit.startMonth.year
        draftStartMonth = credit.startMonth.month
        draftPaymentDay = credit.paymentDay
        draftReminderEnabled = credit.reminderEnabled
        state = .editing(credit, members: members)
    }

    func saveCredit(currentItem: CreditListItem?, useCase: CreditUseCase) {
        do {
            let draft = try makeDraft()
            let items: [CreditListItem]
            if let currentItem {
                do {
                    items = try useCase.updateCredit(id: currentItem.id, draft: draft, confirmedPaidPaymentChange: false)
                } catch CreditUseCaseError.paidPaymentsRequireConfirmation {
                    pendingPaidPaymentDraft = draft
                    state = .confirmPaidPaymentUpdate(currentItem)
                    return
                }
            } else {
                items = try useCase.createCredit(draft)
            }
            setListState(credits: items, members: try useCase.listMembers())
        } catch {
            state = .error(message(for: error))
        }
    }

    func confirmPaidPaymentUpdate(_ credit: CreditListItem, useCase: CreditUseCase) {
        guard let draft = pendingPaidPaymentDraft else {
            state = .error("Не удалось восстановить изменения кредита.")
            return
        }

        do {
            let items = try useCase.updateCredit(id: credit.id, draft: draft, confirmedPaidPaymentChange: true)
            pendingPaidPaymentDraft = nil
            setListState(credits: items, members: try useCase.listMembers())
        } catch {
            state = .error(message(for: error))
        }
    }

    func requestDelete(_ credit: CreditListItem) {
        state = .confirmDelete(credit)
    }

    func confirmDelete(_ credit: CreditListItem, useCase: CreditUseCase) {
        do {
            setListState(credits: try useCase.deleteCredit(id: credit.id), members: try useCase.listMembers())
        } catch {
            state = .error(message(for: error))
        }
    }

    func showPayments(for credit: CreditListItem, useCase: CreditUseCase) {
        do {
            state = .payments(credit: credit, payments: try useCase.listPayments(creditId: credit.id))
        } catch {
            state = .error("Не удалось загрузить график платежей.")
        }
    }

    func cancel(useCase: CreditUseCase) {
        pendingPaidPaymentDraft = nil
        refresh(useCase: useCase)
    }

    func updateCalculatedMonthlyPayment(useCase: CreditUseCase) {
        guard draftUsesCalculatedMonthlyPayment else {
            return
        }

        do {
            let payment = try useCase.calculatedMonthlyPayment(
                totalAmount: Self.decimal(from: draftTotalAmount),
                downPayment: Self.decimal(from: draftDownPayment),
                termMonths: draftTermMonths,
                currencyCode: draftCurrencyCode
            )
            draftMonthlyPayment = Self.format(payment.amount)
        } catch {
            draftMonthlyPayment = ""
        }
    }

    private func refresh(useCase: CreditUseCase) {
        do {
            let members = try useCase.listMembers()
            guard !members.isEmpty else {
                state = .noMembers
                return
            }

            setListState(credits: try useCase.listCredits(), members: members)
        } catch {
            state = .error("Не удалось загрузить кредиты.")
        }
    }

    private func setListState(credits: [CreditListItem], members: [FamilyMemberListItem]) {
        state = credits.isEmpty ? .empty(members: members) : .loaded(credits: credits, members: members)
    }

    private func resetDraft(member: FamilyMemberListItem?) {
        let now = Date()
        let calendar = Calendar.current
        draftMemberId = member?.id
        draftTitle = ""
        draftTotalAmount = ""
        draftDownPayment = "0"
        draftMonthlyPayment = ""
        draftUsesCalculatedMonthlyPayment = true
        draftCurrencyCode = Self.defaultCurrencyCode
        draftTermMonths = 1
        draftStartYear = calendar.component(.year, from: now)
        draftStartMonth = calendar.component(.month, from: now)
        draftPaymentDay = 1
        draftReminderEnabled = false
    }

    private func makeDraft() throws -> CreditDraft {
        CreditDraft(
            memberId: draftMemberId,
            title: draftTitle,
            totalAmount: Self.decimal(from: draftTotalAmount),
            downPayment: Self.decimal(from: draftDownPayment),
            monthlyPayment: Self.decimal(from: draftMonthlyPayment),
            usesCalculatedMonthlyPayment: draftUsesCalculatedMonthlyPayment,
            currencyCode: draftCurrencyCode,
            termMonths: draftTermMonths,
            startMonth: try YearMonth(year: draftStartYear, month: draftStartMonth),
            paymentDay: draftPaymentDay,
            reminderEnabled: draftReminderEnabled
        )
    }

    private func message(for error: Error) -> String {
        switch error as? CreditUseCaseError {
        case .memberRequired?:
            return "Выберите участника."
        case .memberNotFound?:
            return "Участник не найден."
        case .creditNotFound?:
            return "Кредит не найден."
        case .emptyTitle?:
            return "Название кредита не может быть пустым."
        case .invalidAmount?:
            return "Проверьте суммы кредита."
        case .downPaymentExceedsTotalAmount?:
            return "Первый взнос не может быть больше суммы кредита."
        case .invalidTermMonths?:
            return "Срок должен быть больше нуля."
        case .invalidPaymentDay?:
            return "День платежа должен быть от 1 до 31."
        case .paidPaymentsRequireConfirmation?:
            return "Изменение кредита с оплаченными платежами требует подтверждения."
        case nil:
            return "Не удалось сохранить кредит."
        }
    }

    private static func decimal(from text: String) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func format(_ decimal: Decimal) -> String {
        NSDecimalNumber(decimal: decimal).stringValue
    }
}
