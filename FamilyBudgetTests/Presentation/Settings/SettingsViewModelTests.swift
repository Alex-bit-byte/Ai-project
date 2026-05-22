import XCTest
@testable import FamilyBudget

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadPublishesLoadedState() {
        let viewModel = SettingsViewModel()
        let useCase = SettingsUseCase(
            settingsRepository: ViewModelSettingsRepository(),
            moneyRecordChecker: ViewModelMoneyRecordChecker(hasRecords: false)
        )

        viewModel.load(useCase: useCase)

        XCTAssertEqual(
            viewModel.state,
            .loaded(
                SettingsViewData(
                    currencyCode: "USD",
                    canChangeCurrency: true,
                    biometricLockEnabled: false,
                    notificationsEnabled: false,
                    appName: "Семейный бюджет",
                    appVersion: "1.0",
                    storageNote: "Данные хранятся локально на этом устройстве."
                )
            )
        )
    }

    func testBlockedCurrencyChangePublishesError() {
        let viewModel = SettingsViewModel()
        let useCase = SettingsUseCase(
            settingsRepository: ViewModelSettingsRepository(settings: AppSettings(currencyCode: "USD")),
            moneyRecordChecker: ViewModelMoneyRecordChecker(hasRecords: true)
        )

        viewModel.updateCurrencyCode("EUR", useCase: useCase)

        XCTAssertEqual(viewModel.state, .error("Валюту нельзя изменить после создания денежных записей."))
    }
}

private final class ViewModelSettingsRepository: SettingsRepositoryProtocol {
    private var settings: AppSettings?

    init(settings: AppSettings? = nil) {
        self.settings = settings
    }

    func loadOrCreateDefault() throws -> AppSettings {
        if let settings {
            return settings
        }

        let settings = AppSettings(currencyCode: "USD")
        self.settings = settings
        return settings
    }

    func save(_ settings: AppSettings) throws {
        self.settings = settings
    }
}

private struct ViewModelMoneyRecordChecker: MoneyRecordStatusChecking {
    let hasRecords: Bool

    func hasMoneyRecords() throws -> Bool {
        hasRecords
    }
}
