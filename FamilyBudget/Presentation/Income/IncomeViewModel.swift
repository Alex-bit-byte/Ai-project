import Combine
import Foundation

@MainActor
final class IncomeViewModel: ObservableObject {
    private static let defaultCurrencyCode = "USD"

    enum State: Equatable {
        case idle
        case loading
        case noMembers
        case empty(members: [FamilyMemberListItem])
        case loaded(incomes: [IncomeListItem], members: [FamilyMemberListItem])
        case editing(IncomeListItem?, members: [FamilyMemberListItem])
        case overrides(income: IncomeListItem, overrides: [IncomeOverrideListItem])
        case editingOverride(IncomeListItem, IncomeOverrideListItem?)
        case confirmDelete(IncomeListItem)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var draftMemberId: UUID?
    @Published var draftCategory: IncomeCategory = .salary
    @Published var draftTitle: String = ""
    @Published var draftAmount: String = ""
    @Published var draftRecurrence: IncomeRecurrence = .monthly
    @Published var draftStartYear: Int = Calendar.current.component(.year, from: Date())
    @Published var draftStartMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var draftHasEndMonth: Bool = false
    @Published var draftEndYear: Int = Calendar.current.component(.year, from: Date())
    @Published var draftEndMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var draftCurrencyCode: String = defaultCurrencyCode
    @Published var overrideYear: Int = Calendar.current.component(.year, from: Date())
    @Published var overrideMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var overrideAmount: String = ""
    @Published var overrideNote: String = ""

    func load(useCase: IncomeUseCase) {
        state = .loading
        refresh(useCase: useCase)
    }

    func startCreate(members: [FamilyMemberListItem]) {
        resetIncomeDraft(member: members.first)
        state = .editing(nil, members: members)
    }

    func startEdit(_ income: IncomeListItem, members: [FamilyMemberListItem]) {
        draftMemberId = income.memberId
        draftCategory = income.category
        draftTitle = income.title ?? ""
        draftAmount = Self.format(income.amount.amount)
        draftCurrencyCode = income.amount.currencyCode
        draftRecurrence = income.recurrence
        draftStartYear = income.startMonth.year
        draftStartMonth = income.startMonth.month
        draftHasEndMonth = income.endMonth != nil
        draftEndYear = income.endMonth?.year ?? income.startMonth.year
        draftEndMonth = income.endMonth?.month ?? income.startMonth.month
        state = .editing(income, members: members)
    }

    func saveIncome(currentItem: IncomeListItem?, useCase: IncomeUseCase) {
        do {
            let draft = try makeIncomeDraft()
            let items: [IncomeListItem]
            if let currentItem {
                items = try useCase.updateIncome(id: currentItem.id, draft: draft)
            } else {
                items = try useCase.createIncome(draft)
            }
            setListState(incomes: items, members: try useCase.listMembers())
        } catch {
            state = .error(message(for: error))
        }
    }

    func requestDelete(_ income: IncomeListItem) {
        state = .confirmDelete(income)
    }

    func confirmDelete(_ income: IncomeListItem, useCase: IncomeUseCase) {
        do {
            let items = try useCase.deleteIncome(id: income.id)
            setListState(incomes: items, members: try useCase.listMembers())
        } catch {
            state = .error(message(for: error))
        }
    }

    func showOverrides(for income: IncomeListItem, useCase: IncomeUseCase) {
        do {
            state = .overrides(income: income, overrides: try useCase.listOverrides(incomeId: income.id))
        } catch {
            state = .error("Не удалось загрузить изменения по месяцам.")
        }
    }

    func startCreateOverride(for income: IncomeListItem) {
        overrideYear = income.startMonth.year
        overrideMonth = income.startMonth.month
        overrideAmount = Self.format(income.amount.amount)
        overrideNote = ""
        state = .editingOverride(income, nil)
    }

    func startEditOverride(_ override: IncomeOverrideListItem, income: IncomeListItem) {
        overrideYear = override.month.year
        overrideMonth = override.month.month
        overrideAmount = Self.format(override.amount.amount)
        overrideNote = override.note ?? ""
        state = .editingOverride(income, override)
    }

    func saveOverride(income: IncomeListItem, currentItem: IncomeOverrideListItem?, useCase: IncomeUseCase) {
        do {
            let draft = try makeOverrideDraft(income: income)
            let overrides: [IncomeOverrideListItem]
            if let currentItem {
                overrides = try useCase.updateOverride(id: currentItem.id, draft: draft)
            } else {
                overrides = try useCase.createOverride(draft)
            }
            state = .overrides(income: income, overrides: overrides)
        } catch {
            state = .error(message(for: error))
        }
    }

    func deleteOverride(_ override: IncomeOverrideListItem, income: IncomeListItem, useCase: IncomeUseCase) {
        do {
            state = .overrides(income: income, overrides: try useCase.deleteOverride(id: override.id, incomeId: income.id))
        } catch {
            state = .error("Не удалось удалить изменение по месяцу.")
        }
    }

    func cancel(useCase: IncomeUseCase) {
        refresh(useCase: useCase)
    }

    private func refresh(useCase: IncomeUseCase) {
        do {
            let members = try useCase.listMembers()
            guard !members.isEmpty else {
                state = .noMembers
                return
            }

            setListState(incomes: try useCase.listIncomes(), members: members)
        } catch {
            state = .error("Не удалось загрузить доходы.")
        }
    }

    private func setListState(incomes: [IncomeListItem], members: [FamilyMemberListItem]) {
        state = incomes.isEmpty ? .empty(members: members) : .loaded(incomes: incomes, members: members)
    }

    private func resetIncomeDraft(member: FamilyMemberListItem?) {
        let now = Date()
        let calendar = Calendar.current
        draftMemberId = member?.id
        draftCategory = .salary
        draftTitle = ""
        draftAmount = ""
        draftCurrencyCode = Self.defaultCurrencyCode
        draftRecurrence = .monthly
        draftStartYear = calendar.component(.year, from: now)
        draftStartMonth = calendar.component(.month, from: now)
        draftHasEndMonth = false
        draftEndYear = draftStartYear
        draftEndMonth = draftStartMonth
    }

    private func makeIncomeDraft() throws -> IncomeDraft {
        let startMonth = try YearMonth(year: draftStartYear, month: draftStartMonth)
        let endMonth = draftHasEndMonth ? try YearMonth(year: draftEndYear, month: draftEndMonth) : nil
        return IncomeDraft(
            memberId: draftMemberId,
            category: draftCategory,
            title: draftTitle,
            amount: Self.decimal(from: draftAmount),
            currencyCode: draftCurrencyCode,
            recurrence: draftRecurrence,
            startMonth: startMonth,
            endMonth: endMonth
        )
    }

    private func makeOverrideDraft(income: IncomeListItem) throws -> IncomeOverrideDraft {
        IncomeOverrideDraft(
            incomeId: income.id,
            month: try YearMonth(year: overrideYear, month: overrideMonth),
            amount: Self.decimal(from: overrideAmount),
            currencyCode: income.amount.currencyCode,
            note: overrideNote
        )
    }

    private func message(for error: Error) -> String {
        switch error as? IncomeUseCaseError {
        case .memberRequired?:
            return "Выберите участника."
        case .memberNotFound?:
            return "Участник не найден."
        case .incomeNotFound?:
            return "Доход не найден."
        case .invalidAmount?:
            return "Сумма должна быть больше нуля."
        case .invalidPeriod?:
            return "Месяц окончания не может быть раньше начала."
        case .overrideOutsideIncomePeriod?:
            return "Месяц изменения вне периода дохода."
        case .overrideOnlyForMonthlyIncome?:
            return "Изменение по месяцу доступно только для регулярного дохода."
        case nil:
            return "Не удалось сохранить доход."
        }
    }

    private static func decimal(from text: String) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func format(_ decimal: Decimal) -> String {
        NSDecimalNumber(decimal: decimal).stringValue
    }
}
