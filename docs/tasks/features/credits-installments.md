# Задача: кредиты и рассрочки

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode
Spec: `docs/specs/features/credits-installments.md`  
Зависит от:

- `docs/tasks/features/family-members.md`
- `docs/tasks/foundation/domain-core.md`
- `docs/tasks/foundation/local-persistence.md`

## Конкретный результат

Пользователь может создавать, редактировать и удалять кредиты/рассрочки с фиксированным графиком платежей.

## Scope

- Credit CRUD use cases.
- Credit validation.
- Manual monthly payment mode.
- Calculated monthly payment mode.
- Генерация `CreditPayment` по сроку кредита.
- Обработка `paymentDay` 29-31.
- Credit list и form states.
- Предупреждение при изменении кредита с оплаченными платежами.

## Out of scope

- Уведомления.
- Отметка платежа как оплаченного.
- Годовая таблица UI.
- Сложные проценты/ставки.
- Коррекция rounding difference.

## Предполагаемые области кода

- `FamilyBudget/Domain/Credits/`
- `FamilyBudget/Application/Credits/`
- `FamilyBudget/Presentation/Credits/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudgetTests/Domain/Credits/`
- `FamilyBudgetTests/Application/Credits/`

## Шаги реализации

1. Реализовать credit input validation.
2. Реализовать расчет monthly payment по простой формуле.
3. Реализовать генерацию графика платежей.
4. Реализовать create/update/delete credit use cases.
5. Реализовать credit form с manual/calculated modes.
6. Реализовать предупреждение для кредита с оплаченными платежами.
7. Добавить tests для schedule generation и validation.

## Тесты

- Нельзя создать кредит без участника.
- Нельзя создать кредит с пустым названием.
- Нельзя создать кредит с `downPayment > totalAmount`.
- Генерируется ровно `termMonths` платежей.
- `paymentDay` в коротких месяцах переносится на последний день.
- Calculated monthly payment работает по простой формуле.

## Definition of Done

- Кредиты и платежи сохраняются локально.
- График платежей воспроизводим и покрыт tests.
- Кредитная нагрузка готова для годовой таблицы.
- Acceptance criteria spec выполнены.
- Review note создана в `docs/reviews/`.
