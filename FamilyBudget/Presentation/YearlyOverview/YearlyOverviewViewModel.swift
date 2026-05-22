import Combine
import Foundation

@MainActor
final class YearlyOverviewViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case noMembers(year: Int)
        case empty(YearlyOverviewState)
        case loaded(YearlyOverviewState)
        case monthDetailsPlaceholder(MonthlyBudgetSummary)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var selectedYear: Int = Calendar.current.component(.year, from: Date())

    func load(useCase: YearlyOverviewUseCase) {
        state = .loading
        refresh(useCase: useCase)
    }

    func previousYear(useCase: YearlyOverviewUseCase) {
        selectedYear -= 1
        refresh(useCase: useCase)
    }

    func nextYear(useCase: YearlyOverviewUseCase) {
        selectedYear += 1
        refresh(useCase: useCase)
    }

    func showMonthDetails(_ summary: MonthlyBudgetSummary) {
        state = .monthDetailsPlaceholder(summary)
    }

    func closeMonthDetails(useCase: YearlyOverviewUseCase) {
        refresh(useCase: useCase)
    }

    private func refresh(useCase: YearlyOverviewUseCase) {
        do {
            let overview = try useCase.overview(year: selectedYear)
            if !overview.hasMembers {
                state = .noMembers(year: selectedYear)
            } else if !overview.hasFinancialData {
                state = .empty(overview)
            } else {
                state = .loaded(overview)
            }
        } catch {
            state = .error("Не удалось рассчитать годовую сводку.")
        }
    }
}
