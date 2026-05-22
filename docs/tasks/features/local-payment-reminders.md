# Задача: локальные напоминания о платежах

Дата: 2026-05-11  
Статус: draft for human review  
Spec: `docs/specs/features/local-payment-reminders.md`  
Зависит от:

- `docs/tasks/features/credits-installments.md`
- `docs/tasks/features/onboarding-settings.md`

## Конкретный результат

Пользователь может включить локальные нейтральные напоминания о платежах, а приложение планирует и отменяет уведомления через UserNotifications.

## Scope

- Notifications settings toggle.
- Permission request после пользовательского намерения.
- Reminder toggle на уровне кредита.
- Stable notification identifiers.
- Scheduling за 1 день до due date в 09:00.
- Cancel notifications при отключении reminder или удалении кредита.
- Reschedule при изменении графика кредита.

## Out of scope

- Push notifications.
- Сервер.
- Раскрытие суммы, названия кредита или участника.
- Настройка времени напоминания пользователем.
- Несколько напоминаний на один платеж.

## Предполагаемые области кода

- `FamilyBudget/Application/Notifications/`
- `FamilyBudget/Presentation/Settings/`
- `FamilyBudget/Presentation/Credits/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudgetTests/Application/Notifications/`

## Шаги реализации

1. Реализовать abstraction для UserNotifications.
2. Реализовать permission state use case.
3. Реализовать stable notification identifier generation.
4. Реализовать schedule reminders для credit payments.
5. Реализовать cancel reminders для credit/credit payment.
6. Подключить reminder toggle в credit flow.
7. Добавить tests для schedule/cancel decisions.

## Тесты

- Permission denied не блокирует создание кредита.
- Identifier стабилен для credit/payment.
- Reminder enabled планирует будущие уведомления.
- Reminder disabled отменяет будущие уведомления.
- Credit update вызывает reschedule.
- Manual checks permission flow и локального уведомления.

## Definition of Done

- Уведомления локальные и нейтральные.
- Нет финансовых деталей в notification content.
- UserNotifications не попадает в Domain/Data.
- Manual checks описаны в review note.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
