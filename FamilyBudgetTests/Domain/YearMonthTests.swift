import XCTest
@testable import FamilyBudget

final class YearMonthTests: XCTestCase {
    func testMonthValidation() {
        XCTAssertThrowsError(try YearMonth(year: 2026, month: 13))
    }

    func testOrdering() throws {
        let january = try YearMonth(year: 2026, month: 1)
        let february = try YearMonth(year: 2026, month: 2)

        XCTAssertLessThan(january, february)
    }

    func testMonthRangeAcrossYearBoundary() throws {
        let start = try YearMonth(year: 2026, month: 11)
        let end = try YearMonth(year: 2027, month: 2)

        let range = try YearMonth.months(from: start, through: end)

        XCTAssertEqual(
            range,
            [
                try YearMonth(year: 2026, month: 11),
                try YearMonth(year: 2026, month: 12),
                try YearMonth(year: 2027, month: 1),
                try YearMonth(year: 2027, month: 2)
            ]
        )
    }

    func testYearMonthsContainsTwelveMonths() throws {
        let months = try YearMonth.months(inYear: 2026)

        XCTAssertEqual(months.count, 12)
        XCTAssertEqual(months.first, try YearMonth(year: 2026, month: 1))
        XCTAssertEqual(months.last, try YearMonth(year: 2026, month: 12))
    }
}
