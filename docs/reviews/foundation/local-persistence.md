# Review: локальное хранение и mapping

Дата: 2026-05-11  
Task: `docs/tasks/foundation/local-persistence.md`  
Spec: `docs/specs/foundation/local-persistence.md`  
Статус: implementation review, ожидает XCTest в полном Xcode

## Соответствие spec

- Созданы SwiftData `@Model` types для MVP-сущностей: settings, members, incomes, income overrides, credits, payments.
- Domain entities остаются отдельными от SwiftData models.
- SwiftData models не содержат бизнес-расчетов.
- `Money.amount` хранится в persistence как строка.
- Mapping явно преобразует `Money`, `YearMonth`, enums и ids.
- Mapping errors представлены диагностируемым `PersistenceMappingError`.
- Repositories отвечают за CRUD и basic queries, без годовых сводок, процентов нагрузки и UI state.
- Добавлен in-memory `ModelContainer` для tests.
- Default settings инициализируются при отсутствии записи.

## Найденные риски

- `USD` выбран как default `currencyCode` агентом. Это рабочее решение для продолжения MVP, но продуктово его стоит подтвердить в onboarding/settings review.
- SwiftData macro expansion и XCTest не проверены из-за отсутствия полного Xcode.
- Referential consistency реализуется на уровне application/repository boundaries через UUID-ссылки; каскадное удаление намеренно не добавлено, потому что удаление участника с данными требует отдельного feature spec.
- Изменение currency code после появления денежных записей пока не заблокировано на repository level; это должно быть закрыто в settings/onboarding feature task согласно spec.

## Тестовые пробелы

- Data tests добавлены, но не запущены через XCTest.
- Нет теста на блокировку смены валюты после денежных записей, потому что это относится к будущему settings flow.
- Нет теста на удаление связанных данных, потому что соответствующий feature spec должен определить UX-подтверждение.

## Ручные проверки

- Проверен синтаксис `project.pbxproj`.
- Проверен XML shared scheme.
- Просмотрено, что Data layer не содержит вызовов `BudgetCalculator`.

## Что перепроверить человеку

- Запустить полный test target в Xcode:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Подтвердить `USD` как default currency или заменить до появления реальных денежных записей.
