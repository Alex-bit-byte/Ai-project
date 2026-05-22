# Задача: доменное ядро

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode  
Spec: `docs/specs/foundation/domain-core.md`

## Конкретный результат

Реализованы чистые Domain value objects, entities, enums и базовые финансовые расчеты без зависимости от SwiftUI и SwiftData.

## Scope

- `Money`.
- `YearMonth`.
- Domain entities для участников, доходов, кредитов и платежей.
- Enums для категорий доходов, повторяемости и статусов платежей.
- Расчеты доходов, кредитной нагрузки, остатков и процента нагрузки.
- Генерация графика платежей.
- Определение просрочки.

## Out of scope

- SwiftData models.
- UI.
- ViewModels.
- LocalAuthentication.
- UserNotifications.
- Форматирование валюты для UI.

## Предполагаемые области кода

- `FamilyBudget/Domain/ValueObjects/`
- `FamilyBudget/Domain/FamilyMembers/`
- `FamilyBudget/Domain/Income/`
- `FamilyBudget/Domain/Credits/`
- `FamilyBudget/Domain/BudgetCalculations/`
- `FamilyBudgetTests/Domain/`

## Шаги реализации

1. Реализовать `Money` и правила арифметики одной валюты.
2. Реализовать `YearMonth`, validation, ordering и month ranges.
3. Реализовать domain entities и enums.
4. Реализовать расчеты доходов по месяцу.
5. Реализовать генерацию графика кредитных платежей.
6. Реализовать расчеты остатков и процента нагрузки.
7. Покрыть критичные правила unit tests.

## Тесты

- `Money` arithmetic и currency mismatch.
- `YearMonth` validation, ordering, ranges.
- Recurring и one-time income applicability.
- Income override.
- Member/family income.
- Credit schedule generation.
- Payment overdue detection.
- Member/family credit load.
- Remaining money.
- Credit load percentage, включая `notApplicable`.

## Definition of Done

- Domain не импортирует SwiftUI и SwiftData.
- Все финансовые расчеты используют `Money`.
- Все помесячные расчеты используют `YearMonth`.
- Unit tests для критичных расчетов проходят.
- Review note создана в `docs/reviews/`.

## Результат выполнения

Дата выполнения: 2026-05-11

Реализовано:

- `Money` с арифметикой через `Decimal` и ошибкой при смешивании валют.
- `YearMonth` с validation, ordering, переходами между месяцами и диапазонами.
- Domain entities: `FamilyMember`, `Income`, `IncomeOverride`, `Credit`, `CreditPayment`.
- Enums: `IncomeCategory`, `IncomeRecurrence`, `PaymentStatus`, `CreditLoadPercentage`.
- `BudgetCalculator` для доходов, графика кредитных платежей, кредитной нагрузки, остатков и процента нагрузки.
- Unit tests в `FamilyBudgetTests/Domain/` для критичных правил из spec.

Выполненные проверки:

- `swiftc -typecheck FamilyBudget/Domain/...` — успешно.
- `plutil -lint FamilyBudget.xcodeproj/project.pbxproj` — успешно.
- `xmllint --noout FamilyBudget.xcodeproj/xcshareddata/xcschemes/FamilyBudget.xcscheme` — успешно.
- `rg "import SwiftUI|import SwiftData" FamilyBudget/Domain` — совпадений нет.

Не выполнено:

- Полный `xcodebuild test` не запущен, потому что активный developer directory указывает на Command Line Tools: `/Library/Developer/CommandLineTools`, а не на полный Xcode.

Review note: `docs/reviews/foundation/domain-core.md`
