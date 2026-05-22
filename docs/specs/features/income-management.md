# Доходы

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Контекст

Доходы являются базой для расчета остатка "на жизнь" и процента кредитной нагрузки. MVP поддерживает зарплату, премии и прочие доходы.

## 2. Цель

Позволить пользователю добавлять регулярные и разовые доходы участникам семьи, а также корректировать повторяющийся доход в конкретном месяце.

## 3. Пользовательские сценарии

- Пользователь добавляет ежемесячную зарплату участнику.
- Пользователь добавляет разовую премию в конкретный месяц.
- Пользователь меняет сумму регулярного дохода только для одного месяца.
- Пользователь редактирует или удаляет доход.

## 4. Functional requirements

- Доход принадлежит одному `FamilyMember`.
- Категории MVP: salary, bonus, other.
- Доход имеет сумму `Money`.
- Повторяемость: monthly или oneTime.
- Monthly income применяется от `startMonth` до `endMonth`, если `endMonth` задан.
- One-time income применяется только к выбранному месяцу.
- Для monthly income можно создать `IncomeOverride` на конкретный месяц.
- Override заменяет сумму дохода только для указанного месяца.
- Удаление дохода удаляет связанные overrides после подтверждения.

## 5. Acceptance criteria

- Нельзя создать доход без участника.
- Нельзя создать доход с невалидной или отрицательной суммой.
- Регулярная зарплата отображается в каждом применимом месяце.
- Разовый доход влияет только на один месяц.
- Override влияет только на выбранный месяц.
- Итоги месяца и года пересчитываются после создания, редактирования или удаления дохода.

## 6. UI states

- список доходов пуст;
- список доходов участника или всех участников;
- форма создания дохода;
- форма редактирования дохода;
- выбор категории;
- выбор recurring/one-time;
- month/year picker;
- validation errors;
- confirmation dialog удаления.

## 7. Ошибки и edge cases

- нет участников семьи;
- сумма равна нулю;
- сумма отрицательная;
- `endMonth` раньше `startMonth`;
- override вне периода действия дохода;
- удаление дохода с overrides;
- изменение валюты недоступно после создания дохода.

## 8. Модель данных

`Income`:

- `id: UUID`
- `memberId: UUID`
- `category: IncomeCategory`
- `title: String?`
- `amount: Money`
- `recurrence: IncomeRecurrence`
- `startMonth: YearMonth`
- `endMonth: YearMonth?`
- `createdAt: Date`
- `updatedAt: Date`

`IncomeOverride`:

- `id: UUID`
- `incomeId: UUID`
- `month: YearMonth`
- `amount: Money`
- `note: String?`

## 9. Миграции

Не требуются для первой версии.

## 10. Стратегия тестирования

- Domain tests для applicability доходов по месяцам.
- Domain tests для recurring override.
- Domain tests для member/family monthly income.
- Mapper tests для `Money`, `YearMonth`, enums.
- ViewModel state tests для forms и validation.

## 11. Принятые базовые допущения

- Доход с суммой `0` запрещен при создании, потому что нулевой доход лучше удалить или не создавать.
