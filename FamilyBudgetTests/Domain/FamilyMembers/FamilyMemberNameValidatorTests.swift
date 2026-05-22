import XCTest
@testable import FamilyBudget

final class FamilyMemberNameValidatorTests: XCTestCase {
    func testEmptyNameThrows() {
        XCTAssertThrowsError(try FamilyMemberNameValidator.normalizedName("   ")) { error in
            XCTAssertEqual(error as? FamilyMemberValidationError, .emptyName)
        }
    }

    func testNameIsTrimmed() throws {
        XCTAssertEqual(try FamilyMemberNameValidator.normalizedName("  Alex  "), "Alex")
    }
}
