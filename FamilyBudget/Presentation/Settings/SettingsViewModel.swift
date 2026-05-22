import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(SettingsViewData)
        case error(String)
    }

    @Published private(set) var state: State = .idle

    func load(useCase: SettingsUseCase) {
        state = .loading
        perform {
            try useCase.load()
        }
    }

    func updateCurrencyCode(_ currencyCode: String, useCase: SettingsUseCase) {
        perform {
            try useCase.updateCurrencyCode(currencyCode)
        }
    }

    func updateBiometricLockEnabled(_ isEnabled: Bool, useCase: SettingsUseCase) {
        perform {
            try useCase.updateBiometricLockEnabled(isEnabled)
        }
    }

    func updateNotificationsEnabled(_ isEnabled: Bool, useCase: SettingsUseCase) {
        perform {
            try useCase.updateNotificationsEnabled(isEnabled)
        }
    }

    private func perform(_ action: () throws -> SettingsViewData) {
        do {
            state = .loaded(try action())
        } catch SettingsUseCaseError.invalidCurrencyCode {
            state = .error("Код валюты должен состоять из трех букв.")
        } catch SettingsUseCaseError.currencyChangeBlocked {
            state = .error("Валюту нельзя изменить после создания денежных записей.")
        } catch {
            state = .error("Не удалось загрузить настройки.")
        }
    }
}
