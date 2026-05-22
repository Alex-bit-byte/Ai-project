import XCTest
@testable import FamilyBudget

final class SettingsUseCaseTests: XCTestCase {
    func testLoadCreatesDefaultSettings() throws {
        let repository = InMemorySettingsRepository()
        let useCase = SettingsUseCase(settingsRepository: repository, moneyRecordChecker: InMemoryMoneyRecordChecker(hasRecords: false))

        let data = try useCase.load()

        XCTAssertEqual(data.currencyCode, "USD")
        XCTAssertTrue(data.canChangeCurrency)
    }

    func testCurrencyChangeAllowedBeforeMoneyRecords() throws {
        let repository = InMemorySettingsRepository()
        let useCase = SettingsUseCase(settingsRepository: repository, moneyRecordChecker: InMemoryMoneyRecordChecker(hasRecords: false))

        let data = try useCase.updateCurrencyCode("eur")

        XCTAssertEqual(data.currencyCode, "EUR")
        XCTAssertEqual(try repository.loadOrCreateDefault().currencyCode, "EUR")
    }

    func testCurrencyChangeBlockedAfterMoneyRecords() throws {
        let repository = InMemorySettingsRepository(settings: AppSettings(currencyCode: "USD"))
        let useCase = SettingsUseCase(settingsRepository: repository, moneyRecordChecker: InMemoryMoneyRecordChecker(hasRecords: true))

        XCTAssertThrowsError(try useCase.updateCurrencyCode("EUR")) { error in
            XCTAssertEqual(error as? SettingsUseCaseError, .currencyChangeBlocked)
        }
    }

    func testInvalidCurrencyCodeThrows() {
        let repository = InMemorySettingsRepository()
        let useCase = SettingsUseCase(settingsRepository: repository, moneyRecordChecker: InMemoryMoneyRecordChecker(hasRecords: false))

        XCTAssertThrowsError(try useCase.updateCurrencyCode("US")) { error in
            XCTAssertEqual(error as? SettingsUseCaseError, .invalidCurrencyCode)
        }
    }
}

private final class InMemorySettingsRepository: SettingsRepositoryProtocol {
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

private struct InMemoryMoneyRecordChecker: MoneyRecordStatusChecking {
    let hasRecords: Bool

    func hasMoneyRecords() throws -> Bool {
        hasRecords
    }
}
