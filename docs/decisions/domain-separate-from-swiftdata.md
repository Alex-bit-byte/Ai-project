# Domain отдельно от SwiftData

Дата: 2026-05-11  
Статус: accepted  
Связанные документы:

- `docs/architecture/ARCHITECTURE-MVP.md`
- `docs/specs/foundation/domain-core.md`
- `docs/specs/foundation/local-persistence.md`

## Контекст

Финансовые расчеты — критичная часть приложения. Ошибки в доходах, кредитной нагрузке, остатках и процентах напрямую подрывают ценность MVP.

## Решение

Использовать отдельные Domain entities/value objects и отдельные SwiftData `@Model` types.

Data layer отвечает за mapping между SwiftData и Domain.

## Последствия

Плюсы:

- Domain можно тестировать без SwiftData;
- финансовые правила не зависят от persistence;
- проще контролировать money/date logic;
- меньше риск смешать UI, storage и business logic.

Минусы:

- больше кода на mapping;
- нужны mapper tests;
- repositories должны быть спроектированы аккуратно, чтобы не превратиться в неопределенный `Manager`.

## Альтернативы

- Использовать SwiftData `@Model` напрямую в расчетах: быстрее, но слабее testability и архитектурные границы.
- Гибрид: value objects отдельно, entities как SwiftData models: меньше mapping, но Domain остается частично связан с persistence.

## Проверка решения

Решение остается валидным, пока:

- финансовые расчеты являются критичным ядром продукта;
- Domain tests должны быть быстрыми и независимыми;
- SwiftData schema может меняться без переписывания расчетов.
