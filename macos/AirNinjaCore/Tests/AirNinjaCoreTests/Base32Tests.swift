import XCTest
import AirNinjaCore

final class Base32Tests: XCTestCase {

    func testEmptyInputReturnsEmptyString() {
        XCTAssertEqual(Base32.encodeLowerNoPadding(Data()), "")
    }

    func testRfc4648VectorsAreLowercaseAndUnpadded() {
        XCTAssertEqual(encode("f"), "my")
        XCTAssertEqual(encode("fo"), "mzxq")
        XCTAssertEqual(encode("foo"), "mzxw6")
        XCTAssertEqual(encode("foob"), "mzxw6yq")
        XCTAssertEqual(encode("fooba"), "mzxw6ytb")
        XCTAssertEqual(encode("foobar"), "mzxw6ytboi")
    }

    private func encode(_ text: String) -> String {
        Base32.encodeLowerNoPadding(Data(text.utf8))
    }
}
