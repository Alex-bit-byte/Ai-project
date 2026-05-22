import SwiftUI

struct FamilyMembersView: View {
    @ObservedObject var viewModel: FamilyMembersViewModel
    let useCase: FamilyMemberUseCase

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .empty:
                ContentUnavailableView {
                    Label("Нет участников", systemImage: "person.crop.circle.badge.plus")
                } description: {
                    Text("Добавьте первого участника семьи.")
                } actions: {
                    Button("Добавить") {
                        viewModel.startCreate()
                    }
                }
            case .loaded(let items):
                List {
                    ForEach(items) { item in
                        Button {
                            viewModel.startEdit(item)
                        } label: {
                            Text(item.name)
                        }
                    }
                    .onDelete { offsets in
                        if let index = offsets.first {
                            viewModel.requestDelete(items[index], useCase: useCase)
                        }
                    }
                }
            case .editing(let item):
                memberForm(item)
            case .confirmDelete(let item, let destructive):
                deleteConfirmation(item: item, destructive: destructive)
            case .error(let message):
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Участники")
        .toolbar {
            Button {
                viewModel.startCreate()
            } label: {
                Image(systemName: "plus")
            }
        }
        .task {
            if viewModel.state == .idle {
                viewModel.load(useCase: useCase)
            }
        }
    }

    private func memberForm(_ item: FamilyMemberListItem?) -> some View {
        Form {
            TextField("Имя", text: $viewModel.draftName)
            Button("Сохранить") {
                viewModel.saveEditing(currentItem: item, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancelEditing(useCase: useCase)
            }
        }
    }

    private func deleteConfirmation(item: FamilyMemberListItem, destructive: Bool) -> some View {
        VStack(spacing: 16) {
            Text(destructive ? "Удалить участника и связанные данные?" : "Удалить участника?")
                .font(.headline)
            Text(destructive ? "Будут удалены доходы, кредиты и платежи участника." : item.name)
                .foregroundStyle(.secondary)
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete(item, destructive: destructive, useCase: useCase)
            }
            Button("Отмена", role: .cancel) {
                viewModel.cancelEditing(useCase: useCase)
            }
        }
        .padding()
    }
}
