# Задача: доходы

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode
Spec: `docs/specs/features/income-management.md`  
Зависит от:

- `docs/tasks/features/family-members.md`
- `docs/tasks/foundation/domain-core.md`
- `docs/tasks/foundation/local-persistence.md`

## Конкретный результат

Пользователь может создавать, редактировать и удалять регулярные и разовые доходы, а также override регулярного дохода на конкретный месяц.

## Scope

- Income CRUD use cases.
- Income validation.
- Income categories: salary, bonus, other.
- Recurrence: monthly, oneTime.
- Income override для отдельного месяца.
- Income forms и list states.
- Пересчет income summaries через Domain.

## Out of scope

- Кредиты.
- Годовая таблица UI.
- Детали месяца UI.
- Мультивалютность.
- Импорт зарплатных данных.

## Предполагаемые области кода

- `FamilyBudget/Domain/Income/`
- `FamilyBudget/Application/Income/`
- `FamilyBudget/Presentation/Income/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudgetTests/Domain/Income/`
- `FamilyBudgetTests/Application/Income/`

## Шаги реализации

1. Реализовать validation income input.
2. Реализовать create/update/delete income use cases.
3. Реализовать create/update/delete override use cases.
4. Реализовать form state для monthly и one-time income.
5. Реализовать список доходов.
6. Добавить tests для recurrence, override и validation.

## Тесты

- Нельзя создать доход без участника.
- Нельзя создать доход с `0` или отрицательной суммой.
- Monthly income применяется в нужном диапазоне.
- One-time income применяется только к одному месяцу.
- Override влияет только на выбранный месяц.
- Delete income удаляет overrides после подтверждения.

## Definition of Done

- Доходы корректно сохраняются и читаются.
- Domain income calculations покрыты tests.
- Изменения доходов готовы для использования годовой таблицей.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
