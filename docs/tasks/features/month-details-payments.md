# Задача: детали месяца и оплата платежей

Дата: 2026-05-11  
Статус: draft for human review  
Spec: `docs/specs/features/month-details-payments.md`  
Зависит от:

- `docs/tasks/features/yearly-overview.md`
- `docs/tasks/features/credits-installments.md`
- `docs/tasks/features/income-management.md`

## Конкретный результат

Пользователь видит детализацию выбранного месяца по семье и участникам, а также может отметить платеж как оплаченный.

## Scope

- Use case month details.
- Сводка семьи за месяц.
- Сводка по каждому участнику.
- Список платежей месяца.
- Mark payment as paid use case.
- Overdue detection для неоплаченных платежей.
- UI states для planned/paid/overdue.

## Out of scope

- Undo оплаты платежа.
- Частичная оплата.
- Редактирование платежа из деталей месяца.
- Уведомления.
- Export.

## Предполагаемые области кода

- `FamilyBudget/Application/MonthDetails/`
- `FamilyBudget/Presentation/MonthDetails/`
- `FamilyBudget/Domain/BudgetCalculations/`
- `FamilyBudget/Domain/Credits/`
- `FamilyBudgetTests/Application/MonthDetails/`
- `FamilyBudgetTests/Presentation/MonthDetails/`

## Шаги реализации

1. Реализовать month details use case.
2. Реализовать participant summary для выбранного месяца.
3. Реализовать list payments by month.
4. Реализовать mark payment as paid.
5. Реализовать overdue presentation state.
6. Добавить SwiftUI экран деталей месяца.
7. Добавить tests для статусов и сохранения оплаты.

## Тесты

- Сводка месяца совпадает с годовой таблицей.
- Остаток участника считается корректно.
- Planned payment можно отметить paid.
- Paid payment получает `paidAt`.
- Paid payment не становится overdue.
- Повторная оплата без undo/edit spec недоступна.

## Definition of Done

- Детали месяца открываются из годовой таблицы.
- Оплата платежа сохраняется локально.
- Просроченные платежи выделяются.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
