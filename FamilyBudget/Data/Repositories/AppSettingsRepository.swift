import Foundation
import SwiftData

final class AppSettingsRepository: SettingsRepositoryProtocol {
    static let defaultCurrencyCode = "USD"

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() throws -> AppSettings? {
        try context.fetch(FetchDescriptor<AppSettingsModel>())
            .sorted { $0.createdAt < $1.createdAt }
            .first
            .map(PersistenceMapper.domain)
    }

    func loadOrCreateDefault() throws -> AppSettings {
        if let existing = try load() {
            return existing
        }

        let settings = AppSettings(currencyCode: Self.defaultCurrencyCode)
        context.insert(PersistenceMapper.model(from: settings))
        try context.save()
        return settings
    }

    func save(_ settings: AppSettings) throws {
        if let existing = try model(id: settings.id) {
            existing.currencyCode = settings.currencyCode
            existing.biometricLockEnabled = settings.biometricLockEnabled
            existing.notificationsEnabled = settings.notificationsEnabled
            existing.updatedAt = settings.updatedAt
        } else {
            context.insert(PersistenceMapper.model(from: settings))
        }

        try context.save()
    }

    private func model(id: UUID) throws -> AppSettingsModel? {
        try context.fetch(FetchDescriptor<AppSettingsModel>())
            .first { $0.id == id }
    }
}
