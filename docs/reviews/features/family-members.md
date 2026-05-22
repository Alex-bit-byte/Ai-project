# Review: участники семьи

Дата: 2026-05-11  
Task: `docs/tasks/features/family-members.md`  
Spec: `docs/specs/features/family-members.md`  
Статус: implementation review, ожидает XCTest в полном Xcode

## Соответствие spec

- Участник имеет обязательное имя.
- Пустое после trimming имя не сохраняется.
- Одинаковые имена разрешены.
- Реализованы create, update, list и delete use cases.
- Удаление со связанными доходами или кредитами требует destructive confirmation.
- После destructive confirmation удаляются связанные incomes, income overrides, credits и payments.
- Добавлены list, empty, edit, validation/error и confirmation states.
- Участники представлены `FamilyMemberListItem`, пригодным для будущих owner picker flows.

## Найденные риски

- Cascade delete реализован в Data layer через UUID-ссылки и требует проверки на SwiftData in-memory tests в полном Xcode.
- UI confirmation реализован как отдельное состояние экрана, не системный `.confirmationDialog`; это проще для текущего MVP, но визуально стоит проверить в simulator.
- Очень длинное имя пока не ограничивается, потому что spec требует только непустое имя и разрешает одинаковые имена.

## Тестовые пробелы

- Tests добавлены, но не запущены через XCTest.
- Нет UI test для swipe delete/confirmation.

## Ручные проверки

- Выполнен `swiftc -typecheck` для Domain/Application/Presentation family members slice.
- Проверен `project.pbxproj`.
- Проверен shared scheme.

## Что перепроверить человеку

- Запустить:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Проверить создание, редактирование и удаление участника в simulator.
- После появления доходов/кредитов проверить destructive cascade delete на тестовых данных.
