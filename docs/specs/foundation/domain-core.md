# Доменное ядро и финансовые расчеты

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Контекст

Самый рискованный слой MVP — финансовые расчеты по доходам, кредитам, остаткам и проценту кредитной нагрузки. Эти правила должны быть независимы от SwiftUI и SwiftData.

## 2. Цель

Зафиксировать базовые domain entities, value objects и правила расчетов, которые будут использоваться всеми future feature specs.

## 3. Scope

Входит:

- `Money`;
- `YearMonth`;
- `FamilyMember`;
- `Income`;
- `IncomeOverride`;
- `Credit`;
- `CreditPayment`;
- enums для категорий доходов, повторяемости и статусов платежей;
- расчеты доходов, платежей, остатков и кредитной нагрузки.

Не входит:

- UI формы;
- persistence implementation;
- SwiftData schema;
- настройки уведомлений;
- Face ID / Touch ID flow.

## 4. Domain model

### Money

Поля:

- `amount: Decimal`
- `currencyCode: String`

Правила:

- арифметика разрешена только для одинакового `currencyCode`;
- `Double` не используется для доменных денежных расчетов;
- отрицательные значения допустимы только там, где spec конкретной операции явно разрешает долг или отрицательный остаток.

### YearMonth

Поля:

- `year: Int`
- `month: Int`

Правила:

- `month` должен быть в диапазоне 1...12;
- тип должен поддерживать сравнение, сортировку и диапазоны месяцев;
- годовая таблица строится по 12 значениям `YearMonth` для выбранного года.

### FamilyMember

Поля:

- `id: UUID`
- `name: String`
- `createdAt: Date`
- `updatedAt: Date`

### Income

Поля:

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

### IncomeOverride

Поля:

- `id: UUID`
- `incomeId: UUID`
- `month: YearMonth`
- `amount: Money`
- `note: String?`

### Credit

Поля:

- `id: UUID`
- `memberId: UUID`
- `title: String`
- `totalAmount: Money`
- `downPayment: Money`
- `monthlyPayment: Money`
- `termMonths: Int`
- `startMonth: YearMonth`
- `endMonth: YearMonth`
- `paymentDay: Int`
- `reminderEnabled: Bool`
- `createdAt: Date`
- `updatedAt: Date`

### CreditPayment

Поля:

- `id: UUID`
- `creditId: UUID`
- `month: YearMonth`
- `dueDate: Date`
- `amount: Money`
- `status: PaymentStatus`
- `paidAt: Date?`

## 5. Functional requirements

- Повторяющийся доход применяется каждый месяц от `startMonth` до `endMonth`, если `endMonth` задан.
- Разовый доход применяется только к выбранному месяцу.
- `IncomeOverride` заменяет сумму конкретного повторяющегося дохода только в указанном месяце.
- Доход участника за месяц равен сумме применимых доходов с учетом override.
- Доход семьи за месяц равен сумме доходов всех участников.
- Кредитный платеж принадлежит владельцу кредита.
- График платежей создается по `termMonths`, `startMonth`, `paymentDay` и `monthlyPayment`.
- Остаток участника равен доходу участника минус платежи участника.
- Общий остаток семьи равен доходу семьи минус кредитная нагрузка семьи.
- Процент кредитной нагрузки равен `credit payments / income * 100`.
- При нулевом доходе процент нагрузки не должен приводить к делению на ноль.

## 6. Acceptance criteria

- Все доменные расчеты доступны без SwiftData.
- Все денежные расчеты используют `Money`.
- Все помесячные расчеты используют `YearMonth`.
- Расчет процента нагрузки стабилен при нулевом доходе.
- График кредита не создает платежи за пределами срока кредита.
- Просроченность платежа может быть определена относительно текущей даты.

## 7. Edge cases

- Доход равен нулю.
- Кредитная нагрузка больше дохода.
- Остаток становится отрицательным.
- `endMonth` раньше `startMonth`.
- `termMonths <= 0`.
- `paymentDay` больше количества дней в месяце.
- Override задан для месяца вне периода дохода.
- Смешивание разных валют в одной операции.

## 8. Миграции

Не применимо для чистого Domain layer.

## 9. Стратегия тестирования

Unit tests:

- `Money` arithmetic;
- `Money` currency mismatch;
- `YearMonth` validation;
- `YearMonth` ordering and ranges;
- income applicability by month;
- recurring income override;
- one-time income;
- member monthly income;
- family monthly income;
- credit schedule generation;
- payment overdue detection;
- member credit load;
- family credit load;
- member remaining money;
- family remaining money;
- credit load percentage with positive income;
- credit load percentage with zero income.

## 10. Принятые базовые допущения

- При нулевом доходе процент нагрузки должен возвращать специальное состояние `notApplicable`, а не `0%`, чтобы UI не показывал ложное отсутствие нагрузки.
- Если `paymentDay` больше количества дней в месяце, дата платежа переносится на последний день месяца.
