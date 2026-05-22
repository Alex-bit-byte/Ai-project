# Задача: базовая структура Xcode-проекта

Дата: 2026-05-11  
Статус: implemented, ожидает проверки в полном Xcode  
Spec: `docs/specs/foundation/project-foundation.md`

## Конкретный результат

Создан iOS 17+ SwiftUI Xcode-проект с базовой layered monolith структурой и тестовым target.

## Scope

- Создать iOS app project.
- Настроить iOS 17+ deployment target.
- Создать папки/группы `App`, `Domain`, `Application`, `Data`, `Presentation`.
- Создать базовый `FamilyBudgetApp`.
- Создать общий unit test target.
- Добавить пустые директории для будущих vertical slices.

## Out of scope

- Feature UI.
- SwiftData schema.
- Domain calculations.
- LocalAuthentication.
- UserNotifications.
- Внешние зависимости.

## Предполагаемые области кода

- `FamilyBudget/App/`
- `FamilyBudget/Domain/`
- `FamilyBudget/Application/`
- `FamilyBudget/Data/`
- `FamilyBudget/Presentation/`
- `FamilyBudgetTests/`

## Шаги реализации

1. Создать Xcode-проект SwiftUI iOS app.
2. Установить minimum deployment target iOS 17+.
3. Создать базовую структуру слоев.
4. Добавить minimal app root view без product features.
5. Создать unit test target.
6. Зафиксировать команду локального build/test запуска.

## Тесты

- Build app target.
- Запустить пустой или smoke unit test target.

## Definition of Done

- Проект открывается и собирается.
- Приложение запускается на iOS 17+ simulator.
- Test target запускается.
- Нет feature-кода вне согласованных feature tasks.
- Review note создана в `docs/reviews/`.

## Результат выполнения

Дата выполнения: 2026-05-11

Создан минимальный iOS 17+ SwiftUI Xcode-проект:

- `FamilyBudget.xcodeproj`;
- app target `FamilyBudget`;
- unit test target `FamilyBudgetTests`;
- shared scheme `FamilyBudget`;
- базовый entry point `FamilyBudget/App/FamilyBudgetApp.swift`;
- minimal root view `FamilyBudget/App/AppRootView.swift`;
- layered monolith структура `App`, `Domain`, `Application`, `Data`, `Presentation`;
- директории будущих vertical slices согласно архитектуре MVP.

Локальная команда для проверки после установки/выбора полного Xcode:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

Выполненные проверки:

- `plutil -lint FamilyBudget.xcodeproj/project.pbxproj` — успешно.
- Проверена файловая структура `FamilyBudget`, `FamilyBudgetTests`, `FamilyBudget.xcodeproj`.

Не выполнено:

- `xcodebuild -list -project FamilyBudget.xcodeproj` и build/test не запустились, потому что активный developer directory указывает на Command Line Tools: `/Library/Developer/CommandLineTools`, а не на полный Xcode.

Review note: `docs/reviews/foundation/project-setup.md`
