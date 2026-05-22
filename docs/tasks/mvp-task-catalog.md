# Каталог задач MVP

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Цель

Документ фиксирует порядок реализации MVP после согласования specs. Он не заменяет отдельные task files и не разрешает расширять scope MVP.

## 2. Рекомендуемый порядок

### Foundation

1. `foundation/project-setup.md`
2. `foundation/domain-core.md`
3. `foundation/local-persistence.md`

### Features

1. `features/onboarding-settings.md`
2. `features/family-members.md`
3. `features/income-management.md`
4. `features/credits-installments.md`
5. `features/yearly-overview.md`
6. `features/month-details-payments.md`
7. `features/app-security.md`
8. `features/local-payment-reminders.md`

## 3. Блокеры перед implementation

- Нужно закрыть вопрос валюты по умолчанию при первом запуске.
- Нужно создать Xcode-проект до задач, которые предполагают build/test command.
- Любое изменение scope MVP требует нового spec или обновления существующего spec.

## 4. Общий Definition of Done

- Реализация соответствует связанному spec.
- Acceptance criteria связанного spec выполнены.
- Scope task не расширен.
- Тесты добавлены или причина пропуска явно указана.
- Тесты запущены или указано, почему не запускались.
- Создан review note в `docs/reviews/`.
