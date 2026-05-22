import Foundation

struct YearMonth: Equatable, Hashable, Comparable {
    let year: Int
    let month: Int

    init(year: Int, month: Int) throws {
        guard (1...12).contains(month) else {
            throw YearMonthError.invalidMonth(month)
        }

        self.year = year
        self.month = month
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        return lhs.month < rhs.month
    }

    func addingMonths(_ count: Int) throws -> YearMonth {
        let zeroBasedMonth = (year * 12) + (month - 1) + count
        let newYear = floorDiv(zeroBasedMonth, by: 12)
        let newMonth = mod(zeroBasedMonth, by: 12) + 1
        return try YearMonth(year: newYear, month: newMonth)
    }

    func next() throws -> YearMonth {
        try addingMonths(1)
    }

    func previous() throws -> YearMonth {
        try addingMonths(-1)
    }

    static func months(from start: YearMonth, through end: YearMonth) throws -> [YearMonth] {
        guard start <= end else {
            throw YearMonthError.invalidRange(start: start, end: end)
        }

        var result: [YearMonth] = []
        var current = start

        while current <= end {
            result.append(current)
            current = try current.next()
        }

        return result
    }

    static func months(inYear year: Int) throws -> [YearMonth] {
        try (1...12).map { try YearMonth(year: year, month: $0) }
    }

    private func floorDiv(_ value: Int, by divisor: Int) -> Int {
        let quotient = value / divisor
        let remainder = value % divisor

        if remainder != 0 && ((remainder > 0) != (divisor > 0)) {
            return quotient - 1
        }

        return quotient
    }

    private func mod(_ value: Int, by divisor: Int) -> Int {
        let result = value % divisor
        return result >= 0 ? result : result + abs(divisor)
    }
}

enum YearMonthError: Error, Equatable {
    case invalidMonth(Int)
    case invalidRange(start: YearMonth, end: YearMonth)
}
