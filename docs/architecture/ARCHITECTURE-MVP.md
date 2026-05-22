# Архитектура MVP: Семейный бюджет iOS

Дата: 2026-05-11  
Статус: draft for human review  
Источник: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`

## 1. Цель документа

Документ фиксирует базовую архитектуру MVP до начала feature-разработки. Он нужен, чтобы будущие specs, tasks, реализация и review опирались на единые границы приложения, доменные правила и технические решения.

Архитектура не расширяет scope PRD и не добавляет новые product features.

## 2. Принятые решения

- Минимальная версия: iOS 17+.
- UI: SwiftUI.
- Локальное хранение: SwiftData.
- Архитектурный стиль: layered monolith + vertical slices.
- Domain-модели отделены от SwiftData-моделей.
- Data-слой отвечает за SwiftData-модели, repositories и mapping.
- Финансовая арифметика использует `Money` value object поверх `Decimal`.
- Даты помесячных расчетов используют `YearMonth`, а не произвольные строки или день месяца.
- Внешние интеграции в MVP отсутствуют, кроме системных Apple API: LocalAuthentication и UserNotifications.

## 3. Архитектурный стиль

Проект остается единым iOS-приложением без разделения на Swift Packages на этапе MVP.

Базовые слои:

- `Presentation`: SwiftUI views, view state, пользовательские действия, навигация на уровне экранов.
- `Application`: use cases, orchestration пользовательских сценариев, подготовка данных для UI.
- `Domain`: entities, value objects, доменные расчеты, правила статусов и финансовые формулы.
- `Data`: SwiftData `@Model`, repositories, mapping между persistence и Domain.

Вертикальные slice должны группировать код вокруг пользовательской функции:

- `FamilyMembers`
- `Income`
- `Credits`
- `YearlyOverview`
- `MonthDetails`
- `Settings`
- `Security`
- `Notifications`

Shared-код появляется только после 2-3 реальных повторов и понятной общей формы.

## 4. Рекомендуемая структура будущего Xcode-проекта

```text
FamilyBudget/
  App/
    FamilyBudgetApp.swift
    AppRootView.swift
  Domain/
    ValueObjects/
      Money.swift
      YearMonth.swift
    FamilyMembers/
    Income/
    Credits/
    BudgetCalculations/
  Application/
    FamilyMembers/
    Income/
    Credits/
    YearlyOverview/
    MonthDetails/
    Settings/
    Security/
    Notifications/
  Data/
    SwiftDataModels/
    Repositories/
    Mappers/
    Persistence/
  Presentation/
    FamilyMembers/
    Income/
    Credits/
    YearlyOverview/
    MonthDetails/
    Settings/
    SharedUI/
```

Точная файловая структура может уточняться в specs и tasks, но слои и зависимости должны сохраняться.

## 5. Правила зависимостей

Разрешенные зависимости:

- `Presentation` -> `Application`, `Domain`
- `Application` -> `Domain`
- `Data` -> `Domain`
- `App` -> `Presentation`, `Application`, `Data`

Запрещенные зависимости:

- `Domain` -> `SwiftUI`
- `Domain` -> `SwiftData`
- `Domain` -> `Foundation` API, если это создает нестабильную дату/валютную логику вместо value objects
- `Application` -> конкретные SwiftData `@Model`
- `Presentation` -> прямые SwiftData-запросы для бизнес-расчетов

SwiftData может использоваться напрямую в простых settings/persistence flows только если это явно разрешено соответствующим spec.

## 6. Domain layer

Domain содержит бизнес-смысл приложения и должен тестироваться без UI и SwiftData.

Ключевые domain concepts:

- `FamilyMember`
- `Income`
- `IncomeOverride`
- `Credit`
- `CreditPayment`
- `AppSettings`
- `Money`
- `YearMonth`
- `IncomeCategory`
- `IncomeRecurrence`
- `PaymentStatus`
- `CreditLoad`
- `MonthlyBudgetSummary`

Критичные доменные правила:

- расчет дохода участника за месяц;
- расчет дохода семьи за месяц;
- применение override к повторяющемуся доходу;
- расчет графика кредитных платежей;
- определение статуса платежа;
- определение просрочки;
- расчет остатка участника;
- расчет общего остатка семьи;
- расчет процента кредитной нагрузки.

## 7. Money

Для доменной арифметики используется `Money`.

Базовые требования:

- хранит `amount: Decimal`;
- хранит `currencyCode: String`;
- запрещает смешивание разных валют в одной операции;
- поддерживает сложение, вычитание и сравнение сумм одной валюты;
- не использует `Double` для доменных расчетов;
- форматирование для UI не живет внутри бизнес-расчетов.

MVP поддерживает одну основную валюту, выбранную в настройках. Мультивалютность не входит в MVP.

## 8. YearMonth

`YearMonth` используется для всех помесячных расчетов.

Базовые требования:

- хранит `year: Int`;
- хранит `month: Int` в диапазоне 1...12;
- поддерживает сравнение и сортировку;
- поддерживает переход к следующему/предыдущему месяцу;
- поддерживает построение диапазона месяцев;
- отделяет месяц планирования от конкретной даты платежа.

Конкретная дата нужна только там, где есть `dueDate`, `paidAt` или локальное уведомление.

## 9. Data layer

SwiftData используется как локальное persistence-хранилище.

Data layer содержит:

- SwiftData `@Model` types;
- repositories;
- mappers между SwiftData и Domain;
- настройки `ModelContainer`;
- миграционные решения, если они понадобятся после изменения модели.

Domain entities не должны становиться SwiftData `@Model`.

## 10. Application layer

Application layer координирует use cases.

Примеры будущих use cases:

- создать участника семьи;
- рассчитать сводку года;
- рассчитать детали месяца;
- создать доход;
- применить override дохода;
- создать кредит и график платежей;
- отметить платеж как оплаченный;
- обновить настройки безопасности;
- запланировать локальные уведомления.

Use case не должен содержать SwiftUI view state и не должен напрямую зависеть от SwiftData models.

## 11. Presentation layer

Presentation строится на SwiftUI.

Правила:

- business logic не живет в `body`;
- view получает готовый view state или вызывает use case через view model;
- экран годовой таблицы показывает семейные итоги, а не полную детализацию всех сущностей;
- детали месяца показывают участников, доходы, платежи и остатки;
- формы используют системные controls и короткие понятные поля;
- состояния загрузки, пустые состояния и ошибки описываются в specs конкретных экранов.

## 12. Security

MVP использует LocalAuthentication.

Базовая политика:

- Face ID / Touch ID включается пользователем в настройках;
- при включенной защите приложение требует локальную аутентификацию при открытии;
- fallback идет через системный код устройства;
- финансовые данные не отправляются на сервер;
- уведомления по умолчанию не раскрывают сумму и название кредита.

Детальные UX-состояния безопасности фиксируются отдельным spec.

## 13. Notifications

MVP использует UserNotifications.

Базовая политика:

- уведомления локальные;
- разрешение запрашивается только в контексте включения уведомлений;
- если разрешение не выдано, приложение продолжает работать;
- текст уведомления по умолчанию нейтральный: "Напоминание о платеже".

## 14. Testing strategy

Приоритет тестирования:

1. Domain unit tests.
2. Application use case tests.
3. Mapping и persistence edge cases.
4. ViewModel state tests.
5. UI happy paths для критичных сценариев.

Обязательные доменные тесты:

- `YearMonth` validation, ordering и ranges;
- `Money` arithmetic и currency mismatch;
- доход участника по месяцу;
- доход семьи по месяцу;
- override повторяющегося дохода;
- график платежей по кредиту;
- статус оплаты и просрочка;
- кредитная нагрузка участника;
- кредитная нагрузка семьи;
- остаток участника;
- общий остаток семьи;
- процент нагрузки.

## 15. Guardrails

Запрещено без отдельного decision log:

- добавлять сервер, аккаунты или синхронизацию;
- добавлять банковские интеграции;
- добавлять импорт/экспорт;
- добавлять мультивалютность;
- использовать внешние зависимости;
- дробить приложение на Swift Packages;
- вводить DI container, event bus или custom reactive layer;
- смешивать SwiftData models с domain calculations.

## 16. Принятые базовые допущения и открытые вопросы

- Исходный PRD остается в корне как canonical source, потому что на него уже ссылается `AGENTS.md`. Позже его можно скопировать в `docs/prd/` отдельным housekeeping task.
- Review notes создаются после implementation slices. До появления кода достаточно specs и decisions.
- Открытый вопрос: какой currency code будет значением по умолчанию: `USD`, `RUB`, `TJS` или другой?
