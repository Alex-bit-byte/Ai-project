# Review: доходы

Дата: 2026-05-22  
Task: `docs/tasks/features/income-management.md`  
Spec: `docs/specs/features/income-management.md`  
Статус: implementation review, ожидает XCTest в полном Xcode

## Соответствие spec

- Реализованы create, update, list и delete use cases для доходов.
- Доход требует существующего участника.
- Сумма дохода и override должна быть больше нуля.
- Поддержаны категории MVP: salary, bonus, other.
- Поддержаны recurrence: monthly и oneTime.
- Monthly income учитывает `startMonth` и `endMonth`.
- One-time income применяется к выбранному месяцу через Domain logic.
- Реализованы create, update, list и delete use cases для `IncomeOverride`.
- Override разрешен только для monthly income и только внутри периода действия дохода.
- Удаление дохода удаляет связанные overrides.
- При редактировании дохода удаляются overrides, которые больше не попадают в новый период или становятся невалидными для recurrence.
- Добавлены UI states: нет участников, пустой список, список доходов, форма создания/редактирования, список overrides, форма override, confirmation удаления и error state.
- Экран доходов подключен в root toolbar приложения.

## Найденные риски

- UI удаления реализован как отдельное состояние экрана, как и в family members slice; визуально нужно проверить в simulator.
- Presentation пока использует рабочий default `USD` для draft currency до полноценной связки с настройками валюты.
- Нет фильтра списка по участнику в UI, хотя use case поддерживает `memberId`; spec допускает список всех участников или одного участника.

## Тестовые пробелы

- Добавлены Application tests для income CRUD, validation, override lifecycle, удаления overrides и очистки invalid overrides.
- XCTest не запущен из-за локальной настройки: активен `/Library/Developer/CommandLineTools`, а `xcodebuild` требует полный Xcode.
- Нет UI tests для формы дохода и swipe delete.

## Ручные проверки

- Выполнен `swiftc -typecheck` для Domain/Application income slice и `IncomeViewModel`.
- Выполнен `plutil -lint FamilyBudget.xcodeproj/project.pbxproj`.
- `xcodebuild test` запускался, но остановился на требовании полного Xcode.

## Что перепроверить человеку

- Переключить developer directory на полный Xcode и запустить:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Проверить в simulator: создание monthly income, one-time income, редактирование, удаление, создание override и удаление дохода с overrides.
