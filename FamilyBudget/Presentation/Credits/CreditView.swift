import SwiftUI
import SwiftData

struct CreditView: View {
    @ObservedObject var viewModel: CreditViewModel
    let useCase: CreditUseCase

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
                    Label("Нет кредитов", systemImage: "creditcard")
                } description: {
                    Text("Добавьте кредит или рассрочку.")
                } actions: {
                    Button("Добавить") {
                        viewModel.startCreate(members: members)
                    }
                }
            case .loaded(let credits, let members):
                creditList(credits: credits, members: members)
            case .editing(let item, let members):
                creditForm(item: item, members: members)
            case .payments(let credit, let payments):
                paymentSchedule(credit: credit, payments: payments)
            case .confirmDelete(let credit):
                deleteConfirmation(credit: credit)
            case .confirmPaidPaymentUpdate(let credit):
                paidPaymentUpdateConfirmation(credit: credit)
            case .error(let message):
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Кредиты")
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

    private func creditList(credits: [CreditListItem], members: [FamilyMemberListItem]) -> some View {
        List {
            ForEach(credits) { credit in
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        viewModel.startEdit(credit, members: members)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credit.title)
                                .font(.headline)
                            Text("\(credit.memberName) · \(credit.monthlyPayment.displayText) / мес.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(credit.startMonth.displayText) - \(credit.endMonth.displayText) · день \(credit.paymentDay)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("График платежей") {
                        viewModel.showPayments(for: credit, useCase: useCase)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                if let index = offsets.first {
                    viewModel.requestDelete(credits[index])
                }
            }
        }
    }

    private func creditForm(item: CreditListItem?, members: [FamilyMemberListItem]) -> some View {
        Form {
            Picker("Участник", selection: $viewModel.draftMemberId) {
                ForEach(members) { member in
                    Text(member.name).tag(Optional(member.id))
                }
            }

            TextField("Название", text: $viewModel.draftTitle)
            TextField("Сумма кредита", text: $viewModel.draftTotalAmount)
                .keyboardType(.decimalPad)
                .onChange(of: viewModel.draftTotalAmount) { _, _ in viewModel.updateCalculatedMonthlyPayment(useCase: useCase) }
            TextField("Первый взнос", text: $viewModel.draftDownPayment)
                .keyboardType(.decimalPad)
                .onChange(of: viewModel.draftDownPayment) { _, _ in viewModel.updateCalculatedMonthlyPayment(useCase: useCase) }

            Stepper("Срок: \(viewModel.draftTermMonths) мес.", value: $viewModel.draftTermMonths, in: 1...360)
                .onChange(of: viewModel.draftTermMonths) { _, _ in viewModel.updateCalculatedMonthlyPayment(useCase: useCase) }

            Toggle("Рассчитать платеж", isOn: $viewModel.draftUsesCalculatedMonthlyPayment)
                .onChange(of: viewModel.draftUsesCalculatedMonthlyPayment) { _, _ in viewModel.updateCalculatedMonthlyPayment(useCase: useCase) }
            TextField("Ежемесячный платеж", text: $viewModel.draftMonthlyPayment)
                .keyboardType(.decimalPad)
                .disabled(viewModel.draftUsesCalculatedMonthlyPayment)

            monthFields(title: "Начало", year: $viewModel.draftStartYear, month: $viewModel.draftStartMonth)
            Stepper("День платежа: \(viewModel.draftPaymentDay)", value: $viewModel.draftPaymentDay, in: 1...31)
            Toggle("Напоминания", isOn: $viewModel.draftReminderEnabled)

            Button("Сохранить") {
                viewModel.saveCredit(currentItem: item, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancel(useCase: useCase)
            }
        }
    }

    private func paymentSchedule(credit: CreditListItem, payments: [CreditPayment]) -> some View {
        List {
            ForEach(payments) { payment in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(payment.month.displayText): \(payment.amount.displayText)")
                    Text("\(payment.dueDate.formatted(date: .abbreviated, time: .omitted)) · \(payment.status.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbar {
            Button("Готово") {
                viewModel.cancel(useCase: useCase)
            }
        }
    }

    private func deleteConfirmation(credit: CreditListItem) -> some View {
        VStack(spacing: 16) {
            Text("Удалить кредит и платежи?")
                .font(.headline)
            Text(credit.title)
                .foregroundStyle(.secondary)
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete(credit, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancel(useCase: useCase)
            }
        }
        .padding()
    }

    private func paidPaymentUpdateConfirmation(credit: CreditListItem) -> some View {
        VStack(spacing: 16) {
            Text("Изменить кредит с оплаченными платежами?")
                .font(.headline)
            Text("Оплаченные платежи сохранятся, будущий график будет пересчитан.")
                .foregroundStyle(.secondary)
            Button("Изменить", role: .destructive) {
                viewModel.confirmPaidPaymentUpdate(credit, useCase: useCase)
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

private extension PaymentStatus {
    var title: String {
        switch self {
        case .scheduled:
            return "Запланирован"
        case .paid:
            return "Оплачен"
        case .skipped:
            return "Пропущен"
        }
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
    CreditView(
        viewModel: CreditViewModel(),
        useCase: CreditUseCase(
            creditRepository: CreditRepository(context: context),
            memberRepository: FamilyMemberRepository(context: context)
        )
    )
}
