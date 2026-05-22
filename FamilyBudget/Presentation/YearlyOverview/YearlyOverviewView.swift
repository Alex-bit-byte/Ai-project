import SwiftUI
import SwiftData

struct YearlyOverviewView: View {
    @ObservedObject var viewModel: YearlyOverviewViewModel
    let useCase: YearlyOverviewUseCase

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .noMembers:
                ContentUnavailableView {
                    Label("Нет участников", systemImage: "person.2")
                } description: {
                    Text("Добавьте участников семьи, чтобы увидеть годовую сводку.")
                }
            case .empty(let overview):
                overviewList(overview)
            case .loaded(let overview):
                overviewList(overview)
            case .monthDetailsPlaceholder(let summary):
                monthPlaceholder(summary)
            case .error(let message):
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Год")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.previousYear(useCase: useCase)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Text("\(viewModel.selectedYear)")
                    .monospacedDigit()
                Button {
                    viewModel.nextYear(useCase: useCase)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .task {
            if viewModel.state == .idle {
                viewModel.load(useCase: useCase)
            }
        }
    }

    private func overviewList(_ overview: YearlyOverviewState) -> some View {
        List {
            ForEach(overview.summaries) { summary in
                Button {
                    viewModel.showMonthDetails(summary)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(summary.month.monthTitle)
                                .font(.headline)
                            Spacer()
                            Text(summary.creditLoadLevel.title)
                                .font(.caption)
                                .foregroundStyle(summary.creditLoadLevel.color)
                        }

                        HStack {
                            metric(title: "Доход", value: summary.familyIncome.displayText)
                            metric(title: "Кредиты", value: summary.creditLoad.displayText)
                            metric(title: "Остаток", value: summary.remaining.displayText)
                        }

                        HStack {
                            Text(summary.creditLoadPercentage.displayText)
                            Spacer()
                            Text(summary.paymentStatus.title)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func monthPlaceholder(_ summary: MonthlyBudgetSummary) -> some View {
        VStack(spacing: 16) {
            Text(summary.month.monthTitle)
                .font(.headline)
            Text("Детали месяца будут реализованы в следующем slice.")
                .foregroundStyle(.secondary)
            Button("Назад") {
                viewModel.closeMonthDetails(useCase: useCase)
            }
        }
        .padding()
    }
}

private extension CreditLoadLevel {
    var title: String {
        switch self {
        case .noIncome:
            return "нет дохода"
        case .normal:
            return "норма"
        case .warning:
            return "внимание"
        case .high:
            return "высокая"
        }
    }

    var color: Color {
        switch self {
        case .noIncome:
            return .secondary
        case .normal:
            return .green
        case .warning:
            return .yellow
        case .high:
            return .red
        }
    }
}

private extension PaymentMonthStatus {
    var title: String {
        switch self {
        case .noPayments:
            return "нет платежей"
        case .scheduled:
            return "запланировано"
        case .paid:
            return "оплачено"
        case .overdue:
            return "есть просрочка"
        }
    }
}

private extension CreditLoadPercentage {
    var displayText: String {
        switch self {
        case .notApplicable:
            return "нагрузка: нет дохода"
        case .value(let value):
            return "нагрузка: \(NSDecimalNumber(decimal: value).stringValue)%"
        }
    }
}

private extension Money {
    var displayText: String {
        "\(NSDecimalNumber(decimal: amount).stringValue) \(currencyCode)"
    }
}

private extension YearMonth {
    var monthTitle: String {
        String(format: "%02d.%04d", month, year)
    }
}

#Preview {
    let container = try! PersistenceContainerFactory.makeModelContainer(inMemory: true)
    let context = ModelContext(container)
    YearlyOverviewView(
        viewModel: YearlyOverviewViewModel(),
        useCase: YearlyOverviewUseCase(
            memberRepository: FamilyMemberRepository(context: context),
            incomeRepository: IncomeRepository(context: context),
            creditRepository: CreditRepository(context: context),
            settingsRepository: AppSettingsRepository(context: context)
        )
    )
}
