import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let useCase: SettingsUseCase

    private let currencyOptions = ["USD", "RUB", "TJS", "EUR"]

    var body: some View {
        Form {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded(let data):
                settingsContent(data)
            case .error(let message):
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Настройки")
        .task {
            if viewModel.state == .idle {
                viewModel.load(useCase: useCase)
            }
        }
    }

    @ViewBuilder
    private func settingsContent(_ data: SettingsViewData) -> some View {
        Section("Валюта") {
            Picker("Основная валюта", selection: currencyBinding(data)) {
                ForEach(currencyOptions, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .disabled(!data.canChangeCurrency)

            if !data.canChangeCurrency {
                Text("Валюта заблокирована после создания денежных записей.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Защита") {
            Toggle("Face ID / Touch ID", isOn: biometricBinding(data))
        }

        Section("Напоминания") {
            Toggle("Локальные уведомления", isOn: notificationsBinding(data))
        }

        Section("О приложении") {
            LabeledContent("Название", value: data.appName)
            LabeledContent("Версия", value: data.appVersion)
            Text(data.storageNote)
                .foregroundStyle(.secondary)
        }
    }

    private func currencyBinding(_ data: SettingsViewData) -> Binding<String> {
        Binding(
            get: { data.currencyCode },
            set: { viewModel.updateCurrencyCode($0, useCase: useCase) }
        )
    }

    private func biometricBinding(_ data: SettingsViewData) -> Binding<Bool> {
        Binding(
            get: { data.biometricLockEnabled },
            set: { viewModel.updateBiometricLockEnabled($0, useCase: useCase) }
        )
    }

    private func notificationsBinding(_ data: SettingsViewData) -> Binding<Bool> {
        Binding(
            get: { data.notificationsEnabled },
            set: { viewModel.updateNotificationsEnabled($0, useCase: useCase) }
        )
    }
}
