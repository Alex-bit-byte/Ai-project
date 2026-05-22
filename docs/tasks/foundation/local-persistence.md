# Задача: локальное хранение и mapping

Дата: 2026-05-11  
Статус: implemented, ожидает XCTest в полном Xcode  
Spec: `docs/specs/foundation/local-persistence.md`

## Конкретный результат

Настроен SwiftData Data layer с persistence models, mappers и repositories для MVP-сущностей.

## Scope

- SwiftData `@Model` для settings, members, incomes, income overrides, credits, payments.
- Mapping persistence <-> Domain.
- Repositories для basic CRUD и queries.
- In-memory SwiftData setup для tests.
- Default settings initialization.

## Out of scope

- Feature UI.
- Финансовые расчеты в Data layer.
- iCloud sync.
- Миграции после релиза.
- Import/export.
- Encryption layer поверх системного storage.

## Предполагаемые области кода

- `FamilyBudget/Data/SwiftDataModels/`
- `FamilyBudget/Data/Mappers/`
- `FamilyBudget/Data/Repositories/`
- `FamilyBudget/Data/Persistence/`
- `FamilyBudgetTests/Data/`

## Шаги реализации

1. Создать SwiftData models без бизнес-расчетов.
2. Реализовать сериализацию `Money.amount` как строку.
3. Реализовать mapping для `Money`, `YearMonth`, enums и relationships.
4. Реализовать repositories для MVP-сущностей.
5. Настроить `ModelContainer` для app и in-memory tests.
6. Добавить initialization default settings.

## Тесты

- Mapper tests для всех сущностей.
- In-memory persistence tests для create/update/delete.
- Tests для default settings.
- Tests для referential consistency на уровне приложения.

## Definition of Done

- Domain tests не требуют SwiftData.
- SwiftData models не содержат бизнес-расчетов.
- Mapping errors диагностируемы.
- Persistence tests проходят.
- Review note создана в `docs/reviews/`.

## Результат выполнения

Дата выполнения: 2026-05-11

Реализовано:

- SwiftData `@Model` для `AppSettings`, участников, доходов, override доходов, кредитов и платежей.
- Mapping persistence <-> Domain для `Money`, `YearMonth`, enums, ids и дат.
- Хранение `Money.amount` как строки через контролируемую сериализацию `Decimal`.
- Repositories для settings, family members, incomes, income overrides, credits и credit payments.
- `PersistenceContainerFactory` для production и in-memory `ModelContainer`.
- Инициализация default settings.
- Подключение `ModelContainer` в `FamilyBudgetApp`.
- Data tests для mapper round-trip, default settings и in-memory CRUD.

Принятое решение:

- Default `currencyCode`: `USD`. Решение принято агентом по указанию владельца проекта принимать решения самостоятельно и с учетом текущей пользовательской среды. До создания денежных записей оно может быть изменено через будущий onboarding/settings flow.

Выполненные проверки:

- `plutil -lint FamilyBudget.xcodeproj/project.pbxproj` — успешно.
- `xmllint --noout FamilyBudget.xcodeproj/xcshareddata/xcschemes/FamilyBudget.xcscheme` — успешно.
- Проверено, что Data layer не содержит доменных расчетов.

Не выполнено:

- `swiftc -typecheck` для Data layer не прошел в текущем окружении, потому что Command Line Tools не содержит доступный plugin `SwiftDataMacros` для раскрытия `@Model`.
- Полный `xcodebuild test` не запущен, потому что активный developer directory указывает на Command Line Tools: `/Library/Developer/CommandLineTools`, а не на полный Xcode.

Review note: `docs/reviews/foundation/local-persistence.md`
