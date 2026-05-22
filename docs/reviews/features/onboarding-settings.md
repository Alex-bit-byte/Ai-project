# Review: первый запуск и настройки валюты

Дата: 2026-05-11  
Task: `docs/tasks/features/onboarding-settings.md`  
Spec: `docs/specs/features/onboarding-settings.md`  
Статус: implementation review, ожидает XCTest в полном Xcode

## Соответствие spec

- При загрузке settings создается default `AppSettings`, если запись отсутствует.
- Settings state показывает текущий `currencyCode`.
- Валюту можно изменить до появления денежных записей.
- Смена валюты блокируется, если есть доходы, кредиты или платежи.
- Экран настроек содержит toggles для Face ID / Touch ID и уведомлений без системных flows.
- Экран показывает название, версию и note о локальном хранении.
- Первый экран приложения содержит empty state без семьи и вход в настройки.
- Настройки не требуют сети и не создают внешние аккаунты.

## Найденные риски

- `USD` выбран как default currency по делегированному решению владельца проекта. Это стоит визуально подтвердить при review первого запуска.
- SwiftData-backed проверка денежных записей не была подтверждена full build/test из-за отсутствия полного Xcode.
- Placeholder toggles сохраняют значения, но не запускают LocalAuthentication/UserNotifications flows; это соответствует out of scope текущей task.

## Тестовые пробелы

- Application/ViewModel tests добавлены, но не запущены через XCTest.
- UI не проверялся на simulator из-за ограничения окружения.

## Ручные проверки

- Выполнен `swiftc -typecheck` для settings use case, view model и SwiftUI settings view.
- Проверен `project.pbxproj` через `plutil`.
- Проверен shared scheme через `xmllint`.

## Что перепроверить человеку

- Запустить:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Открыть первый экран и settings screen в simulator.
- Подтвердить, что `USD` подходит как default currency для первого запуска.
