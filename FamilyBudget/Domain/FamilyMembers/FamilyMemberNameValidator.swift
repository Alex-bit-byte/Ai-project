import Foundation

enum FamilyMemberNameValidator {
    static func normalizedName(_ name: String) throws -> String {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw FamilyMemberValidationError.emptyName
        }

        return normalized
    }
}

enum FamilyMemberValidationError: Error, Equatable {
    case emptyName
}
