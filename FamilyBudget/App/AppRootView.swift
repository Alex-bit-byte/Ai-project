import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var familyMembersViewModel = FamilyMembersViewModel()

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Семья пока не настроена", systemImage: "person.2")
            } description: {
                Text("Начните с настроек, затем добавьте участников семьи.")
            } actions: {
                NavigationLink("Добавить участников") {
                    FamilyMembersView(viewModel: familyMembersViewModel, useCase: makeFamilyMemberUseCase())
                }
            }
            .navigationTitle("Семейный бюджет")
            .toolbar {
                NavigationLink {
                    CreditView(viewModel: CreditViewModel(), useCase: makeCreditUseCase())
                } label: {
                    Image(systemName: "creditcard")
                }
                NavigationLink {
                    IncomeView(viewModel: IncomeViewModel(), useCase: makeIncomeUseCase())
                } label: {
                    Image(systemName: "banknote")
                }
                NavigationLink {
                    SettingsView(viewModel: settingsViewModel, useCase: makeSettingsUseCase())
                } label: {
                    Image(systemName: "gearshape")
                }
                NavigationLink {
                    FamilyMembersView(viewModel: familyMembersViewModel, useCase: makeFamilyMemberUseCase())
                } label: {
                    Image(systemName: "person.2")
                }
            }
        }
    }

    private func makeSettingsUseCase() -> SettingsUseCase {
        SettingsUseCase(
            settingsRepository: AppSettingsRepository(context: modelContext),
            moneyRecordChecker: MoneyRecordStatusRepository(context: modelContext)
        )
    }

    private func makeFamilyMemberUseCase() -> FamilyMemberUseCase {
        FamilyMemberUseCase(
            repository: FamilyMemberRepository(context: modelContext),
            relatedDataHandler: FamilyMemberRelatedDataRepository(context: modelContext)
        )
    }

    private func makeIncomeUseCase() -> IncomeUseCase {
        IncomeUseCase(
            incomeRepository: IncomeRepository(context: modelContext),
            memberRepository: FamilyMemberRepository(context: modelContext)
        )
    }

    private func makeCreditUseCase() -> CreditUseCase {
        CreditUseCase(
            creditRepository: CreditRepository(context: modelContext),
            memberRepository: FamilyMemberRepository(context: modelContext)
        )
    }
}

#Preview {
    AppRootView()
        .modelContainer(try! PersistenceContainerFactory.makeModelContainer(inMemory: true))
}
