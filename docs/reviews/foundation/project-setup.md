# Review: базовая структура Xcode-проекта

Дата: 2026-05-11  
Task: `docs/tasks/foundation/project-setup.md`  
Spec: `docs/specs/foundation/project-foundation.md`  
Статус: implementation review, ожидает проверки в полном Xcode

## Соответствие spec

- Создан единый iOS SwiftUI Xcode-проект `FamilyBudget.xcodeproj`.
- Установлен deployment target iOS 17.0.
- Созданы слои `App`, `Domain`, `Application`, `Data`, `Presentation`.
- Создан app entry point в `FamilyBudget/App/FamilyBudgetApp.swift`.
- Добавлен minimal root view без feature-сценариев.
- Создан unit test target `FamilyBudgetTests` со smoke test.
- Внешние зависимости не добавлялись.

## Найденные риски

- Build/test не подтверждены, потому что в окружении активны только Command Line Tools. Для `xcodebuild` нужен полный Xcode.
- Bundle identifier `com.familybudget.app` временный и может потребовать замены перед реальной подписью приложения.
- Root view содержит только заглушку названия приложения; это не feature UI и должно быть заменено в рамках следующих согласованных feature tasks.

## Тестовые пробелы

- Unit test target создан, но фактический запуск тестов не выполнен из-за отсутствия полного Xcode.
- Simulator launch не проверен по той же причине.

## Ручные проверки

- Проверен синтаксис project file через `plutil -lint FamilyBudget.xcodeproj/project.pbxproj`.
- Проверено наличие файловой структуры проекта.

## Что перепроверить человеку

- Открыть `FamilyBudget.xcodeproj` в Xcode.
- Выбрать установленный Xcode через `xcode-select`, если нужно.
- Запустить:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Подтвердить или заменить bundle identifier.
