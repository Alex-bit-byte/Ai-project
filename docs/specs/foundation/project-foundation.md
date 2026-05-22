# Базовая структура проекта

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Контекст

MVP приложения "Семейный бюджет" должен разрабатываться по Spec Driven Development. До feature-разработки нужно зафиксировать базовую структуру iOS-проекта, архитектурные слои и правила зависимостей.

## 2. Цель

Создать основу проекта, которая позволит реализовывать будущие specs без смешивания UI, persistence и доменных расчетов.

## 3. Scope

Входит:

- iOS 17+;
- Swift;
- SwiftUI;
- SwiftData;
- единый Xcode-проект;
- layered monolith + vertical slices;
- базовые директории для `App`, `Domain`, `Application`, `Data`, `Presentation`;
- тестовые targets для domain/application тестов.

Не входит:

- реализация пользовательских features;
- создание конкретных экранов;
- создание конкретных SwiftData-моделей;
- импорт/экспорт;
- iCloud sync;
- внешние зависимости.

## 4. Функциональные требования

- Проект должен собираться как iPhone-first iOS-приложение.
- Минимальная версия iOS должна быть 17+.
- В проекте должны быть разделены слои `Domain`, `Application`, `Data`, `Presentation`.
- Должна быть предусмотрена структура vertical slices.
- Domain layer не должен зависеть от SwiftUI или SwiftData.
- Базовый app entry point должен быть в `App` layer.

## 5. Acceptance criteria

- Приложение запускается на iOS 17+ simulator.
- В проекте есть понятная файловая структура для слоев.
- Domain target/code может тестироваться без SwiftData.
- Нет внешних зависимостей.
- Нет feature-кода вне согласованных specs.

## 6. UI states

Этот spec не определяет UI-состояния пользовательских экранов.

## 7. Ошибки и edge cases

- Если SwiftData container не инициализируется, приложение должно иметь диагностируемую ошибку на этапе разработки.
- Runtime fallback для corrupted persistence будет описан в отдельном persistence spec.

## 8. Модель данных

Этот spec не вводит production-модели данных.

## 9. Миграции

Миграции не требуются до появления первой версии SwiftData schema.

## 10. Стратегия тестирования

- Build test для основного app target.
- Unit test target для Domain.
- Unit test target для Application/use cases после появления use cases.

## 11. Принятые базовые допущения

- Для MVP достаточно одного unit test target, например `FamilyBudgetTests`, с внутренними папками по слоям: `Domain`, `Application`, `Data`, `Presentation`.
- Отдельные test targets можно выделить позже только при реальной необходимости.
