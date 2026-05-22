import Combine
import Foundation

@MainActor
final class FamilyMembersViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case loaded([FamilyMemberListItem])
        case editing(FamilyMemberListItem?)
        case confirmDelete(FamilyMemberListItem, destructive: Bool)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var draftName: String = ""

    func load(useCase: FamilyMemberUseCase) {
        state = .loading
        refresh(useCase: useCase)
    }

    func startCreate() {
        draftName = ""
        state = .editing(nil)
    }

    func startEdit(_ item: FamilyMemberListItem) {
        draftName = item.name
        state = .editing(item)
    }

    func saveEditing(currentItem: FamilyMemberListItem?, useCase: FamilyMemberUseCase) {
        performListAction {
            if let currentItem {
                return try useCase.updateMember(id: currentItem.id, name: draftName)
            }

            return try useCase.createMember(name: draftName)
        }
    }

    func requestDelete(_ item: FamilyMemberListItem, useCase: FamilyMemberUseCase) {
        do {
            let plan = try useCase.deletePlan(memberId: item.id)
            state = .confirmDelete(item, destructive: plan == .requiresDestructiveConfirmation)
        } catch {
            state = .error("Не удалось подготовить удаление участника.")
        }
    }

    func confirmDelete(_ item: FamilyMemberListItem, destructive: Bool, useCase: FamilyMemberUseCase) {
        performListAction {
            try useCase.deleteMember(id: item.id, confirmedDestructiveDelete: destructive)
        }
    }

    func cancelEditing(useCase: FamilyMemberUseCase) {
        refresh(useCase: useCase)
    }

    private func refresh(useCase: FamilyMemberUseCase) {
        performListAction {
            try useCase.listMembers()
        }
    }

    private func performListAction(_ action: () throws -> [FamilyMemberListItem]) {
        do {
            let items = try action()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch FamilyMemberUseCaseError.emptyName {
            state = .error("Имя участника не может быть пустым.")
        } catch FamilyMemberUseCaseError.destructiveConfirmationRequired {
            state = .error("Для удаления связанных данных нужно подтверждение.")
        } catch {
            state = .error("Не удалось сохранить изменения.")
        }
    }
}
