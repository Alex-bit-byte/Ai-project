import Foundation

enum PersistenceMappingError: Error, Equatable {
    case invalidDecimal(String)
    case invalidIncomeCategory(String)
    case invalidIncomeRecurrence(String)
    case invalidPaymentStatus(String)
    case incompleteOptionalYearMonth
    case invalidDomainValue(String)
}

enum PersistenceMapper {
    private static let decimalLocale = Locale(identifier: "en_US_POSIX")

    static func amountString(from amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    static func money(amountString: String, currencyCode: String) throws -> Money {
        guard let amount = Decimal(string: amountString, locale: decimalLocale) else {
            throw PersistenceMappingError.invalidDecimal(amountString)
        }

        return Money(amount: amount, currencyCode: currencyCode)
    }

    static func model(from settings: AppSettings) -> AppSettingsModel {
        AppSettingsModel(
            id: settings.id,
            currencyCode: settings.currencyCode,
            biometricLockEnabled: settings.biometricLockEnabled,
            notificationsEnabled: settings.notificationsEnabled,
            createdAt: settings.createdAt,
            updatedAt: settings.updatedAt
        )
    }

    static func domain(from model: AppSettingsModel) -> AppSettings {
        AppSettings(
            id: model.id,
            currencyCode: model.currencyCode,
            biometricLockEnabled: model.biometricLockEnabled,
            notificationsEnabled: model.notificationsEnabled,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    static func model(from member: FamilyMember) -> FamilyMemberModel {
        FamilyMemberModel(id: member.id, name: member.name, createdAt: member.createdAt, updatedAt: member.updatedAt)
    }

    static func domain(from model: FamilyMemberModel) -> FamilyMember {
        FamilyMember(id: model.id, name: model.name, createdAt: model.createdAt, updatedAt: model.updatedAt)
    }

    static func model(from income: Income) -> IncomeModel {
        IncomeModel(
            id: income.id,
            memberId: income.memberId,
            categoryRawValue: rawValue(from: income.category),
            title: income.title,
            amountString: amountString(from: income.amount.amount),
            currencyCode: income.amount.currencyCode,
            recurrenceRawValue: rawValue(from: income.recurrence),
            startYear: income.startMonth.year,
            startMonth: income.startMonth.month,
            endYear: income.endMonth?.year,
            endMonth: income.endMonth?.month,
            createdAt: income.createdAt,
            updatedAt: income.updatedAt
        )
    }

    static func domain(from model: IncomeModel) throws -> Income {
        let endMonth = try optionalYearMonth(year: model.endYear, month: model.endMonth)

        do {
            return try Income(
                id: model.id,
                memberId: model.memberId,
                category: incomeCategory(from: model.categoryRawValue),
                title: model.title,
                amount: money(amountString: model.amountString, currencyCode: model.currencyCode),
                recurrence: incomeRecurrence(from: model.recurrenceRawValue),
                startMonth: YearMonth(year: model.startYear, month: model.startMonth),
                endMonth: endMonth,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            )
        } catch let error as PersistenceMappingError {
            throw error
        } catch {
            throw PersistenceMappingError.invalidDomainValue(String(describing: error))
        }
    }

    static func model(from override: IncomeOverride) -> IncomeOverrideModel {
        IncomeOverrideModel(
            id: override.id,
            incomeId: override.incomeId,
            year: override.month.year,
            month: override.month.month,
            amountString: amountString(from: override.amount.amount),
            currencyCode: override.amount.currencyCode,
            note: override.note
        )
    }

    static func domain(from model: IncomeOverrideModel) throws -> IncomeOverride {
        do {
            return try IncomeOverride(
                id: model.id,
                incomeId: model.incomeId,
                month: YearMonth(year: model.year, month: model.month),
                amount: money(amountString: model.amountString, currencyCode: model.currencyCode),
                note: model.note
            )
        } catch let error as PersistenceMappingError {
            throw error
        } catch {
            throw PersistenceMappingError.invalidDomainValue(String(describing: error))
        }
    }

    static func model(from credit: Credit) -> CreditModel {
        CreditModel(
            id: credit.id,
            memberId: credit.memberId,
            title: credit.title,
            totalAmountString: amountString(from: credit.totalAmount.amount),
            downPaymentString: amountString(from: credit.downPayment.amount),
            monthlyPaymentString: amountString(from: credit.monthlyPayment.amount),
            currencyCode: credit.totalAmount.currencyCode,
            termMonths: credit.termMonths,
            startYear: credit.startMonth.year,
            startMonth: credit.startMonth.month,
            endYear: credit.endMonth.year,
            endMonth: credit.endMonth.month,
            paymentDay: credit.paymentDay,
            reminderEnabled: credit.reminderEnabled,
            createdAt: credit.createdAt,
            updatedAt: credit.updatedAt
        )
    }

    static func domain(from model: CreditModel) throws -> Credit {
        do {
            return try Credit(
                id: model.id,
                memberId: model.memberId,
                title: model.title,
                totalAmount: money(amountString: model.totalAmountString, currencyCode: model.currencyCode),
                downPayment: money(amountString: model.downPaymentString, currencyCode: model.currencyCode),
                monthlyPayment: money(amountString: model.monthlyPaymentString, currencyCode: model.currencyCode),
                termMonths: model.termMonths,
                startMonth: YearMonth(year: model.startYear, month: model.startMonth),
                paymentDay: model.paymentDay,
                reminderEnabled: model.reminderEnabled,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            )
        } catch let error as PersistenceMappingError {
            throw error
        } catch {
            throw PersistenceMappingError.invalidDomainValue(String(describing: error))
        }
    }

    static func model(from payment: CreditPayment) -> CreditPaymentModel {
        CreditPaymentModel(
            id: payment.id,
            creditId: payment.creditId,
            year: payment.month.year,
            month: payment.month.month,
            dueDate: payment.dueDate,
            amountString: amountString(from: payment.amount.amount),
            currencyCode: payment.amount.currencyCode,
            statusRawValue: rawValue(from: payment.status),
            paidAt: payment.paidAt
        )
    }

    static func domain(from model: CreditPaymentModel) throws -> CreditPayment {
        do {
            return try CreditPayment(
                id: model.id,
                creditId: model.creditId,
                month: YearMonth(year: model.year, month: model.month),
                dueDate: model.dueDate,
                amount: money(amountString: model.amountString, currencyCode: model.currencyCode),
                status: paymentStatus(from: model.statusRawValue),
                paidAt: model.paidAt
            )
        } catch let error as PersistenceMappingError {
            throw error
        } catch {
            throw PersistenceMappingError.invalidDomainValue(String(describing: error))
        }
    }

    private static func optionalYearMonth(year: Int?, month: Int?) throws -> YearMonth? {
        switch (year, month) {
        case (.none, .none):
            return nil
        case let (.some(year), .some(month)):
            return try YearMonth(year: year, month: month)
        default:
            throw PersistenceMappingError.incompleteOptionalYearMonth
        }
    }

    private static func rawValue(from category: IncomeCategory) -> String {
        switch category {
        case .salary:
            return "salary"
        case .bonus:
            return "bonus"
        case .other:
            return "other"
        }
    }

    private static func incomeCategory(from rawValue: String) throws -> IncomeCategory {
        switch rawValue {
        case "salary":
            return .salary
        case "bonus":
            return .bonus
        case "other":
            return .other
        default:
            throw PersistenceMappingError.invalidIncomeCategory(rawValue)
        }
    }

    private static func rawValue(from recurrence: IncomeRecurrence) -> String {
        switch recurrence {
        case .oneTime:
            return "oneTime"
        case .monthly:
            return "monthly"
        }
    }

    private static func incomeRecurrence(from rawValue: String) throws -> IncomeRecurrence {
        switch rawValue {
        case "oneTime":
            return .oneTime
        case "monthly":
            return .monthly
        default:
            throw PersistenceMappingError.invalidIncomeRecurrence(rawValue)
        }
    }

    private static func rawValue(from status: PaymentStatus) -> String {
        switch status {
        case .scheduled:
            return "scheduled"
        case .paid:
            return "paid"
        case .skipped:
            return "skipped"
        }
    }

    private static func paymentStatus(from rawValue: String) throws -> PaymentStatus {
        switch rawValue {
        case "scheduled":
            return .scheduled
        case "paid":
            return .paid
        case "skipped":
            return .skipped
        default:
            throw PersistenceMappingError.invalidPaymentStatus(rawValue)
        }
    }
}
