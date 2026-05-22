# Review: кредиты и рассрочки

Дата: 2026-05-22  
Task: `docs/tasks/features/credits-installments.md`  
Spec: `docs/specs/features/credits-installments.md`  
Статус: implementation review, ожидает XCTest в полном Xcode

## Соответствие spec

- Реализованы create, update, list и delete use cases для кредитов.
- Кредит требует существующего участника.
- Название кредита обязательно после trimming.
- `totalAmount`, `downPayment`, `monthlyPayment` валидируются как неотрицательные суммы.
- `downPayment > totalAmount` запрещен.
- `termMonths` должен быть больше 0.
- `paymentDay` ограничен диапазоном 1...31.
- Поддержан manual monthly payment mode.
- Поддержан calculated monthly payment mode по формуле `(totalAmount - downPayment) / termMonths`.
- При создании кредита генерируется платеж на каждый месяц срока.
- При редактировании кредита неоплаченный график пересоздается.
- Если у кредита есть оплаченные платежи, update требует подтверждение; оплаченные платежи сохраняются.
- Удаление кредита удаляет связанные платежи.
- Добавлены UI states: нет участников, пустой список, список кредитов, форма создания/редактирования, список платежей, confirmation удаления, warning для кредита с оплаченными платежами и error state.
- Экран кредитов подключен в root toolbar приложения.

## Найденные риски

- При подтвержденном редактировании оплаченные платежи сохраняются даже если новый срок кредита больше не включает их месяц. Это защищает факт оплаты, но может потребовать отдельного product-решения в деталях месяца.
- UI confirmation реализован как отдельное состояние экрана, в стиле текущих slices.
- Переключатель `reminderEnabled` сохраняется в кредит, но сами уведомления остаются out of scope до `local-payment-reminders`.
- Presentation использует рабочий default `USD` для формы до полной связки с настройками валюты.

## Тестовые пробелы

- Добавлены Domain tests для simple monthly payment и validation сумм.
- Добавлены Application tests для CRUD, manual/calculated mode, генерации платежей, update schedule, paid payment warning/preservation и удаления платежей.
- XCTest не запущен из-за локальной настройки: активен `/Library/Developer/CommandLineTools`, а `xcodebuild` требует полный Xcode.
- Нет UI tests для формы кредита, предупреждения и swipe delete.

## Ручные проверки

- Выполнен `swiftc -typecheck` для Domain/Application credit slice и `CreditViewModel`.
- Выполнен `plutil -lint FamilyBudget.xcodeproj/project.pbxproj`.

## Что перепроверить человеку

- Переключить developer directory на полный Xcode и запустить:

```bash
xcodebuild test -project FamilyBudget.xcodeproj -scheme FamilyBudget -destination 'platform=iOS Simulator,name=iPhone 15'
```

- Проверить в simulator: создание кредита с автоплатежом, ручной платеж, редактирование срока, просмотр графика и удаление кредита.
