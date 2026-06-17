import XCTest
import AirNinjaCore

final class SasTests: XCTestCase {

    func testDeriveFromKnownHandshakeHashReturnsExpectedSas() {
        let handshakeHash = TestHex.decode("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        XCTAssertEqual(Sas.derive(handshakeHash: handshakeHash), "124507")
    }

    func testDeriveAlwaysReturnsSixDigits() {
        let sas = Sas.derive(handshakeHash: Data(count: 32))
        XCTAssertEqual(sas.count, 6)
        XCTAssertTrue(sas.allSatisfy { $0.isNumber })
    }
}
