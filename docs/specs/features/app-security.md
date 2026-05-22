# Защита приложения

Дата: 2026-05-11  
Статус: draft for human review  
PRD: `PRD-Semeynyy-Byudzhet-iOS-2026-05-11.md`  
Базовый spec: `docs/specs/foundation/security-notifications-baseline.md`

## 1. Контекст

Приложение хранит финансовые данные локально. Пользователь должен иметь возможность включить Face ID / Touch ID защиту при открытии приложения.

## 2. Цель

Реализовать системную локальную аутентификацию без собственной авторизации, аккаунтов или паролей приложения.

## 3. Пользовательские сценарии

- Пользователь включает защиту в настройках.
- Пользователь открывает приложение и проходит Face ID / Touch ID.
- Пользователь отменяет аутентификацию и не получает доступ к финансовым данным.
- Биометрия недоступна, и приложение показывает понятное объяснение.

## 4. Functional requirements

- Защита выключена по умолчанию.
- Toggle защиты находится в настройках.
- При включенной защите используется LocalAuthentication.
- Системный fallback через passcode разрешен, если доступен.
- Повторная аутентификация требуется при cold start и возвращении из background после паузы более 5 минут.
- Если аутентификация отменена, финансовый UI остается скрыт.
- Domain и Data layers не зависят от LocalAuthentication.

## 5. Acceptance criteria

- Пользователь может включить и выключить защиту.
- При включенной защите приложение требует аутентификацию.
- При успешной аутентификации пользователь видит приложение.
- При отмене аутентификации данные не отображаются.
- При недоступной биометрии пользователь видит понятное системное состояние.

## 6. UI states

- lock disabled;
- lock enabled;
- locked;
- authenticating;
- unlocked;
- authentication canceled;
- authentication failed;
- biometrics unavailable;
- passcode fallback unavailable.

## 7. Ошибки и edge cases

- устройство без биометрии;
- пользователь не настроил Face ID / Touch ID;
- пользователь отменил системный prompt;
- приложение вернулось из background через 5+ минут;
- LocalAuthentication возвращает ошибку;
- пользователь выключает защиту после успешной аутентификации.

## 8. Модель данных

`AppSettings.biometricLockEnabled: Bool`

Runtime state аутентификации не должен храниться как permanent persistence state.

## 9. Миграции

Не требуются.

## 10. Стратегия тестирования

- Unit tests для Application-level lock state decisions.
- ViewModel state tests для locked/unlocked states.
- Manual checks на реальном устройстве или simulator для LocalAuthentication.

## 11. Принятые базовые допущения

- Нет критичных открытых вопросов для MVP.
