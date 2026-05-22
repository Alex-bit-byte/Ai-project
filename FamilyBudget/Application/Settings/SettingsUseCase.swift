import Foundation

protocol SettingsRepositoryProtocol {
    func loadOrCreateDefault() throws -> AppSettings
    func save(_ settings: AppSettings) throws
}

protocol MoneyRecordStatusChecking {
    func hasMoneyRecords() throws -> Bool
}

struct SettingsViewData: Equatable {
    let currencyCode: String
    let canChangeCurrency: Bool
    let biometricLockEnabled: Bool
    let notificationsEnabled: Bool
    let appName: String
    let appVersion: String
    let storageNote: String
}

enum SettingsUseCaseError: Error, Equatable {
    case invalidCurrencyCode
    case currencyChangeBlocked
}

final class SettingsUseCase {
    private let settingsRepository: SettingsRepositoryProtocol
    private let moneyRecordChecker: MoneyRecordStatusChecking
    private let appName: String
    private let appVersion: String

    init(
        settingsRepository: SettingsRepositoryProtocol,
        moneyRecordChecker: MoneyRecordStatusChecking,
        appName: String = "Семейный бюджет",
        appVersion: String = "1.0"
    ) {
        self.settingsRepository = settingsRepository
        self.moneyRecordChecker = moneyRecordChecker
        self.appName = appName
        self.appVersion = appVersion
    }

    func load() throws -> SettingsViewData {
        let settings = try settingsRepository.loadOrCreateDefault()
        return try makeViewData(from: settings)
    }

    func updateCurrencyCode(_ currencyCode: String) throws -> SettingsViewData {
        let normalizedCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard isValidCurrencyCode(normalizedCode) else {
            throw SettingsUseCaseError.invalidCurrencyCode
        }

        var settings = try settingsRepository.loadOrCreateDefault()
        let hasMoneyRecords = try moneyRecordChecker.hasMoneyRecords()
        if settings.currencyCode != normalizedCode && hasMoneyRecords {
            throw SettingsUseCaseError.currencyChangeBlocked
        }

        settings.currencyCode = normalizedCode
        settings.updatedAt = Date()
        try settingsRepository.save(settings)
        return try makeViewData(from: settings)
    }

    func updateBiometricLockEnabled(_ isEnabled: Bool) throws -> SettingsViewData {
        var settings = try settingsRepository.loadOrCreateDefault()
        settings.biometricLockEnabled = isEnabled
        settings.updatedAt = Date()
        try settingsRepository.save(settings)
        return try makeViewData(from: settings)
    }

    func updateNotificationsEnabled(_ isEnabled: Bool) throws -> SettingsViewData {
        var settings = try settingsRepository.loadOrCreateDefault()
        settings.notificationsEnabled = isEnabled
        settings.updatedAt = Date()
        try settingsRepository.save(settings)
        return try makeViewData(from: settings)
    }

    private func makeViewData(from settings: AppSettings) throws -> SettingsViewData {
        SettingsViewData(
            currencyCode: settings.currencyCode,
            canChangeCurrency: try !moneyRecordChecker.hasMoneyRecords(),
            biometricLockEnabled: settings.biometricLockEnabled,
            notificationsEnabled: settings.notificationsEnabled,
            appName: appName,
            appVersion: appVersion,
            storageNote: "Данные хранятся локально на этом устройстве."
        )
    }

    private func isValidCurrencyCode(_ currencyCode: String) -> Bool {
        currencyCode.count == 3 && currencyCode.allSatisfy { $0.isLetter }
    }
}
