# Локальное хранение и mapping

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Контекст

MVP хранит финансовые данные локально на устройстве. Выбрано iOS 17+ и SwiftData. Domain-модели не являются SwiftData-моделями, поэтому Data layer должен обеспечить mapping.

## 2. Цель

Зафиксировать правила локального хранения, границы SwiftData и mapping между persistence-моделями и Domain.

## 3. Scope

Входит:

- SwiftData как локальное хранилище;
- `@Model` types для сохранения данных MVP;
- repositories;
- mapping persistence <-> Domain;
- локальные настройки приложения;
- подготовка к будущим migration plans.

Не входит:

- iCloud sync;
- сервер;
- аккаунты;
- импорт/экспорт;
- encryption layer поверх системного хранилища;
- feature UI.

## 4. Persistence model

SwiftData schema должна покрывать:

- family members;
- incomes;
- income overrides;
- credits;
- credit payments;
- app settings.

Денежные значения должны храниться так, чтобы не терять точность `Decimal`.

Допустимые варианты хранения `Decimal`:

- `Decimal`, если SwiftData schema стабильно поддерживает выбранный тип;
- `String` representation, если потребуется контролируемая сериализация;
- integer minor units только после отдельного decision log.

## 5. Mapping rules

- Domain entities не должны знать о SwiftData.
- SwiftData `@Model` types не должны содержать бизнес-расчеты.
- Mapping должен явно преобразовывать `Money`, `YearMonth`, enums и ids.
- Ошибки mapping должны быть диагностируемыми.
- Repositories возвращают Domain types или Application DTO/view state, если это явно описано spec.

## 6. Repository boundaries

Repositories отвечают за:

- загрузку;
- сохранение;
- обновление;
- удаление;
- basic queries по id, memberId, creditId и диапазонам месяцев.

Repositories не отвечают за:

- расчет годовой сводки;
- расчет процента нагрузки;
- правила просрочки;
- UI state;
- навигацию.

## 7. Functional requirements

- Данные должны храниться локально на устройстве.
- Приложение должно работать без сети.
- Связанные данные должны сохранять referential consistency на уровне приложения.
- Удаление участника с доходами или кредитами должно требовать явного пользовательского подтверждения в feature spec.
- App settings должны иметь ровно одну активную запись или эквивалентный singleton storage mechanism.

## 8. Acceptance criteria

- Data layer может загрузить и сохранить все сущности MVP.
- Domain tests не требуют SwiftData.
- Mapping tests покрывают `Money`, `YearMonth`, enums и relationships.
- Persistence implementation не добавляет внешние зависимости.
- Нет прямого использования SwiftData models в Domain calculations.

## 9. Edge cases

- Отсутствует запись `AppSettings`.
- Поврежденное или неполное persistence-состояние.
- Удален участник, на которого ссылаются доходы или кредиты.
- `IncomeOverride` ссылается на отсутствующий income.
- `CreditPayment` ссылается на отсутствующий credit.
- Изменение currency code после создания денежных записей.

## 10. Миграции

Первая версия schema не требует миграции. После релиза любые изменения schema должны сопровождаться:

- migration note;
- тестом mapping/persistence для старой и новой формы, если применимо;
- review note для риска потери финансовых данных.

## 11. Стратегия тестирования

- Unit tests для mappers.
- Integration tests с in-memory SwiftData container.
- Tests для default settings initialization.
- Tests для удаления связанных данных после появления соответствующего feature spec.

## 12. Принятые базовые допущения и открытые вопросы

- `Money.amount` хранится в SwiftData через строковую сериализацию `Decimal`, чтобы не терять точность и иметь контролируемый mapping.
- После появления денежных записей изменение основной валюты блокируется до отдельного spec, потому что MVP не поддерживает мультивалютность и конвертацию.
- Открытый вопрос: какой currency code использовать по умолчанию при первом запуске.
