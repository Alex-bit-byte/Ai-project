# Задача: главная годовая таблица

Дата: 2026-05-11  
Статус: draft for human review  
Spec: `docs/specs/features/yearly-overview.md`  
Зависит от:

- `docs/tasks/features/income-management.md`
- `docs/tasks/features/credits-installments.md`
- `docs/tasks/foundation/domain-core.md`

## Конкретный результат

Пользователь видит главную годовую таблицу из 12 месяцев с семейными итогами, остатком, процентом нагрузки и цветовой индикацией.

## Scope

- Use case расчета годовой сводки.
- `YearlyOverviewState`.
- Переключение года.
- 12 monthly summary rows/cards.
- Цветовая индикация нагрузки.
- Агрегированный статус платежей месяца.
- Переход в детали месяца.

## Out of scope

- Детальная разбивка по участникам.
- Отметка платежей как оплаченных.
- Charts/сложная аналитика.
- Export.
- iPad-specific layout.

## Предполагаемые области кода

- `FamilyBudget/Application/YearlyOverview/`
- `FamilyBudget/Presentation/YearlyOverview/`
- `FamilyBudget/Domain/BudgetCalculations/`
- `FamilyBudgetTests/Application/YearlyOverview/`
- `FamilyBudgetTests/Presentation/YearlyOverview/`

## Шаги реализации

1. Реализовать use case yearly overview на 12 месяцев.
2. Реализовать thresholds цветовой нагрузки.
3. Реализовать view model/state для selected year.
4. Реализовать SwiftUI экран годовой таблицы.
5. Добавить navigation action в детали месяца.
6. Добавить tests для calculations и view states.

## Тесты

- Yearly overview всегда содержит 12 месяцев.
- Доход, нагрузка, остаток и процент совпадают с Domain calculations.
- Thresholds до 30%, 30-50%, выше 50%.
- `notApplicable` при нулевом доходе.
- Переключение года.

## Definition of Done

- Таблица не перегружает UI деталями по каждому человеку.
- Кредиты из будущих лет отображаются в соответствующем году.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
