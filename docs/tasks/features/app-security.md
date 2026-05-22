# Задача: защита приложения

Дата: 2026-05-11  
Статус: draft for human review  
Spec: `docs/specs/features/app-security.md`  
Зависит от:

- `docs/tasks/features/onboarding-settings.md`
- `docs/tasks/foundation/project-setup.md`

## Конкретный результат

Пользователь может включить защиту приложения, а приложение скрывает финансовые данные до успешной LocalAuthentication.

## Scope

- Security settings toggle.
- LocalAuthentication wrapper на Application boundary.
- Lock/unlock runtime state.
- Проверка при cold start.
- Проверка при возвращении из background после 5+ минут.
- Locked UI state.
- Обработка cancellation/error/unavailable states.

## Out of scope

- Собственный пароль приложения.
- Аккаунты.
- Шифрование отдельным ключом приложения.
- Notification privacy.
- Серверная авторизация.

## Предполагаемые области кода

- `FamilyBudget/Application/Security/`
- `FamilyBudget/Presentation/Settings/`
- `FamilyBudget/Presentation/Security/`
- `FamilyBudget/App/`
- `FamilyBudgetTests/Application/Security/`

## Шаги реализации

1. Реализовать abstraction для LocalAuthentication без зависимости Domain/Data.
2. Реализовать security lock state.
3. Подключить toggle к `AppSettings.biometricLockEnabled`.
4. Реализовать lock gate при app launch.
5. Реализовать background timeout 5 минут.
6. Реализовать locked/authenticating/error UI states.
7. Добавить tests для state decisions.

## Тесты

- Lock disabled не блокирует приложение.
- Lock enabled требует authentication.
- Success открывает финансовый UI.
- Cancellation оставляет UI locked.
- Background timeout вызывает повторную проверку.
- Manual checks LocalAuthentication на simulator/device.

## Definition of Done

- Финансовые данные не отображаются до успешной аутентификации.
- Domain/Data не зависят от LocalAuthentication.
- Manual checks описаны в review note.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
