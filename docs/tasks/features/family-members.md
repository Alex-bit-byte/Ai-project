# Задача: участники семьи

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode  
Spec: `docs/specs/features/family-members.md`  
Зависит от:

- `docs/tasks/foundation/domain-core.md`
- `docs/tasks/foundation/local-persistence.md`
- `docs/tasks/features/onboarding-settings.md`

## Конкретный результат

Пользователь может создавать, редактировать, просматривать и удалять участников семьи.

## Scope

- CRUD use cases для `FamilyMember`.
- Validation имени.
- Список участников.
- Форма создания/редактирования.
- Подтверждение удаления.
- Destructive confirmation при связанных доходах или кредитах.

## Out of scope

- Создание доходов.
- Создание кредитов.
- Расчеты бюджета.
- Импорт контактов.
- Уникальность имен участников.

## Предполагаемые области кода

- `FamilyBudget/Domain/FamilyMembers/`
- `FamilyBudget/Application/FamilyMembers/`
- `FamilyBudget/Presentation/FamilyMembers/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudgetTests/Domain/FamilyMembers/`
- `FamilyBudgetTests/Application/FamilyMembers/`

## Шаги реализации

1. Реализовать validation имени участника.
2. Реализовать use cases create/update/delete/list.
3. Реализовать проверку связанных данных перед удалением.
4. Реализовать list view и member form.
5. Реализовать confirmation dialogs.
6. Добавить tests для validation, use cases и view states.

## Тесты

- Нельзя сохранить пустое имя.
- Одинаковые имена разрешены.
- Create/update/delete member.
- Delete confirmation state при связанных данных.
- Empty и non-empty list states.

## Definition of Done

- Участник доступен для выбора в будущих income/credit flows.
- Удаление со связанными данными требует явного подтверждения.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.

## Результат выполнения

Дата выполнения: 2026-05-11

Реализовано:

- Validation имени участника с trimming whitespace и запретом пустого имени.
- `FamilyMemberUseCase` для list/create/update/delete.
- Проверка связанных доходов/кредитов перед удалением.
- Cascade delete связанных incomes, income overrides, credits и payments после destructive confirmation.
- `FamilyMembersViewModel` со states empty/list/edit/confirm/error.
- SwiftUI `FamilyMembersView` со списком, формой создания/редактирования и экраном подтверждения удаления.
- Переход к участникам с первого empty state приложения.
- Unit tests для validation и use case сценариев.

Выполненные проверки:

- `swiftc -typecheck` для Domain + Application + Presentation slice — успешно.
- `plutil -lint FamilyBudget.xcodeproj/project.pbxproj` — успешно.
- `xmllint --noout FamilyBudget.xcodeproj/xcshareddata/xcschemes/FamilyBudget.xcscheme` — успешно.

Не выполнено:

- XCTest и full app build не запущены, потому что активный developer directory указывает на Command Line Tools: `/Library/Developer/CommandLineTools`, а не на полный Xcode.

Review note: `docs/reviews/features/family-members.md`
