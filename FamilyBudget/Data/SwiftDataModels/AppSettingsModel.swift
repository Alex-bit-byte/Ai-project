import Foundation
import SwiftData

@Model
final class AppSettingsModel {
    @Attribute(.unique) var id: UUID
    var currencyCode: String
    var biometricLockEnabled: Bool
    var notificationsEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        currencyCode: String,
        biometricLockEnabled: Bool,
        notificationsEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.biometricLockEnabled = biometricLockEnabled
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
