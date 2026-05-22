# Mermaid-диаграммы архитектуры и проектных спецификаций

Дата: 2026-05-11  
Статус: draft for human review  
Связанные документы:

- `ARCHITECTURE-MVP.md`
- `../specs/features/mvp-feature-catalog.md`
- `../tasks/mvp-task-catalog.md`

## 1. Spec Driven Development flow

```mermaid
flowchart LR
    PRD["PRD<br/>цель, пользователи, MVP scope"]
    ARCH["Architecture<br/>слои, зависимости, guardrails"]
    SPEC["Specs<br/>foundation + features"]
    TASKS["Tasks<br/>ограниченный scope реализации"]
    IMPL["Implementation<br/>Swift / SwiftUI / SwiftData"]
    TESTS["Tests<br/>domain, use cases, mapping, view state"]
    REVIEW["Review notes<br/>риски, проверки, пробелы"]

    PRD --> ARCH
    ARCH --> SPEC
    SPEC --> TASKS
    TASKS --> IMPL
    IMPL --> TESTS
    TESTS --> REVIEW
    REVIEW -->|если есть критичные замечания| SPEC

    HUMAN["Human-in-the-loop<br/>scope, privacy, finance, migrations"]
    HUMAN -. подтверждает .-> SPEC
    HUMAN -. подтверждает .-> TASKS
    HUMAN -. review .-> REVIEW
```

## 2. Layered monolith + vertical slices

```mermaid
flowchart TB
    APP["App<br/>FamilyBudgetApp, AppRootView"]

    subgraph PRESENTATION["Presentation"]
        UI_SETTINGS["Settings UI"]
        UI_MEMBERS["FamilyMembers UI"]
        UI_INCOME["Income UI"]
        UI_CREDITS["Credits UI"]
        UI_YEAR["YearlyOverview UI"]
        UI_MONTH["MonthDetails UI"]
        UI_SECURITY["Security UI"]
        UI_NOTIF["Notifications UI"]
    end

    subgraph APPLICATION["Application"]
        UC_SETTINGS["Settings use cases"]
        UC_MEMBERS["FamilyMembers use cases"]
        UC_INCOME["Income use cases"]
        UC_CREDITS["Credits use cases"]
        UC_YEAR["YearlyOverview use cases"]
        UC_MONTH["MonthDetails use cases"]
        UC_SECURITY["Security use cases"]
        UC_NOTIF["Notifications use cases"]
    end

    subgraph DOMAIN["Domain"]
        VO["Value objects<br/>Money, YearMonth"]
        ENTITIES["Entities<br/>FamilyMember, Income, Credit, CreditPayment"]
        RULES["Rules<br/>income, schedules, load %, overdue"]
    end

    subgraph DATA["Data"]
        MODELS["SwiftData @Model"]
        MAPPERS["Mappers<br/>Persistence <-> Domain"]
        REPOS["Repositories"]
        CONTAINER["ModelContainer"]
    end

    APP --> PRESENTATION
    APP --> DATA
    PRESENTATION --> APPLICATION
    PRESENTATION --> DOMAIN
    APPLICATION --> DOMAIN
    APPLICATION --> REPOS
    DATA --> DOMAIN
    REPOS --> MAPPERS
    MAPPERS --> MODELS
    MODELS --> CONTAINER

    DOMAIN -. запрещено .-> MODELS
    DOMAIN -. запрещено .-> PRESENTATION
```

## 3. MVP feature dependencies

```mermaid
flowchart TD
    FOUNDATION["Foundation<br/>project setup, domain core, persistence"]
    SETTINGS["Первый запуск<br/>и настройки валюты"]
    MEMBERS["Участники семьи"]
    INCOME["Доходы"]
    CREDITS["Кредиты и рассрочки"]
    YEAR["Годовая таблица"]
    MONTH["Детали месяца<br/>и оплата платежей"]
    SECURITY["Защита приложения"]
    REMINDERS["Локальные напоминания"]

    FOUNDATION --> SETTINGS
    FOUNDATION --> MEMBERS
    FOUNDATION --> INCOME
    FOUNDATION --> CREDITS

    SETTINGS --> MEMBERS
    MEMBERS --> INCOME
    MEMBERS --> CREDITS
    INCOME --> YEAR
    CREDITS --> YEAR
    YEAR --> MONTH
    CREDITS --> MONTH

    SETTINGS --> SECURITY
    SETTINGS --> REMINDERS
    CREDITS --> REMINDERS
```

## 4. Conceptual data model

```mermaid
erDiagram
    FAMILY_MEMBER ||--o{ INCOME : owns
    FAMILY_MEMBER ||--o{ CREDIT : owns
    INCOME ||--o{ INCOME_OVERRIDE : has
    CREDIT ||--o{ CREDIT_PAYMENT : generates
    APP_SETTINGS ||--|| APP_SETTINGS_SINGLETON : "single active record"

    FAMILY_MEMBER {
        UUID id
        String name
        Date createdAt
        Date updatedAt
    }

    INCOME {
        UUID id
        UUID memberId
        IncomeCategory category
        String title
        Money amount
        IncomeRecurrence recurrence
        YearMonth startMonth
        YearMonth endMonth
        Date createdAt
        Date updatedAt
    }

    INCOME_OVERRIDE {
        UUID id
        UUID incomeId
        YearMonth month
        Money amount
        String note
    }

    CREDIT {
        UUID id
        UUID memberId
        String title
        Money totalAmount
        Money downPayment
        Money monthlyPayment
        Int termMonths
        YearMonth startMonth
        YearMonth endMonth
        Int paymentDay
        Bool reminderEnabled
        Date createdAt
        Date updatedAt
    }

    CREDIT_PAYMENT {
        UUID id
        UUID creditId
        YearMonth month
        Date dueDate
        Money amount
        PaymentStatus status
        Date paidAt
    }

    APP_SETTINGS {
        UUID id
        String currencyCode
        Bool biometricLockEnabled
        Bool notificationsEnabled
    }

    APP_SETTINGS_SINGLETON {
        String invariant
    }
```

## 5. Main runtime flows

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant App as AppRoot
    participant Security as Security use case
    participant Settings as Settings repository
    participant Overview as YearlyOverview use case
    participant Domain as Domain calculations
    participant Data as SwiftData repositories
    participant Month as MonthDetails use case
    participant Notifications as Notifications use case
    participant System as iOS APIs

    User->>App: Открывает приложение
    App->>Settings: Load AppSettings
    Settings-->>App: biometricLockEnabled, notificationsEnabled
    alt Биометрическая защита включена
        App->>Security: authenticate()
        Security->>System: LocalAuthentication
        System-->>Security: success / cancel / error
        Security-->>App: unlocked / locked
    end

    App->>Overview: Load selected year
    Overview->>Data: Fetch members, incomes, credits, payments
    Data-->>Overview: Domain entities
    Overview->>Domain: Calculate 12 monthly summaries
    Domain-->>Overview: YearlyOverviewState
    Overview-->>App: Render yearly table

    User->>App: Открывает месяц
    App->>Month: Load YearMonth details
    Month->>Data: Fetch month data
    Month->>Domain: Calculate member and family summary
    Domain-->>Month: Monthly details state
    Month-->>App: Render details

    User->>App: Отмечает платеж оплаченным
    App->>Month: markPaymentPaid(paymentId)
    Month->>Data: Update status paid, paidAt
    Data-->>Month: Saved
    Month-->>App: Updated state

    opt Reminder enabled for credit
        App->>Notifications: schedule credit reminders
        Notifications->>System: UserNotifications
        System-->>Notifications: scheduled / denied / failed
    end
```
