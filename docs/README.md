# Индекс документации

Дата: 2026-05-11  
Статус: актуальный навигационный индекс

## 1. Как читать документацию

Рекомендуемый порядок для агента или разработчика:

1. Прочитать `AGENTS.md`.
2. Прочитать основной PRD: `../PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`.
3. Прочитать архитектуру MVP: `architecture/ARCHITECTURE-MVP.md`.
4. Прочитать foundation specs.
5. Прочитать feature catalog и нужный feature spec.
6. Прочитать соответствующий task.
7. После реализации создать review note в `reviews/`.

Feature-код разрешен только после согласованных spec и task.

## 2. Product source

- `../PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md` — основной продуктовый источник MVP.

## 3. Архитектура

- `architecture/ARCHITECTURE-MVP.md` — базовая архитектура MVP: iOS 17+, SwiftUI, SwiftData, layered monolith + vertical slices, Domain отдельно от SwiftData, `Money`, `YearMonth`.
- `architecture/mermaid-diagrams.md` — наглядные Mermaid-диаграммы архитектуры, SDD-процесса, feature dependencies, data model и runtime flows.

## 4. Foundation specs

- `specs/foundation/project-foundation.md` — базовая структура проекта.
- `specs/foundation/domain-core.md` — доменное ядро и финансовые расчеты.
- `specs/foundation/local-persistence.md` — локальное хранение и mapping.
- `specs/foundation/security-notifications-baseline.md` — базовая безопасность и локальные уведомления.
- `specs/foundation/quality-review-gates.md` — quality gates, тестирование и review.

## 5. Feature specs

- `specs/features/mvp-feature-catalog.md` — карта MVP-фич и зависимости между ними.
- `specs/features/onboarding-settings.md` — первый запуск и настройки валюты.
- `specs/features/family-members.md` — участники семьи.
- `specs/features/income-management.md` — доходы.
- `specs/features/credits-installments.md` — кредиты и рассрочки.
- `specs/features/yearly-overview.md` — главная годовая таблица.
- `specs/features/month-details-payments.md` — детали месяца и оплата платежей.
- `specs/features/app-security.md` — защита приложения.
- `specs/features/local-payment-reminders.md` — локальные напоминания о платежах.

## 6. Tasks

- `tasks/mvp-task-catalog.md` — рекомендуемый порядок реализации MVP.

### Foundation tasks

- `tasks/foundation/project-setup.md` — базовая структура Xcode-проекта.
- `tasks/foundation/domain-core.md` — доменное ядро.
- `tasks/foundation/local-persistence.md` — локальное хранение и mapping.

### Feature tasks

- `tasks/features/onboarding-settings.md` — первый запуск и настройки валюты.
- `tasks/features/family-members.md` — участники семьи.
- `tasks/features/income-management.md` — доходы.
- `tasks/features/credits-installments.md` — кредиты и рассрочки.
- `tasks/features/yearly-overview.md` — главная годовая таблица.
- `tasks/features/month-details-payments.md` — детали месяца и оплата платежей.
- `tasks/features/app-security.md` — защита приложения.
- `tasks/features/local-payment-reminders.md` — локальные напоминания о платежах.

## 7. Decisions

- `decisions/ios17-swiftdata.md` — iOS 17+ и SwiftData для MVP.
- `decisions/domain-separate-from-swiftdata.md` — Domain отдельно от SwiftData.
- `decisions/money-decimal-value-object.md` — `Money` value object поверх `Decimal`.

## 8. Reviews

Review notes создаются после implementation slices:

- `reviews/foundation/`
- `reviews/features/`

Каждая review note должна фиксировать соответствие spec, найденные риски, тестовые пробелы, ручные проверки и то, что нужно перепроверить человеку.

## 9. Текущие блокеры

- Default `currencyCode` временно выбран как `USD` в `tasks/foundation/local-persistence.md`; продуктово стоит подтвердить в onboarding/settings review.
- Xcode-проект создан, но build/test требуют выбрать полный Xcode вместо Command Line Tools.
