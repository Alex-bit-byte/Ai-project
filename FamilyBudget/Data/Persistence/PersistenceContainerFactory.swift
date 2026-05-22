import SwiftData

enum PersistenceContainerFactory {
    static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            AppSettingsModel.self,
            FamilyMemberModel.self,
            IncomeModel.self,
            IncomeOverrideModel.self,
            CreditModel.self,
            CreditPaymentModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
