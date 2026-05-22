import Foundation

struct AppSettings: Equatable, Identifiable {
    let id: UUID
    var currencyCode: String
    var biometricLockEnabled: Bool
    var notificationsEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        currencyCode: String,
        biometricLockEnabled: Bool = false,
        notificationsEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.biometricLockEnabled = biometricLockEnabled
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
