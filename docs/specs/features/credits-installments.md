# Кредиты и рассрочки

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Архитектура: `docs/architecture/ARCHITECTURE-MVP.md`

## 1. Контекст

Кредиты и рассрочки формируют основную финансовую нагрузку MVP. Каждый кредит принадлежит участнику семьи и имеет фиксированный график платежей.

## 2. Цель

Позволить пользователю создавать, редактировать и удалять кредиты/рассрочки с автоматической генерацией платежей по месяцам.

## 3. Пользовательские сценарии

- Пользователь создает рассрочку с названием, владельцем, суммой, первым взносом, сроком и датой платежа.
- Пользователь вручную вводит ежемесячный платеж.
- Пользователь дает приложению рассчитать платеж по простой формуле.
- Пользователь редактирует кредит и видит пересчитанный график.

## 4. Functional requirements

- Кредит принадлежит одному `FamilyMember`.
- Название кредита обязательно.
- `totalAmount`, `downPayment`, `monthlyPayment` используют `Money`.
- `termMonths` должен быть больше 0.
- `paymentDay` должен быть в диапазоне 1...31.
- Если `paymentDay` больше количества дней в месяце, due date переносится на последний день месяца.
- Простой расчет платежа: `(totalAmount - downPayment) / termMonths`.
- Пользователь может заменить рассчитанный платеж ручным значением.
- При создании кредита генерируется `CreditPayment` на каждый месяц срока.
- При изменении параметров кредита график платежей должен быть пересоздан или обновлен по правилам task, с защитой уже оплаченных платежей.

## 5. Acceptance criteria

- Нельзя создать кредит без участника.
- Нельзя создать кредит с пустым названием.
- Нельзя создать кредит с отрицательными суммами.
- Нельзя создать кредит, где `downPayment > totalAmount`.
- Кредит генерирует ровно `termMonths` платежей.
- Платежи попадают в правильные `YearMonth`.
- Кредит отображается в нагрузке владельца и семьи.

## 6. UI states

- список кредитов пуст;
- список кредитов;
- форма создания;
- форма редактирования;
- mode manual monthly payment;
- mode calculated monthly payment;
- validation errors;
- confirmation dialog удаления;
- предупреждение при изменении кредита с уже оплаченными платежами.

## 7. Ошибки и edge cases

- нет участников семьи;
- `termMonths <= 0`;
- `downPayment > totalAmount`;
- `paymentDay` 29-31 в коротких месяцах;
- изменение кредита после оплаты части платежей;
- удаление кредита с платежами;
- rounding при расчете ежемесячного платежа;
- сумма платежей может отличаться от остатка кредита из-за округления.

## 8. Модель данных

`Credit`:

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

`CreditPayment`:

- `id: UUID`
- `creditId: UUID`
- `month: YearMonth`
- `dueDate: Date`
- `amount: Money`
- `status: PaymentStatus`
- `paidAt: Date?`

## 9. Миграции

Не требуются для первой версии.

## 10. Стратегия тестирования

- Domain tests для generation schedule.
- Domain tests для коротких месяцев.
- Domain tests для payment calculation.
- Domain tests для validation сумм.
- Mapper tests для credit/payment persistence.
- ViewModel state tests для формы кредита.

## 11. Принятые базовые допущения

- При автосчете платежа сохраняется одинаковый `monthlyPayment`, а rounding difference не корректируется в MVP, потому что PRD требует простую формулу.
