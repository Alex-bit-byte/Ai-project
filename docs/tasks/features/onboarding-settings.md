# Задача: первый запуск и настройки валюты

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode  
Spec: `docs/specs/features/onboarding-settings.md`  
Зависит от:

- `docs/tasks/foundation/project-setup.md`
- `docs/tasks/foundation/local-persistence.md`

## Конкретный результат

Пользователь получает первый запуск с default settings и экран настроек для валюты, защиты, уведомлений и информации о приложении.

## Scope

- Default `AppSettings`.
- Settings view state и view model/use case.
- Экран настроек.
- Отображение и изменение `currencyCode` до создания денежных записей.
- Блокировка изменения валюты после создания денежных записей.
- Placeholder/toggles для security и notifications без реализации системных flows.

## Out of scope

- Face ID / Touch ID flow.
- Notification permission flow.
- Создание участников семьи.
- Создание доходов или кредитов.
- Мультивалютность и конвертация.

## Предполагаемые области кода

- `FamilyBudget/Application/Settings/`
- `FamilyBudget/Presentation/Settings/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudgetTests/Application/Settings/`
- `FamilyBudgetTests/Presentation/Settings/`

## Шаги реализации

1. Реализовать use case загрузки или создания default settings.
2. Реализовать проверку наличия денежных записей для блокировки валюты.
3. Реализовать Settings view model/state.
4. Реализовать SwiftUI settings screen.
5. Добавить пустое состояние первого запуска без данных.
6. Покрыть state и validation tests.

## Тесты

- Default settings initialization.
- Currency change allowed до денежных записей.
- Currency change blocked после денежных записей.
- ViewModel states для loaded/error/locked currency.

## Definition of Done

- Открытый вопрос `currencyCode` по умолчанию закрыт человеком до implementation.
- Настройки работают без сети.
- Изменение валюты не создает мультивалютность.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.

## Результат выполнения

Дата выполнения: 2026-05-11

Реализовано:

- `SettingsUseCase` для загрузки/создания default settings.
- Проверка наличия денежных записей для блокировки смены валюты.
- Validation `currencyCode`: 3 буквы, normalization в uppercase.
- `SettingsViewModel` со states `idle/loading/loaded/error`.
- SwiftUI `SettingsView` с выбором валюты, placeholder toggles для Face ID / Touch ID и уведомлений, информацией о локальном хранении.
- Первый экран приложения с empty state без семьи и переходом в настройки.
- Application и Presentation tests для state/validation сценариев.

Принятое решение:

- Default `currencyCode`: `USD`. Владелец проекта явно делегировал принятие решений агенту; решение зафиксировано как рабочее для MVP и не добавляет мультивалютность.

Выполненные проверки:

- `swiftc -typecheck` для Domain + `SettingsUseCase` + `SettingsViewModel` + `SettingsView` — успешно.
- `plutil -lint FamilyBudget.xcodeproj/project.pbxproj` — успешно.
- `xmllint --noout FamilyBudget.xcodeproj/xcshareddata/xcschemes/FamilyBudget.xcscheme` — успешно.

Не выполнено:

- XCTest и full app build не запущены, потому что активный developer directory указывает на Command Line Tools: `/Library/Developer/CommandLineTools`, а не на полный Xcode.

Review note: `docs/reviews/features/onboarding-settings.md`
