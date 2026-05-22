import SwiftUI
import SwiftData

struct IncomeView: View {
    @ObservedObject var viewModel: IncomeViewModel
    let useCase: IncomeUseCase

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .noMembers:
                ContentUnavailableView {
                    Label("Нет участников", systemImage: "person.2")
                } description: {
                    Text("Сначала добавьте участника семьи.")
                }
            case .empty(let members):
                ContentUnavailableView {
                    Label("Нет доходов", systemImage: "banknote")
                } description: {
                    Text("Добавьте зарплату, премию или другой доход.")
                } actions: {
                    Button("Добавить") {
                        viewModel.startCreate(members: members)
                    }
                }
            case .loaded(let incomes, let members):
                incomeList(incomes: incomes, members: members)
            case .editing(let item, let members):
                incomeForm(item: item, members: members)
            case .overrides(let income, let overrides):
                overridesList(income: income, overrides: overrides)
            case .editingOverride(let income, let override):
                overrideForm(income: income, override: override)
            case .confirmDelete(let income):
                deleteConfirmation(income: income)
            case .error(let message):
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Доходы")
        .toolbar {
            toolbarContent
        }
        .task {
            if viewModel.state == .idle {
                viewModel.load(useCase: useCase)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        switch viewModel.state {
        case .empty(let members), .loaded(_, let members):
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.startCreate(members: members)
                } label: {
                    Image(systemName: "plus")
                }
            }
        default:
            ToolbarItem(placement: .topBarTrailing) {
                EmptyView()
            }
        }
    }

    private func incomeList(incomes: [IncomeListItem], members: [FamilyMemberListItem]) -> some View {
        List {
            ForEach(incomes) { income in
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        viewModel.startEdit(income, members: members)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(income.title ?? income.category.title)
                                .font(.headline)
                            Text("\(income.memberName) · \(income.amount.displayText) · \(income.recurrence.title)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(income.periodText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if income.recurrence == .monthly {
                        Button("Изменения по месяцам") {
                            viewModel.showOverrides(for: income, useCase: useCase)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                if let index = offsets.first {
                    viewModel.requestDelete(incomes[index])
                }
            }
        }
    }

    private func incomeForm(item: IncomeListItem?, members: [FamilyMemberListItem]) -> some View {
        Form {
            Picker("Участник", selection: $viewModel.draftMemberId) {
                ForEach(members) { member in
                    Text(member.name).tag(Optional(member.id))
                }
            }

            Picker("Категория", selection: $viewModel.draftCategory) {
                ForEach(IncomeCategory.allCases, id: \.self) { category in
                    Text(category.title).tag(category)
                }
            }

            TextField("Название", text: $viewModel.draftTitle)
            TextField("Сумма", text: $viewModel.draftAmount)
                .keyboardType(.decimalPad)

            Picker("Повторяемость", selection: $viewModel.draftRecurrence) {
                ForEach(IncomeRecurrence.allCases, id: \.self) { recurrence in
                    Text(recurrence.title).tag(recurrence)
                }
            }

            monthFields(title: "Начало", year: $viewModel.draftStartYear, month: $viewModel.draftStartMonth)

            if viewModel.draftRecurrence == .monthly {
                Toggle("Есть месяц окончания", isOn: $viewModel.draftHasEndMonth)
                if viewModel.draftHasEndMonth {
                    monthFields(title: "Окончание", year: $viewModel.draftEndYear, month: $viewModel.draftEndMonth)
                }
            }

            Button("Сохранить") {
                viewModel.saveIncome(currentItem: item, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancel(useCase: useCase)
            }
        }
    }

    private func overridesList(income: IncomeListItem, overrides: [IncomeOverrideListItem]) -> some View {
        List {
            if overrides.isEmpty {
                Text("Нет изменений по месяцам")
                    .foregroundStyle(.secondary)
            }

            ForEach(overrides) { override in
                Button {
                    viewModel.startEditOverride(override, income: income)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(override.month.displayText): \(override.amount.displayText)")
                        if let note = override.note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                if let index = offsets.first {
                    viewModel.deleteOverride(overrides[index], income: income, useCase: useCase)
                }
            }
        }
        .toolbar {
            Button {
                viewModel.startCreateOverride(for: income)
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func overrideForm(income: IncomeListItem, override: IncomeOverrideListItem?) -> some View {
        Form {
            monthFields(title: "Месяц", year: $viewModel.overrideYear, month: $viewModel.overrideMonth)
            TextField("Сумма", text: $viewModel.overrideAmount)
                .keyboardType(.decimalPad)
            TextField("Заметка", text: $viewModel.overrideNote)
            Button("Сохранить") {
                viewModel.saveOverride(income: income, currentItem: override, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.showOverrides(for: income, useCase: useCase)
            }
        }
    }

    private func deleteConfirmation(income: IncomeListItem) -> some View {
        VStack(spacing: 16) {
            Text("Удалить доход?")
                .font(.headline)
            Text(income.title ?? income.category.title)
                .foregroundStyle(.secondary)
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete(income, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancel(useCase: useCase)
            }
        }
        .padding()
    }

    private func monthFields(title: String, year: Binding<Int>, month: Binding<Int>) -> some View {
        Section(title) {
            Stepper("Год: \(year.wrappedValue)", value: year, in: 2020...2100)
            Picker("Месяц", selection: month) {
                ForEach(1...12, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
        }
    }
}

private extension IncomeCategory {
    static let allCases: [IncomeCategory] = [.salary, .bonus, .other]

    var title: String {
        switch self {
        case .salary:
            return "Зарплата"
        case .bonus:
            return "Премия"
        case .other:
            return "Прочее"
        }
    }
}

private extension IncomeRecurrence {
    static let allCases: [IncomeRecurrence] = [.monthly, .oneTime]

    var title: String {
        switch self {
        case .monthly:
            return "Ежемесячно"
        case .oneTime:
            return "Разово"
        }
    }
}

private extension IncomeListItem {
    var periodText: String {
        if let endMonth {
            return "\(startMonth.displayText) - \(endMonth.displayText)"
        }

        return recurrence == .monthly ? "С \(startMonth.displayText)" : startMonth.displayText
    }
}

private extension Money {
    var displayText: String {
        "\(NSDecimalNumber(decimal: amount).stringValue) \(currencyCode)"
    }
}

private extension YearMonth {
    var displayText: String {
        String(format: "%02d.%04d", month, year)
    }
}

#Preview {
    let container = try! PersistenceContainerFactory.makeModelContainer(inMemory: true)
    let context = ModelContext(container)
    IncomeView(
        viewModel: IncomeViewModel(),
        useCase: IncomeUseCase(
            incomeRepository: IncomeRepository(context: context),
            memberRepository: FamilyMemberRepository(context: context)
        )
    )
}
